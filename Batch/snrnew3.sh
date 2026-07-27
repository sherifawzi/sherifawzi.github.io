#!/bin/bash
#
# SNRobotiX MT5 server provisioning - Ubuntu 22.04 ONLY, Wine 10.0 pinned
#
#   sudo -i
#   passwd                 # REQUIRED: xrdp needs a root password to log in
#   wget https://sherifawzi.github.io/Batch/snrnew5.sh
#   chmod +x snrnew5.sh
#   ./snrnew5.sh
#
# Runs unattended. Reboot at the end, do the one-time MT5 setup over RDP,
# then enable mt5.service.

set -u

HOMEDIR=/root
MT5DIR=$HOMEDIR/mt5
PREFIX=$HOMEDIR/.wine
BINHOST=http://3.66.106.21/MT5
GECKOVER=2.47.4
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

apt-get clean
apt-get update
apt-get upgrade -y $APTOPTS

###############################################################################
# 2. Desktop + remote access
#
# xfce4-terminal and dbus-x11 are named explicitly: the whole manual workflow
# is a terminal over RDP, and dropping xfce4-goodies must not risk losing it.
###############################################################################
apt-get install -y xfce4 xfce4-terminal dbus-x11 xrdp
echo xfce4-session > $HOMEDIR/.xsession
systemctl enable --now xrdp

ufw allow 3389/tcp 2>/dev/null || true
ufw allow 8567/tcp 2>/dev/null || true

###############################################################################
# 3. Wine 10.0 from WineHQ, pinned and held
#
# Jammy's own wine is 6.0.3 (too old for current MT5). Wine 11.x trips MT5's
# "A debugger has been found running in your system" check. So 10.0 is both
# version-pinned and apt-mark held, so no later upgrade can move it.
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

# libgl1 + libglx-mesa0 replace the old libgl1-mesa-glx; xvfb for headless;
# msttcorefonts so chart and panel text renders correctly
apt-get install -y libgl1 libglx-mesa0 xvfb ttf-mscorefonts-installer

wine --version

###############################################################################
# 4. Pre-seed Wine Gecko so the prefix can be built with no dialogs
#
# MT5 uses embedded HTML for Mailbox/Market/News, so Gecko must be present.
# If the MSIs are already in /usr/share/wine/gecko, wineboot installs them
# silently instead of showing the "Wine could not find a wine-gecko package"
# dialog, which is what blocks an unattended prefix build.
#
# Mono is genuinely unused by MT5, so mscoree stays disabled.
###############################################################################
mkdir -p /usr/share/wine/gecko
for a in x86 x86_64; do
    f=/usr/share/wine/gecko/wine-gecko-$GECKOVER-$a.msi
    [ -s "$f" ] || wget -q -O "$f" "https://dl.winehq.org/wine/wine-gecko/$GECKOVER/wine-gecko-$GECKOVER-$a.msi" || true
done

###############################################################################
# 5. Build the Wine prefix here, headlessly, instead of by hand after reboot
###############################################################################
export WINEPREFIX=$PREFIX
export WINEARCH=win64
export WINEDEBUG=-all
export WINEDLLOVERRIDES="mscoree="

pkill -9 -f wineserver 2>/dev/null || true
pkill -9 -f wine 2>/dev/null || true
sleep 2
rm -rf $PREFIX

timeout 420 xvfb-run -a wineboot -u
wineserver -k 2>/dev/null || true
sleep 2

# Windows 10 mode, and winhttp forced native so MT5's WebRequest calls work
wine reg add "HKCU\\Software\\Wine" /v Version /d win10 /f
wine reg add "HKCU\\Software\\Wine\\DllOverrides" /v winhttp /d "native,builtin" /f
wineserver -k 2>/dev/null || true
sleep 2

cp /usr/share/fonts/truetype/msttcorefonts/*.ttf "$PREFIX/drive_c/windows/Fonts/" 2>/dev/null || true

# Prove the prefix works before going further
if wine cmd /c echo PREFIX_OK 2>/dev/null | grep -q PREFIX_OK; then
    echo "Wine prefix OK"
else
    echo "ERROR: Wine prefix is broken - fix before enabling mt5.service" >&2
fi
wineserver -k 2>/dev/null || true

###############################################################################
# 6. MT5 binaries - fetched ONCE, not on every boot
#
# MT5 completes its own installation on first run, downloading the several
# hundred supporting files itself, and those files match the binary that
# fetched them. Overwriting terminal64.exe on every boot while leaving that
# tree in place leaves the install mismatched. So download only what is
# missing and let MT5 own its directory from then on.
###############################################################################
mkdir -p $MT5DIR
for f in terminal64.exe metatester64.exe MetaEditor64.exe; do
    [ -s "$MT5DIR/$f" ] || wget -q -O "$MT5DIR/$f" "$BINHOST/$f" || true
done
[ -s "$MT5DIR/terminal64.exe" ] || echo "ERROR: terminal64.exe did not download from $BINHOST" >&2

# Quiet Wine logging in interactive shells (profile.d covers login shells,
# .bashrc covers the terminal windows opened over RDP).
# Remove both if you need to see Wine errors while troubleshooting.
echo 'export WINEDEBUG=-all' > /etc/profile.d/wine-quiet.sh
grep -q "WINEDEBUG=-all" $HOMEDIR/.bashrc || echo 'export WINEDEBUG=-all' >> $HOMEDIR/.bashrc

###############################################################################
# 7. Restart watcher (EA drops restart.txt -> notify -> reboot)
###############################################################################
cat > /usr/local/bin/check_restart.sh << 'EOF'
#!/bin/bash
FILE_PATH="/root/.wine/drive_c/users/root/Application Data/MetaQuotes/Terminal/Common/Files/restart.txt"
RESTART_DELAY=120
BOT_ID="8450507003:AAHhqJg_6x_ajStvx2_eoZRHnVIRpexzQc4"
CHANNEL_ID="-1003285305833"

if [ -f "$FILE_PATH" ]; then
    echo "$(date): found restart.txt"
    rm -f "$FILE_PATH"
    curl -s -X POST "https://api.telegram.org/bot${BOT_ID}/sendMessage" \
        -d chat_id="${CHANNEL_ID}" \
        -d text="<b>$(hostname) Server Restart</b>" \
        -d parse_mode="HTML" > /dev/null
    echo "$(date): telegram sent, rebooting in ${RESTART_DELAY}s"
    sleep $RESTART_DELAY
    /sbin/shutdown -r now
fi
EOF
chmod +x /usr/local/bin/check_restart.sh

(crontab -l 2>/dev/null | grep -v check_restart.sh; \
 echo "*/5 * * * * /usr/local/bin/check_restart.sh >> /var/log/restart_check.log 2>&1") | crontab -

###############################################################################
# 8. Xvfb as its own supervised unit
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
# 9. File server for the MT5 Common\Files folder
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
# 10. MT5 service
#
# Fixes carried in here that the old unit had wrong:
#  - ExecStartPre used a shell variable ($name) inside the command line.
#    systemd expands $VAR itself before bash ever sees it, and an undefined
#    one becomes empty, so that cleanup loop was matching nothing. Rewritten
#    with no variables at all.
#  - the /config argument was unquoted, so systemd split it on the space in
#    "Application Data" and MT5 never received the config path.
#  - ExecStopPost ran system-wide "pkill -9 wine", which SIGKILLs any manual
#    Wine session open over RDP. Replaced with a prefix-scoped wineserver -k.
#  - EA download failures now use "-" so they cannot abort startup.
#  - "profiles" dropped from the per-boot wipe: it holds chart and EA setup.
#    Put it back in the find below if that wipe was deliberate.
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
Environment="WINEDLLOVERRIDES=mscoree="
WorkingDirectory=/root/mt5

# Clear stale logs and caches, leave the installation itself intact
ExecStartPre=-/usr/bin/find /root/mt5 -maxdepth 1 -type d \( -iname logs -o -iname tester -o -iname temp \) -exec rm -rf {} +
ExecStartPre=-/usr/bin/find /root/mt5 -maxdepth 2 -type d -iname bases -exec find {} -type f \( -iname "*.hcc" -o -iname "ticks.dat" \) -delete ;

# Refresh the EA and its preset only
ExecStartPre=/bin/mkdir -p /root/mt5/MQL5/Experts /root/mt5/MQL5/Profiles/Tester
ExecStartPre=-/usr/bin/wget -q -O /root/mt5/MQL5/Experts/SNRC.ex5 https://sherifawzi.github.io/Tools/SNRC.ex5
ExecStartPre=-/usr/bin/wget -q -O /root/mt5/MQL5/Profiles/Tester/SNRC.set https://sherifawzi.github.io/Tools/SNRC.set

ExecStart=/usr/bin/wine terminal64.exe /portable "/config:C:\\users\\root\\Application Data\\MetaQuotes\\Terminal\\Common\\Files\\configur.txt"

TimeoutStartSec=180
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=10

ExecStopPost=-/usr/bin/wineserver -k

Restart=always
RestartSec=60
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable xvfb.service mt5-http.service

# mt5.service is deliberately NOT enabled here. Enable it only after the
# one-time MT5 setup below, so it cannot interfere with a manual session.

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
echo "2. REQUIRED - connect via RDP and set MT5 up once:"
echo ""
echo "     cd /root/mt5 && wine explorer /desktop=mt5,1600x900 terminal64.exe"
echo ""
echo "   (virtual desktop mode - plain 'wine terminal64.exe' gives unclickable"
echo "    windows under XRDP)"
echo ""
echo "   a) Let MT5 finish completing its own installation. If it exits,"
echo "      relaunch with the same command until it stays up."
echo "   b) Log into the broker account, tick Save password."
echo "   c) Tools > Options > Expert Advisors > tick 'Allow WebRequest for"
echo "      listed URL' and add all four:"
echo "         https://sherifawzi.github.io"
echo "         https://t.me"
echo "         https://api.telegram.org"
echo "         http://3.66.106.21"
echo "   d) Tick Algo Trading, attach SNRC, confirm it initialises."
echo "   e) Close MT5 with File > Exit so settings are flushed."
echo ""
echo "3. Only then, enable and start it headless:"
echo "     systemctl enable --now mt5.service"
echo "     journalctl -u mt5.service -f"
echo ""
echo "Notes:"
echo " - Never run wine with sudo."
echo " - Do not run MT5 manually while mt5.service is active: they share the"
echo "   same Wine prefix and will fight over it."
echo " - Wine is held at 10.0; verify with: apt-mark showhold"
echo " - Files served at http://SERVER_IP:8567"
echo "=============================================="
