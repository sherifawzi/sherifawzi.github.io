#!/bin/bash

   # >>> RUN ON UBUNTU 24.04 (noble) and NOT above

   # sudo -i
   # sudo passwd
   # sudo chmod +x snrnew5.sh
   # sudo ./snrnew5.sh

# Install Desktop Environment (XFCE - lightweight and good for RDP)
   sudo apt clean -y && sudo apt-get update && sudo apt-get upgrade -y
   sudo apt install -y xfce4 xfce4-goodies

# Install XRDP for Remote Desktop
   sudo apt install -y xrdp
   sudo systemctl enable xrdp
   sudo systemctl start xrdp

# Configure XRDP to use XFCE
   echo xfce4-session > ~/.xsession
   sudo systemctl restart xrdp

# Configure Firewall (if enabled)
   sudo ufw allow 3389/tcp
   sudo ufw allow 8567/tcp

# Install Wine (staging) from the official WineHQ repository
# New MT5 build needs Wine 11.3+ for WebView2; stable is only 11.0, so staging is required.
# We pin+hold the installed version so apt upgrade cannot move it later.
   sudo apt install -y wget gpg bc
   sudo dpkg --add-architecture i386
   sudo mkdir -pm755 /etc/apt/keyrings
   sudo rm -f /etc/apt/sources.list.d/winehq*
   sudo wget -O - https://dl.winehq.org/wine-builds/winehq.key | sudo gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key -
   sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/noble/winehq-noble.sources
   sudo apt update
   sudo apt install --install-recommends -y winehq-staging

# Pin the exact staging version that just installed, then hold it (stability)
# Hold every installed wine-staging/winehq package so apt upgrade cannot move it.
   WINE_PKG_VER=$(dpkg-query -W -f='${Version}' wine-staging-amd64 2>/dev/null)
   echo "Installed Wine staging version: $WINE_PKG_VER"
   HELD=$(dpkg-query -W -f='${Package}\n' 'winehq-*' 'wine-staging*' 2>/dev/null | sort -u)
   if [ -n "$HELD" ]; then
     sudo apt-mark hold $HELD
   fi

# Install winetricks AFTER WineHQ (so it does not pull in distro wine)
   sudo apt install -y winetricks libgl1

# Install Xvfb for headless operation
   sudo apt-get install -y xvfb

# Set Wine to Windows mode & Disable debug messages
# (prefix is initialized on first manual GUI run; set win11 there - see NEXT STEPS)
   export WINEPREFIX="$HOME/.wine"
   export WINEARCH=win64
   export WINEDEBUG=-all

# Download and Install MetaTrader 5
   mkdir -p ~/mt5
   cd ~/mt5
   wget https://www.snrobotix.com/MT5/terminal64.exe

# Create necessary directories for MT5
   mkdir -p ~/mt5/MQL5/Experts
   cd ~/mt5/MQL5/Experts
   wget https://sherifawzi.github.io/Tools/SNRC.ex5

   mkdir -p ~/mt5/MQL5/Profiles/Tester
   cd ~/mt5/MQL5/Profiles/Tester
   wget https://sherifawzi.github.io/Tools/SNRC.set

# Turn off wine logging permanently
   echo 'export WINEDEBUG=-all' >> ~/.bashrc

###############################################################################
# Setup Restart Check Script (Flow 1)
###############################################################################

# Create the restart check script
cat > /usr/local/bin/check_restart.sh << 'EOF'
#!/bin/bash

# Configuration
CHECK_FOLDER="/root/.wine/drive_c/users/root/Application Data/MetaQuotes/Terminal/Common/Files"
CHECK_FILE="restart.txt"
RESTART_DELAY=120  # 2 minutes in seconds

# Telegram credentials
BOT_ID="8450507003:AAHhqJg_6x_ajStvx2_eoZRHnVIRpexzQc4"
CHANNEL_ID="-1003285305833"

# Full path to the file
FILE_PATH="$CHECK_FOLDER/$CHECK_FILE"

# Function to send Telegram message
send_telegram() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot${BOT_ID}/sendMessage" \
        -d chat_id="${CHANNEL_ID}" \
        -d text="${message}" \
        -d parse_mode="HTML" > /dev/null
}

# Check if the file exists
if [ -f "$FILE_PATH" ]; then
    echo "$(date): Found $CHECK_FILE - Initiating restart sequence"

    # Delete the file
    rm -f "$FILE_PATH"
    echo "$(date): Deleted $CHECK_FILE"

    # Send Telegram notification
    HOSTNAME=$(hostname)
    send_telegram "<b>UB0X Server Restart</b>"
    echo "$(date): Telegram notification sent"

    # Wait 2 minutes then restart
    # Note: MT5 working folders will be flushed and files re-downloaded
    # at boot time by mt5.service
    echo "$(date): System will restart in 2 minutes..."
    sleep $RESTART_DELAY

    # Restart the system
    /sbin/shutdown -r now
fi
EOF

# Make it executable
chmod +x /usr/local/bin/check_restart.sh

# Add to root's crontab
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/check_restart.sh >> /var/log/restart_check.log 2>&1") | crontab -

echo "Restart check script installed and cron job configured"

###############################################################################
# Setup MT5 Systemd Service - Single service handles everything:
#   1. Flush working folders (clean slate)
#   2. Clean .hcc and ticks.dat files from bases folder
#   3. Re-download fresh files (SNRC + 1/2/3.exe)
#   4. Wait 60 seconds
#   5. Start Xvfb + HTTP server + MetaTrader
###############################################################################

# Create the systemd service file
cat > /etc/systemd/system/mt5.service << 'EOF'
[Unit]
Description=MetaTrader 5 Headless
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Environment="DISPLAY=:99"
Environment="WINEPREFIX=/root/.wine"
Environment="WINEDEBUG=-all"
WorkingDirectory=/root/mt5

# --- Step 1: Flush MT5 working folders for a fresh start (case-insensitive) ---
ExecStartPre=/bin/bash -c 'echo "$(date): Cleaning up MT5 working folders..."; for name in logs profiles tester temp; do find /root/mt5 -maxdepth 1 -type d -iname "$name" -exec rm -rf {} +; done; true'

# --- Step 1b: Clean .hcc files and ticks.dat from bases/ folder and all subfolders ---
ExecStartPre=/bin/bash -c 'echo "$(date): Cleaning .hcc files from bases/ ..."; find /root/mt5 -maxdepth 1 -type d -iname "bases" -exec find {} -type f -iname "*.hcc" -delete \; ; true'
ExecStartPre=/bin/bash -c 'echo "$(date): Cleaning ticks.dat files from bases/ ..."; find /root/mt5 -maxdepth 1 -type d -iname "bases" -exec find {} -type f -iname "ticks.dat" -delete \; ; true'

# --- Step 2: Recreate directories and download fresh files ---
ExecStartPre=/bin/bash -c 'mkdir -p /root/mt5/MQL5/Experts /root/mt5/MQL5/Profiles/Tester'
ExecStartPre=/usr/bin/wget -O /root/mt5/MQL5/Experts/SNRC.ex5 https://sherifawzi.github.io/Tools/SNRC.ex5
ExecStartPre=/usr/bin/wget -O /root/mt5/MQL5/Profiles/Tester/SNRC.set https://sherifawzi.github.io/Tools/SNRC.set
ExecStartPre=/usr/bin/wget -O /root/mt5/terminal64.exe http://3.66.106.21/MT5/terminal64.exe
ExecStartPre=/usr/bin/wget -O /root/mt5/metatester64.exe http://3.66.106.21/MT5/metatester64.exe
ExecStartPre=/usr/bin/wget -O /root/mt5/MetaEditor64.exe http://3.66.106.21/MT5/MetaEditor64.exe

# --- Step 3: Wait 15s, then start Xvfb ---
ExecStartPre=/bin/bash -c 'echo "$(date): Downloads complete, waiting 15s..."; sleep 15'

# --- Step 4: Start Xvfb and track its PID ---
ExecStartPre=/bin/bash -c '/usr/bin/Xvfb :99 -screen 0 1024x768x24 -ac +extension GLX +render -noreset & echo $! > /tmp/xvfb.pid && sleep 2'

# --- Step 5: Wait 15s, then start HTTP server ---
ExecStartPre=/bin/bash -c 'echo "$(date): Xvfb started, waiting 15s..."; sleep 15'

# --- Step 6: Start Python HTTP server and track its PID ---
ExecStartPre=/bin/bash -c 'cd /root/.wine/drive_c/users/root/Application\ Data/MetaQuotes/Terminal/Common/Files/ && python3 -m http.server 8567 & echo $! > /tmp/mt5-http.pid'

# --- Step 7: Wait 15s, then launch MT5 ---
ExecStartPre=/bin/bash -c 'echo "$(date): HTTP server started, waiting 15s..."; sleep 15'

# --- Step 8: Main MT5 process ---
ExecStart=/usr/bin/wine terminal64.exe /portable /config:C:\\users\\root\\Application Data\\MetaQuotes\\Terminal\\Common\\Files\\configur.txt

# Allow generous time for downloads + 60s wait before MT5 itself starts
TimeoutStartSec=900

# Force kill everything with proper escalation
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=5

# Clean up tracked processes
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

# Reload systemd and enable the service (but don't start it yet)
systemctl daemon-reload
systemctl enable mt5.service

echo "MT5 systemd service installed and enabled"

# Keep everything up to date before restart
   sudo apt clean -y && sudo apt-get update && sudo apt-get upgrade -y

###############################################################################
# Installation Complete - Next Steps
###############################################################################
echo ""
echo "=============================================="
echo "INSTALLATION COMPLETE!"
echo "=============================================="
echo ""
echo "Wine version installed:"
wine --version
echo ""
echo "NEXT STEPS:"
echo ""
echo "1. REBOOT THE SERVER (required):"
echo "   sudo shutdown -r now"
echo ""
echo "2. After reboot, connect via RDP and run (in this order):"
echo "   wineboot"
echo "   winecfg -v=win11"
echo "   wine reg add \"HKCU\\Software\\Wine\\DllOverrides\" /v winhttp /d native,builtin /f"
echo "   winetricks corefonts"
echo "   winetricks -q renderer=gdi"
echo ""
echo "   NOTE: 'wineboot' will pop up Wine Mono and Gecko installers."
echo "   Click Install on BOTH and let them finish (one time only)."
echo "   Do NOT run any DLL overrides to suppress them - that corrupts the prefix."
echo ""
echo "3. Run MT5 manually first time to configure account + parameters:"
echo "   cd ~/mt5 && wine terminal64.exe"
echo ""
echo "   NOTE: on first launch MT5 installs WebView2 itself in the background."
echo "   The UI may be blank or freeze for a few minutes - let it sit, then"
echo "   close and relaunch. Do NOT install WebView2 by hand."
echo ""
echo "   https://sherifawzi.github.io"
echo "   https://t.me"
echo "   https://api.telegram.org"
echo "   http://3.66.106.21"
echo ""
echo "4. After MT5 is configured and working, start the service:"
echo "   sudo systemctl start mt5.service"
echo "   sudo systemctl status mt5.service"
echo ""
echo "5. Access MT5 files via web browser:"
echo "   http://YOUR_SERVER_IP:8567"
echo ""
echo "NOTES:"
echo "- NEVER use SUDO with Wine commands!"
echo "- Wine staging (pinned + held) from WineHQ repo - new MT5 needs 11.3+"
echo "- Prefix runs in win11 mode (required by new MT5 WebView2)"
echo "- Restart check script runs every 5 minutes via cron"
echo "- mt5.service handles everything at every boot:"
echo "    1. Flushes logs/profiles/Tester/Temp folders (case-insensitive)"
echo "    2. Removes all .hcc files and ticks.dat from bases/ subtree"
echo "    3. Re-downloads SNRC.ex5, SNRC.set, and 1/2/3.exe"
echo "    4. Sleeps 15s -> starts Xvfb"
echo "    5. Sleeps 15s -> starts Python HTTP server"
echo "    6. Sleeps 15s -> launches MetaTrader"
echo "- MT5 service auto-starts on boot"
echo "- Logs available: sudo journalctl -u mt5.service -f"
echo "- Improved shutdown handling ensures clean Wine process termination"
echo ""
echo "=============================================="
