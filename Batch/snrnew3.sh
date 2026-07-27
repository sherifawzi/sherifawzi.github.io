#!/bin/bash
#
# SNRobotiX MT5 server provisioning - Ubuntu 22.04 ONLY, Wine 10.0 pinned
#
#   sudo -i
#   wget https://sherifawzi.github.io/Batch/snrnew4.sh
#   chmod +x snrnew4.sh
#   ./snrnew4.sh
#
# Runs fully unattended. No prompts, no manual Wine steps afterwards.
# Reboot when it finishes, then start mt5.service.

set -u

HOMEDIR=/root
MT5DIR=$HOMEDIR/mt5
PREFIX=$HOMEDIR/.wine
BINHOST=http://3.66.106.21/MT5
TOOLHOST=https://sherifawzi.github.io/Tools
COMMONFILES="$PREFIX/drive_c/users/root/Application Data/MetaQuotes/Terminal/Common/Files"

###############################################################################
# 1. Silence every interactive prompt, then wait for cloud-init to free apt
###############################################################################
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export NEEDRESTART_SUSPEND=1

sed -i "s/^#\?\$nrconf{restart}.*/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf 2>/dev/null || true
sed -i "s/^#\?\$nrconf{kernelhints}.*/\$nrconf{kernelhints} = -1;/" /etc/needrestart/needrestart.conf 2>/dev/null || true
echo "lightdm shared/default-x-display-manager select lightdm" | debconf-set-selections
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections

while fuser /var/lib/dpkg/lock-frontend /var/lib/apt/lists/lock /var/lib/dpkg/lock >/dev/null 2>&1; do
    echo "Waiting for another apt/dpkg process to finish..."
    sleep 5
done

APTOPTS="-o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold"

apt-get update
apt-get upgrade -y $APTOPTS

###############################################################################
# 2. Desktop + remote access (needed only for manual inspection over RDP)
###############################################################################
apt-get install -y xfce4 xrdp
echo xfce4-session > $HOMEDIR/.xsession
systemctl enable --now xrdp

ufw allow 3389/tcp 2>/dev/null || true
ufw allow 8567/tcp 2>/dev/null || true

###############################################################################
# 3. Wine 10.0 from WineHQ, pinned and held
#
# Jammy's own wine is 6.0.3 (too old for current MT5). Wine 11.x trips MT5's
# "A debugger has been found running in your system" check. 10.0 is the only
# version that works, so it is version-pinned AND apt-mark held so neither the
# upgrade above nor unattended-upgrades can move it.
###############################################################################
dpkg --add-architecture i386
mkdir -pm755 /etc/apt/keyrings
wget -qO - https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key
wget -qNP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/winehq-jammy.sources
apt-get update

apt-get install -y --install-recommends \
    winehq-stable=10.0.0.0~jammy-1 \
    wine-stable=10.0.0.0~jammy-1 \
    wine-stable-amd64=10.0.0.0~jammy-1 \
    wine-stable-i386:i386=10.0.0.0~jammy-1
apt-mark hold winehq-stable wine-stable wine-stable-amd64 wine-stable-i386

# Runtime deps: libgl1 for rendering, xvfb for headless, fonts for chart labels
apt-get install -y libgl1 xvfb ttf-mscorefonts-installer

wine --version

###############################################################################
# 4. Build the Wine prefix here, headlessly, instead of by hand after reboot
#
# WINEDLLOVERRIDES disables Mono and Gecko, which MT5 does not use. Without it
# wineboot blocks forever on an installer dialog that never gets clicked.
# xvfb-run gives wineboot a display so no RDP session is needed.
# timeout is a backstop: a wedged wineboot fails the step instead of hanging.
###############################################################################
export WINEPREFIX=$PREFIX
export WINEARCH=win64
export WINEDEBUG=-all
export WINEDLLOVERRIDES="mscoree,mshtml="

pkill -9 -f wineserver 2>/dev/null || true
pkill -9 -f wine 2>/dev/null || true
rm -rf $PREFIX

timeout 300 xvfb-run -a wineboot -u
timeout 60 xvfb-run -a winecfg -v win10
wineserver -k 2>/dev/null || true
sleep 2

cp /usr/share/fonts/truetype/msttcorefonts/*.ttf "$PREFIX/drive_c/windows/Fonts/" 2>/dev/null || true

# Prove the prefix actually works before going any further
if wine cmd /c echo PREFIX_OK 2>/dev/null | grep -q PREFIX_OK; then
    echo "Wine prefix OK"
else
    echo "ERROR: Wine prefix is broken. Fix this before starting mt5.service." >&2
fi
wineserver -k 2>/dev/null || true

###############################################################################
# 5. MT5 binaries - fetched ONCE, not on every boot
#
# MT5 completes its own installation on first run (it downloads the several
# hundred supporting files itself). Those files are matched to the terminal
# binary that fetched them. Overwriting terminal64.exe on every boot while
# leaving that supporting tree in place leaves the install mismatched, which
# is the most likely cause of the startup crashes. So: download only what is
# missing, and let MT5 own its own directory from then on.
###############################################################################
mkdir -p $MT5DIR
for f in terminal64.exe metatester64.exe MetaEditor64.exe; do
    [ -s "$MT5DIR/$f" ] || wget -q -O "$MT5DIR/$f" "$BINHOST/$f"
done

echo 'export WINEDEBUG=-all' > /etc/profile.d/wine-quiet.sh

###############################################################################
# 6. Restart watcher (EA drops restart.txt -> notify -> reboot)
###############################################################################
cat > /usr/local/bin/check_restart.sh << 'EOF'
#!/bin/bash
FILE_PATH="/root/.wine/drive_c/users/root/Application Data/MetaQuotes/Terminal/Common/Files/restart.txt"
RESTART_DELAY=120
BOT_ID="8450507003:AAHhqJg_6x_ajStvx2_eoZRHnVIRpexzQc4"
CHANNEL_ID="-1003285305833"

if [ -f "$FILE_PATH" ]; then
    rm -f "$FILE_PATH"
    curl -s -X POST "https://api.telegram.org/bot${BOT_ID}/sendMessage" \
        -d chat_id="${CHANNEL_ID}" \
        -d text="<b>$(hostname) Server Restart</b>" \
        -d parse_mode="HTML" > /dev/null
    echo "$(date): restart.txt found, rebooting in ${RESTART_DELAY}s"
    sleep $RESTART_DELAY
    /sbin/shutdown -r now
fi
EOF
chmod +x /usr/local/bin/check_restart.sh

(crontab -l 2>/dev/null | grep -v check_restart.sh; \
 echo "*/5 * * * * /usr/local/bin/check_restart.sh >> /var/log/restart_check.log 2>&1") | crontab -

###############################################################################
# 7. Xvfb as its own unit
#
# Previously Xvfb was backgrounded from an ExecStartPre with a PID file, so
# systemd had no idea whether it was alive. As a real unit, MT5 can depend on
# it and systemd restarts it if it dies.
###############################################################################
cat > /etc/systemd/system/xvfb.service << 'EOF'
[Unit]
Description=Xvfb virtual display :99
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/Xvfb :99 -screen 0 1024x768x24 -ac +extension GLX +render -noreset
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

###############################################################################
# 8. File server for the Common\Files folder
###############################################################################
cat > /etc/systemd/system/mt5-http.service << EOF
[Unit]
Description=MT5 Common Files HTTP server
After=network.target

[Service]
Type=simple
ExecStartPre=/bin/mkdir -p "$COMMONFILES"
WorkingDirectory=$COMMONFILES
ExecStart=/usr/bin/python3 -m http.server 8567
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

###############################################################################
# 9. MT5 service
#
# Changes from the previous version:
#  - no 45 seconds of hardcoded sleeps; ordering is expressed as dependencies
#  - Xvfb and the HTTP server are separate units, not backgrounded children
#  - binaries are NOT re-downloaded per boot (see section 5)
#  - the /config argument is quoted; unquoted it was split on the space in
#    "Application Data" and MT5 never received the config path
#  - Mono/Gecko overrides set so a headless start cannot block on a dialog
#  - "profiles" removed from the per-boot wipe: it holds chart and EA setup.
#    Add it back to the for-loop below if wiping it was deliberate.
###############################################################################
cat > /etc/systemd/system/mt5.service << 'EOF'
[Unit]
Description=MetaTrader 5 Headless
After=network-online.target xvfb.service mt5-http.service
Wants=network-online.target
Requires=xvfb.service

[Service]
Type=simple
User=root
Environment="DISPLAY=:99"
Environment="WINEPREFIX=/root/.wine"
Environment="WINEDEBUG=-all"
Environment="WINEDLLOVERRIDES=mscoree,mshtml="
WorkingDirectory=/root/mt5

# Clear caches and stale logs, keep the install itself intact
ExecStartPre=/bin/bash -c 'for d in logs tester temp; do find /root/mt5 -maxdepth 1 -type d -iname "$d" -exec rm -rf {} +; done; true'
ExecStartPre=/bin/bash -c 'find /root/mt5 -maxdepth 1 -type d -iname bases -exec find {} -type f \( -iname "*.hcc" -o -iname "ticks.dat" \) -delete \; ; true'

# Refresh the EA and its preset only
ExecStartPre=/bin/bash -c 'mkdir -p /root/mt5/MQL5/Experts /root/mt5/MQL5/Profiles/Tester'
ExecStartPre=-/usr/bin/wget -q -O /root/mt5/MQL5/Experts/SNRC.ex5 https://sherifawzi.github.io/Tools/SNRC.ex5
ExecStartPre=-/usr/bin/wget -q -O /root/mt5/MQL5/Profiles/Tester/SNRC.set https://sherifawzi.github.io/Tools/SNRC.set

ExecStart=/usr/bin/wine terminal64.exe /portable "/config:C:\\users\\root\\Application Data\\MetaQuotes\\Terminal\\Common\\Files\\configur.txt"

TimeoutStartSec=180
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=10

ExecStopPost=-/usr/bin/pkill -9 -f winedevice
ExecStopPost=-/usr/bin/pkill -9 -f wineserver
ExecStopPost=-/usr/bin/pkill -9 wine

Restart=always
RestartSec=60
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable xvfb.service mt5-http.service mt5.service

###############################################################################
echo ""
echo "=============================================="
echo "DONE. Wine version below must read wine-10.0:"
wine --version
apt-mark showhold
echo "=============================================="
echo ""
echo "1. Reboot:  shutdown -r now"
echo ""
echo "2. Optional manual check over RDP (virtual desktop mode avoids the"
echo "   unclickable-window problem plain 'wine terminal64.exe' has under XRDP):"
echo "     cd /root/mt5 && wine explorer /desktop=mt5,1600x900 terminal64.exe"
echo "   Let MT5 finish completing its own install, log in, then close it."
echo ""
echo "3. Start it headless:"
echo "     systemctl start mt5.service"
echo "     journalctl -u mt5.service -f"
echo ""
echo "Notes:"
echo " - Never run wine with sudo."
echo " - Wine is held at 10.0; check with: apt-mark showhold"
echo " - Files served at http://SERVER_IP:8567"
echo "=============================================="
