#!/bin/bash

   # >>> RUN ON UBUNTU 22.04 and NOT above 

   # sudo chmod +x snrnew.sh
   # sudo ./snrnew.sh

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

# Install Wine for MetaTrader 5
   sudo dpkg --add-architecture i386
   sudo apt update
   sudo apt install -y wine64 wine32 winetricks libgl1-mesa-glx

# Install Xvfb for headless operation
   sudo apt-get install -y xvfb

# Set Wine to Windows 10 mode & Disable debug messages
   export WINEPREFIX="$HOME/.wine"
   export WINEARCH=win64
   export WINEDEBUG=-all

# Download and Install MetaTrader 5
   mkdir -p ~/mt5
   cd ~/mt5
   wget https://www.snrobotix.com/MT5/terminal64.exe
   wget https://sherifawzi.github.io/Batch/configur.ini

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
    
    # Download the first file
    echo "$(date): Downloading SNRC.ex5..."
    wget -O /root/mt5/MQL5/Experts/SNRC.ex5 https://sherifawzi.github.io/Tools/SNRC.ex5

    # Download the second file
    echo "$(date): Downloading SNRC.set..."
    wget -O /root/mt5/MQL5/Profiles/Tester/SNRC.set https://sherifawzi.github.io/Tools/SNRC.set

    # Send Telegram notification
    HOSTNAME=$(hostname)
    send_telegram "<b>Ubuntu Server Restart</b>%0A%0AServer: ${HOSTNAME}%0AFiles updated successfully%0ARestarting in 2 minutes...%0ATime: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "$(date): Telegram notification sent"
    
    # Wait 2 minutes then restart
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

# Add auto-restart trigger (6.5 hours)
(crontab -l 2>/dev/null; echo "*/30 * * * * [ \$(/usr/bin/awk '{print int(\$1)}' /proc/uptime) -ge 23400 ] && touch '/root/.wine/drive_c/users/root/Application Data/MetaQuotes/Terminal/Common/Files/restart.txt'") | crontab -

echo "Restart check script installed and cron job configured"

###############################################################################
# Setup MT5 Systemd Service (Flow 2) - WITH IMPROVED SHUTDOWN HANDLING
###############################################################################

# Create the systemd service file
cat > /etc/systemd/system/mt5.service << 'EOF'
[Unit]
Description=MetaTrader 5 Headless
After=network.target

[Service]
Type=simple
User=root
Environment="DISPLAY=:99"
Environment="WINEPREFIX=/root/.wine"
WorkingDirectory=/root/mt5

# Initial delay
ExecStartPre=/bin/sleep 10

# Start Xvfb and track its PID
ExecStartPre=/bin/bash -c '/usr/bin/Xvfb :99 -screen 0 1024x768x24 -ac +extension GLX +render -noreset & echo $! > /tmp/xvfb.pid && sleep 2'

# Start Python HTTP server and track its PID
ExecStartPre=/bin/bash -c 'cd /root/.wine/drive_c/users/root/Application\ Data/MetaQuotes/Terminal/Common/Files/ && python3 -m http.server 8567 & echo $! > /tmp/mt5-http.pid'

# Main MT5 process
ExecStart=/usr/bin/wine terminal64.exe /portable /config:C:\\users\\root\\Application Data\\MetaQuotes\\Terminal\\Common\\Files\\configur.ini

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
RestartSec=30
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
echo "NEXT STEPS:"
echo ""
echo "1. REBOOT THE SERVER (required):"
echo "   sudo shutdown -r now"
echo ""
echo "2. After reboot, connect via RDP and run:"
echo "   winetricks corefonts"
echo "   winetricks vcrun2015"
echo "   winecfg"
echo ""
echo "3. Run MT5 manually first time to initialize Wine prefix:"
echo "   cd ~/mt5 && wine terminal64.exe"
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
echo "- Restart check script runs every 5 minutes via cron"
echo "- MT5 service will auto-start on future reboots"
echo "- Logs available: sudo journalctl -u mt5.service -f"
echo "- Improved shutdown handling ensures clean Wine process termination"
echo ""
echo "=============================================="
