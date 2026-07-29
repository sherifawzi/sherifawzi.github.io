#!/bin/bash

   # >>> RUN ON UBUNTU 24.04 (noble)   [snrnew_final_v2 - stock MT5 path]
   # OS base + RDP + Xvfb + MT5 automation ONLY. Wine and MT5 are installed
   # afterwards by MetaQuotes' own mt5linux.sh. Prefix ~/.mt5, non-portable.
   #
   # KEY LESSONS BAKED IN (see NEXT STEPS + inline notes):
   #  - Wine/MT5 installed by mt5linux.sh, NOT here (matches working box).
   #  - Everything MUST use WINEPREFIX=~/.mt5. A bare 'wine terminal64.exe'
   #    silently uses the default ~/.wine and scatters the EA's 8 output
   #    files (restart.txt etc.) into the wrong prefix. This caused a long
   #    "files missing" hunt - they were in ~/.wine all along.
   #  - Service does NOT flush 'profiles' (holds saved login + SNRC chart).
   #  - Config launch (/config:...configur.txt) kept for headless; dropped
   #    /portable (stock MT5 is non-portable).
   #  - Two items still need live confirmation before snapshot: login
   #    persistence across restart, and a full service test/restart cycle.

   # sudo -i
   # sudo passwd
   # sudo chmod +x snrnew_final_v2.sh
   # sudo ./snrnew_final_v2.sh

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

# Wine is NOT installed here - MetaQuotes' mt5linux.sh installs Wine itself
# (staging + win11) exactly as it does on the working box. This script only
# provides the OS base, RDP, Xvfb, and the automation around MT5.

# Install Xvfb for headless operation (needed by the service; MT5 script won't add it)
   sudo apt install -y wget curl xvfb

###############################################################################
# Setup Restart Check Script (Flow 1)
###############################################################################

# Common\Files path in the stock (non-portable) ~/.mt5 layout
cat > /usr/local/bin/check_restart.sh << 'EOF'
#!/bin/bash

# Configuration
CHECK_FOLDER="/root/.mt5/drive_c/users/root/AppData/Roaming/MetaQuotes/Terminal/Common/Files"
CHECK_FILE="restart.txt"
RESTART_DELAY=120  # 2 minutes in seconds

# Telegram credentials
BOT_ID="8802025176:AAFHuA1aqAXkk_55MXhzbhHvg7sqreBrtHA"
CHANNEL_ID="-1003285305833"

FILE_PATH="$CHECK_FOLDER/$CHECK_FILE"

send_telegram() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot${BOT_ID}/sendMessage" \
        -d chat_id="${CHANNEL_ID}" \
        -d text="${message}" \
        -d parse_mode="HTML" > /dev/null
}

if [ -f "$FILE_PATH" ]; then
    echo "$(date): Found $CHECK_FILE - Initiating restart sequence"
    rm -f "$FILE_PATH"
    echo "$(date): Deleted $CHECK_FILE"

    HOSTNAME=$(hostname)
    send_telegram "<b>UB0X Server Restart</b>"
    echo "$(date): Telegram notification sent"

    echo "$(date): System will restart in 2 minutes..."
    sleep $RESTART_DELAY
    /sbin/shutdown -r now
fi
EOF

chmod +x /usr/local/bin/check_restart.sh

(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/check_restart.sh >> /var/log/restart_check.log 2>&1") | crontab -

echo "Restart check script installed and cron job configured"

###############################################################################
# Setup MT5 Systemd Service (stock ~/.mt5 layout, non-portable)
###############################################################################

# Stock MT5 install dir inside the prefix
#   /root/.mt5/drive_c/Program Files/MetaTrader 5/
# Common\Files (restart.txt + HTTP server) is under AppData\Roaming.

cat > /etc/systemd/system/mt5.service << 'EOF'
[Unit]
Description=MetaTrader 5 Headless
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Environment="DISPLAY=:99"
Environment="WINEPREFIX=/root/.mt5"
Environment="WINEDEBUG=-all"
WorkingDirectory=/root/.mt5/drive_c/Program Files/MetaTrader 5

# --- Step 1: Flush MT5 working folders for a fresh start (case-insensitive) ---
# NOTE: 'profiles' is intentionally NOT flushed - it holds the saved login
# (auto-connect to 853300) and the SNRC chart setup. Flushing it wiped the
# login every boot. Keep logs/tester/temp cleanup only.
ExecStartPre=/bin/bash -c 'echo "$(date): Cleaning up MT5 working folders..."; BASE="/root/.mt5/drive_c/Program Files/MetaTrader 5"; for name in logs tester temp; do find "$BASE" -maxdepth 1 -type d -iname "$name" -exec rm -rf {} +; done; true'

# --- Step 1b: Clean .hcc files and ticks.dat from bases/ subtree ---
ExecStartPre=/bin/bash -c 'BASE="/root/.mt5/drive_c/Program Files/MetaTrader 5"; echo "$(date): Cleaning .hcc from bases/ ..."; find "$BASE" -maxdepth 1 -type d -iname "bases" -exec find {} -type f -iname "*.hcc" -delete \; ; true'
ExecStartPre=/bin/bash -c 'BASE="/root/.mt5/drive_c/Program Files/MetaTrader 5"; echo "$(date): Cleaning ticks.dat from bases/ ..."; find "$BASE" -maxdepth 1 -type d -iname "bases" -exec find {} -type f -iname "ticks.dat" -delete \; ; true'

# --- Step 2: Recreate MQL5 dirs and download fresh SNRC files ---
ExecStartPre=/bin/bash -c 'BASE="/root/.mt5/drive_c/Program Files/MetaTrader 5"; mkdir -p "$BASE/MQL5/Experts" "$BASE/MQL5/Profiles/Tester"'
ExecStartPre=/bin/bash -c '/usr/bin/wget -O "/root/.mt5/drive_c/Program Files/MetaTrader 5/MQL5/Experts/SNRC.ex5" https://sherifawzi.github.io/Tools/SNRC.ex5'
ExecStartPre=/bin/bash -c '/usr/bin/wget -O "/root/.mt5/drive_c/Program Files/MetaTrader 5/MQL5/Profiles/Tester/SNRC.set" https://sherifawzi.github.io/Tools/SNRC.set'

# --- Step 3: Wait 15s, then start Xvfb ---
ExecStartPre=/bin/bash -c 'echo "$(date): Prep complete, waiting 15s..."; sleep 15'

# --- Step 4: Start Xvfb and track its PID ---
ExecStartPre=/bin/bash -c '/usr/bin/Xvfb :99 -screen 0 1024x768x24 -ac +extension GLX +render -noreset & echo $! > /tmp/xvfb.pid && sleep 2'

# --- Step 5: Wait 15s, then start HTTP server ---
ExecStartPre=/bin/bash -c 'echo "$(date): Xvfb started, waiting 15s..."; sleep 15'

# --- Step 6: Start Python HTTP server in Common\Files ---
ExecStartPre=/bin/bash -c 'cd "/root/.mt5/drive_c/users/root/AppData/Roaming/MetaQuotes/Terminal/Common/Files/" && python3 -m http.server 8567 & echo $! > /tmp/mt5-http.pid'

# --- Step 7: Wait 15s, then launch MT5 ---
ExecStartPre=/bin/bash -c 'echo "$(date): HTTP server started, waiting 15s..."; sleep 15'

# --- Step 8: Main MT5 process (non-portable, config launch retained) ---
ExecStart=/usr/bin/wine "C:\\Program Files\\MetaTrader 5\\terminal64.exe" /config:C:\\users\\root\\AppData\\Roaming\\MetaQuotes\\Terminal\\Common\\Files\\configur.txt

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

echo "MT5 systemd service installed and enabled"

   sudo apt clean -y && sudo apt-get update && sudo apt-get upgrade -y

###############################################################################
# Installation Complete - Next Steps
###############################################################################
echo ""
echo "=============================================="
echo "BASE READY - now run mt5linux.sh for Wine + MT5"
echo "=============================================="
echo ""
echo "NEXT STEPS:"
echo ""
echo "1. REBOOT:"
echo "   sudo shutdown -r now"
echo ""
echo "2. After reboot, connect via RDP. Run MetaQuotes' own install script"
echo "   (mt5linux.sh) as a NORMAL user - it installs Wine AND MetaTrader 5"
echo "   into ~/.mt5, exactly as on the working box. Do NOT use sudo."
echo ""
echo "3. CRITICAL - prefix discipline. When you launch MT5 by hand for"
echo "   configuration, ALWAYS set the prefix, or Wine uses the default"
echo "   ~/.wine and your 8 EA files (restart.txt etc.) get written to the"
echo "   WRONG prefix where the service can't see them:"
echo ""
echo "     cd ~/.mt5/drive_c/Program\\ Files/MetaTrader\\ 5"
echo "     WINEPREFIX=~/.mt5 wine terminal64.exe"
echo ""
echo "      When closing MT5, make sure it closed by the following:"
echo "         WINEPREFIX=~/.mt5 wine tasklist 2>/dev/null | grep -i terminal"
echo ""
echo "      To fully close it write:"
echo "         WINEPREFIX=~/.mt5 wineserver -k"
echo ""
echo "      If the service ran and is stopping u from starting mt5:"
echo "         sudo systemctl stop mt5.service ; WINEPREFIX=~/.mt5 wineserver -k ; sleep 15"
echo ""
echo "      Never run a bare 'wine terminal64.exe'. If a stray ~/.wine appears,"
echo "         delete it:  rm -rf ~/.wine"
echo ""
echo "4. In MT5: log into account 853300 with 'Save account information'"
echo ""
echo "      https://sherifawzi.github.io"
echo "      https://t.me"
echo "      https://api.telegram.org"
echo "      http://3.66.106.21"
echo ""
echo "   save the profile. Confirm the 8 EA files land in:"
echo "     ~/.mt5/drive_c/users/root/AppData/Roaming/MetaQuotes/Terminal/Common/Files/"
echo ""
echo "5. Verify the headless service:"
echo "   sudo systemctl start mt5.service"
echo "   sudo systemctl status mt5.service"
echo "   sudo journalctl -u mt5.service -f"
echo ""
echo "   >>> CONFIRM BEFORE SNAPSHOT (not yet verified as of this script):"
echo "       (a) Login PERSISTS across a service restart (auto-connects to"
echo "           853300 with no manual login). If not, check 'Save account"
echo "           information' was ticked and that profiles isn't being wiped."
echo "       (b) A FULL service cycle completes: Xvfb -> login -> tester run"
echo "           -> writes restart.txt -> restart loop fires."
echo ""
echo "6. MT5 files via browser:  http://YOUR_SERVER_IP:8567"
echo ""
echo "7. GOLDEN SNAPSHOT (only after 5a + 5b confirmed):"
echo "   Take a Contabo panel snapshot of this VPS. Deploy new machines"
echo "   from it for instant redeploy - prefix + MT5 + login + SNRC all"
echo "   preserved, no reinstall. NOTE: prefix has /root absolute paths"
echo "   baked in, so clones MUST also run as root with home /root."
echo ""
echo "NOTES:"
echo "- Wine + MT5 are installed by mt5linux.sh, NOT by this script."
echo "- NEVER use SUDO with Wine commands."
echo "- Prefix: /root/.mt5   MT5: '/root/.mt5/drive_c/Program Files/MetaTrader 5'"
echo "- Common\\Files: /root/.mt5/drive_c/users/root/AppData/Roaming/MetaQuotes/Terminal/Common/Files"
echo "- Restart check runs every 5 min via cron."
echo "- mt5.service at every boot: flush logs/tester/temp (NOT profiles -"
echo "  profiles holds saved login + SNRC chart, must persist), clean"
echo "  .hcc + ticks.dat, re-download SNRC, start Xvfb -> HTTP server -> MT5."
echo "- Logs: sudo journalctl -u mt5.service -f"
echo ""
echo "=============================================="
