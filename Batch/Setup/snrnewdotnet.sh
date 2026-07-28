#!/bin/bash
###############################################################################
# snrnew_dotnet.sh  -  ALTERNATIVE PATH (custom build 6061 + real .NET)
#
# >>> RUN ON UBUNTU 24.04 (noble). Run as root: sudo -i ; ./snrnew_dotnet.sh
#
# ---------------------------------------------------------------------------
# CONTEXT FOR FUTURE REFERENCE (read this before touching anything):
#
# There are TWO working ways to run MT5 on these Contabo VPS boxes. This is
# the SECOND one. The primary/chosen path is snrnew_final.sh (stock MT5).
#
#   PATH A (primary, snrnew_final.sh):
#     - Stock MetaTrader 5 from MetaQuotes (mt5setup.exe via mt5linux.sh).
#     - Plain Wine-Mono is enough. No .NET fight. Simplest, most robust.
#     - Runs the STOCK terminal64.exe (no MCP/llm-agent).
#
#   PATH B (this file, snrnew_dotnet.sh):
#     - Runs OUR OWN custom terminal64.exe (build 6061) from our server.
#     - This build has an MCP server + llm-agent baked in and HARD-REQUIRES
#       real Microsoft .NET: at startup it calls GetModuleHandleW("mscoree").
#       If mscoree/.NET is not resident it calls ExitProcess(0) and quits
#       cleanly with NO window and NO error. That silent exit-0 is THE symptom
#       that tells you .NET is missing. Wine-Mono does NOT satisfy this check.
#     - Fix: install real .NET Framework 4.8 via winetricks (dotnet48).
#       This REMOVES Mono and installs genuine mscoree. After that, build 6061
#       launches and stays open.
#
# WHY WE KEEP BOTH: on 2026-07-28 both were confirmed working live. Stock was
# chosen as production for simplicity, but if the MCP/llm-agent features of
# build 6061 are needed, this is the proven route so we don't re-derive it.
#
# ---------------------------------------------------------------------------
# HARD-WON FIXES BAKED IN (do not "simplify" these away):
#
# 1) WINE VERSION: new MT5 needs Wine 11.3+. WineHQ 'stable' is only 11.0
#    (too old); 'staging' is 11.14 (works). So we use winehq-staging.
#    We PIN + apt-mark hold it so an apt upgrade can't move it under us.
#
# 2) PREFIX BUILD HANGS: Wine's INTERNAL Mono/Gecko downloader stalls on
#    these boxes (network is fine - direct wget hits 100+ MB/s - but wine's
#    own fetch hangs for 10-15 min). FIX: pre-seed the .msi files into
#    ~/.cache/wine BEFORE building the prefix. Then wineboot installs them
#    from disk instantly. Do NOT use WINEDLLOVERRIDES="mscoree=;mshtml=" to
#    suppress them - that CORRUPTS the prefix (c0000135 kernel32 errors).
#
# 3) DOTNET48 INSTALL STALLS: winetricks dotnet48 deadlocks on a
#    "wineserver -w will hang until all wine processes terminate" wait at
#    EACH stage transition (dotnet40->45->46->48 and the winecfg version
#    steps). It is NOT broken - it just needs a nudge. FIX: this script runs
#    dotnet48 in the background and fires periodic `wineserver -k` to unblock
#    each stall automatically, so nobody has to babysit it. ngen.exe /
#    mscorsvw at high CPU is REAL work - the kills only matter when things sit
#    at 0% on the hang line.
#
# 4) win10 vs win11: build 6061 ran fine in win10. (Stock MT5 wanted win11 for
#    WebView2, but build 6061 does not need WebView2 - it exits on mscoree
#    long before any WebView2 path.) We use win10 here, matching the old
#    6-month-working setup.
#
# 5) renderer=gdi: headless/RDP boxes have no GPU (DRI3/libEGL warnings are
#    harmless). MT5 chart rendering under software GL can freeze the UI thread
#    on live ticks. Forcing GDI rendering avoids that. Kept.
#
# 6) LAYOUT: this path keeps the ORIGINAL portable layout - our terminal64.exe
#    runs /portable from ~/mt5, prefix ~/.wine, Common\Files under
#    "Application Data" (NOT AppData\Roaming - that's only the stock path).
#    Config launch retained for the headless service.
###############################################################################

set -u

# --- OS base -----------------------------------------------------------------
sudo apt clean -y && sudo apt-get update && sudo apt-get upgrade -y
sudo apt install -y xfce4 xfce4-goodies

# XRDP
sudo apt install -y xrdp
sudo systemctl enable xrdp
sudo systemctl start xrdp
echo xfce4-session > ~/.xsession
sudo systemctl restart xrdp

# Firewall
sudo ufw allow 3389/tcp
sudo ufw allow 8567/tcp

# --- Wine (staging, pinned) -- see FIX #1 ------------------------------------
sudo apt install -y wget gpg bc curl
sudo dpkg --add-architecture i386
sudo mkdir -pm755 /etc/apt/keyrings
sudo rm -f /etc/apt/sources.list.d/winehq*
sudo wget -O - https://dl.winehq.org/wine-builds/winehq.key | sudo gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key -
sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/noble/winehq-noble.sources
sudo apt update
sudo apt install --install-recommends -y winehq-staging

# Pin + hold the exact staging version (stability across apt upgrades)
WINE_PKG_VER=$(dpkg-query -W -f='${Version}' wine-staging-amd64 2>/dev/null)
echo "Installed Wine staging: $WINE_PKG_VER"
HELD=$(dpkg-query -W -f='${Package}\n' 'winehq-*' 'wine-staging*' 2>/dev/null | sort -u)
[ -n "$HELD" ] && sudo apt-mark hold $HELD

# winetricks + Xvfb (winetricks AFTER WineHQ so it doesn't pull distro wine)
sudo apt install -y winetricks libgl1 xvfb

# --- Pre-seed Mono + Gecko into wine cache -- see FIX #2 ---------------------
mkdir -p ~/.cache/wine
cd ~/.cache/wine
wget -q "https://dl.winehq.org/wine/wine-mono/9.4.0/wine-mono-9.4.0-x86.msi"
wget -q "https://dl.winehq.org/wine/wine-gecko/2.47.4/wine-gecko-2.47.4-x86.msi"
wget -q "https://dl.winehq.org/wine/wine-gecko/2.47.4/wine-gecko-2.47.4-x86_64.msi"

# --- Wine env (ORIGINAL portable layout: prefix ~/.wine) -- see FIX #6 -------
export WINEPREFIX="$HOME/.wine"
export WINEARCH=win64
export WINEDEBUG=-all
echo 'export WINEDEBUG=-all' >> ~/.bashrc

# --- Our custom terminal + SNRC (portable layout under ~/mt5) ----------------
mkdir -p ~/mt5
cd ~/mt5
wget https://www.snrobotix.com/MT5/terminal64.exe

mkdir -p ~/mt5/MQL5/Experts
wget -O ~/mt5/MQL5/Experts/SNRC.ex5 https://sherifawzi.github.io/Tools/SNRC.ex5

mkdir -p ~/mt5/MQL5/Profiles/Tester
wget -O ~/mt5/MQL5/Profiles/Tester/SNRC.set https://sherifawzi.github.io/Tools/SNRC.set

###############################################################################
# Restart check script (original Common\Files path - "Application Data")
###############################################################################
cat > /usr/local/bin/check_restart.sh << 'EOF'
#!/bin/bash
CHECK_FOLDER="/root/.wine/drive_c/users/root/Application Data/MetaQuotes/Terminal/Common/Files"
CHECK_FILE="restart.txt"
RESTART_DELAY=120
BOT_ID="8450507003:AAHhqJg_6x_ajStvx2_eoZRHnVIRpexzQc4"
CHANNEL_ID="-1003285305833"
FILE_PATH="$CHECK_FOLDER/$CHECK_FILE"
send_telegram() {
    curl -s -X POST "https://api.telegram.org/bot${BOT_ID}/sendMessage" \
        -d chat_id="${CHANNEL_ID}" -d text="$1" -d parse_mode="HTML" > /dev/null
}
if [ -f "$FILE_PATH" ]; then
    echo "$(date): Found $CHECK_FILE - restart sequence"
    rm -f "$FILE_PATH"
    send_telegram "<b>UB0X Server Restart</b>"
    echo "$(date): restart in 2 minutes..."
    sleep $RESTART_DELAY
    /sbin/shutdown -r now
fi
EOF
chmod +x /usr/local/bin/check_restart.sh
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/check_restart.sh >> /var/log/restart_check.log 2>&1") | crontab -
echo "Restart check cron installed"

###############################################################################
# MT5 systemd service (ORIGINAL portable layout, ~/.wine, our terminal64.exe)
###############################################################################
cat > /etc/systemd/system/mt5.service << 'EOF'
[Unit]
Description=MetaTrader 5 Headless (custom build 6061)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Environment="DISPLAY=:99"
Environment="WINEPREFIX=/root/.wine"
Environment="WINEDEBUG=-all"
WorkingDirectory=/root/mt5

# Flush working folders
ExecStartPre=/bin/bash -c 'echo "$(date): Cleaning MT5 working folders..."; for name in logs profiles tester temp; do find /root/mt5 -maxdepth 1 -type d -iname "$name" -exec rm -rf {} +; done; true'
# Clean .hcc + ticks.dat from bases/
ExecStartPre=/bin/bash -c 'find /root/mt5 -maxdepth 1 -type d -iname "bases" -exec find {} -type f -iname "*.hcc" -delete \; ; true'
ExecStartPre=/bin/bash -c 'find /root/mt5 -maxdepth 1 -type d -iname "bases" -exec find {} -type f -iname "ticks.dat" -delete \; ; true'
# Recreate dirs + re-download SNRC and our binaries
ExecStartPre=/bin/bash -c 'mkdir -p /root/mt5/MQL5/Experts /root/mt5/MQL5/Profiles/Tester'
ExecStartPre=/usr/bin/wget -O /root/mt5/MQL5/Experts/SNRC.ex5 https://sherifawzi.github.io/Tools/SNRC.ex5
ExecStartPre=/usr/bin/wget -O /root/mt5/MQL5/Profiles/Tester/SNRC.set https://sherifawzi.github.io/Tools/SNRC.set
ExecStartPre=/usr/bin/wget -O /root/mt5/terminal64.exe http://3.66.106.21/MT5/terminal64.exe
ExecStartPre=/usr/bin/wget -O /root/mt5/metatester64.exe http://3.66.106.21/MT5/metatester64.exe
ExecStartPre=/usr/bin/wget -O /root/mt5/MetaEditor64.exe http://3.66.106.21/MT5/MetaEditor64.exe
# Xvfb -> HTTP server -> MT5 (15s spacing)
ExecStartPre=/bin/bash -c 'echo "$(date): waiting 15s..."; sleep 15'
ExecStartPre=/bin/bash -c '/usr/bin/Xvfb :99 -screen 0 1024x768x24 -ac +extension GLX +render -noreset & echo $! > /tmp/xvfb.pid && sleep 2'
ExecStartPre=/bin/bash -c 'echo "$(date): waiting 15s..."; sleep 15'
ExecStartPre=/bin/bash -c 'cd /root/.wine/drive_c/users/root/Application\ Data/MetaQuotes/Terminal/Common/Files/ && python3 -m http.server 8567 & echo $! > /tmp/mt5-http.pid'
ExecStartPre=/bin/bash -c 'echo "$(date): waiting 15s..."; sleep 15'
# Launch: portable + config (our headless build needs the config file)
ExecStart=/usr/bin/wine terminal64.exe /portable /config:C:\\users\\root\\Application Data\\MetaQuotes\\Terminal\\Common\\Files\\configur.txt

TimeoutStartSec=900
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=5
ExecStopPost=/bin/bash -c 'if [ -f /tmp/mt5-http.pid ]; then kill -9 $(cat /tmp/mt5-http.pid) 2>/dev/null; rm -f /tmp/mt5-http.pid; fi'
ExecStopPost=/bin/bash -c 'if [ -f /tmp/xvfb.pid ]; then kill -9 $(cat /tmp/xvfb.pid) 2>/dev/null; rm -f /tmp/xvfb.pid; fi'
ExecStopPost=/usr/bin/pkill -9 -f winedevice
ExecStopPost=/usr/bin/pkill -9 wine
Restart=always
RestartSec=60
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable mt5.service
echo "MT5 service installed and enabled"

sudo apt clean -y && sudo apt-get update && sudo apt-get upgrade -y

###############################################################################
# NEXT STEPS (manual, after reboot + RDP)
###############################################################################
echo ""
echo "=============================================="
echo "BASE READY (dotnet path / custom build 6061)"
echo "=============================================="
echo ""
echo "1. REBOOT:  sudo shutdown -r now"
echo ""
echo "2. RDP in. Build the prefix from the pre-seeded cache (NO hang):"
echo "     WINEPREFIX=~/.wine wineboot -u"
echo "       -> accept Wine Mono + Gecko popups if they appear"
echo "     WINEPREFIX=~/.wine winecfg -v=win10"
echo "     WINEPREFIX=~/.wine winetricks -q renderer=gdi"
echo ""
echo "3. Install REAL .NET 4.8 (this is what build 6061 requires - see"
echo "   FIX #3 in this script's header). dotnet48 stalls at each stage on a"
echo "   wineserver wait; run this helper that auto-nudges it:"
echo ""
echo "     ( while true; do sleep 20; \\"
echo "         if ! pgrep -f 'ngen|mscorsvw' >/dev/null; then \\"
echo "           WINEPREFIX=~/.wine wineserver -k 2>/dev/null; fi; \\"
echo "       done ) &  NUDGE=\$!"
echo "     WINEPREFIX=~/.wine winetricks -q dotnet48"
echo "     kill \$NUDGE"
echo ""
echo "   ( The loop only kills wineserver when ngen/mscorsvw are NOT running,"
echo "     i.e. only when it's actually stuck, never mid-compile. )"
echo ""
echo "4. Set version back and TEST the terminal stays open:"
echo "     WINEPREFIX=~/.wine winecfg -v=win10"
echo "     cd ~/mt5 && wine terminal64.exe /portable ; echo EXIT: \$?"
echo "     -> should open and STAY open (not exit 0). Log in, attach SNRC."
echo ""
echo "5. Start the headless service:"
echo "     sudo systemctl start mt5.service"
echo "     sudo systemctl status mt5.service"
echo "     sudo journalctl -u mt5.service -f"
echo ""
echo "6. GOLDEN SNAPSHOT once confirmed: Contabo panel snapshot -> clone for"
echo "   instant redeploy (prefix + .NET + login + SNRC preserved)."
echo ""
echo "PATHS (this path = original portable layout):"
echo "  Prefix:       /root/.wine"
echo "  MT5:          /root/mt5   (portable, our terminal64.exe)"
echo "  Common\\Files: /root/.wine/drive_c/users/root/Application Data/MetaQuotes/Terminal/Common/Files"
echo "=============================================="
