#!/bin/bash

   # sudo chmod +x snrtestsetup.sh
   # sudo ./snrtestsetup.sh
   
   # https://sherifawzi.github.io
   # https://t.me
   # https://api.telegram.org
   # http://3.66.106.21

# 1. Install Desktop Environment (XFCE - lightweight and good for RDP)
   sudo apt clean -y && sudo apt-get update && sudo apt-get upgrade -y
   sudo apt install -y xfce4 xfce4-goodies

# 2. Install XRDP for Remote Desktop
   sudo apt install -y xrdp
   sudo systemctl enable xrdp
   sudo systemctl start xrdp

# 3. Configure XRDP to use XFCE
   echo xfce4-session > ~/.xsession
   sudo systemctl restart xrdp

#4. Configure Firewall (if enabled)
   sudo ufw allow 3389/tcp

# 5. Install Wine for MetaTrader 5
   sudo dpkg --add-architecture i386
   sudo apt update
   sudo apt install -y wine64 wine32 winetricks
   winetricks vcrun2015 corefonts
   export WINEDEBUG=-all

# 6. Download and Install MetaTrader 5
   mkdir -p ~/mt5
   cd ~/mt5
   sudo wget https://sherifawzi.github.io/Tools/mt5setup.exe
   sudo wget https://sherifawzi.github.io/Pics/SNRTSTBKG.jpg
   sudo wget https://sherifawzi.github.io/Tools/SNRC.ex5
   sudo wget https://sherifawzi.github.io/Tools/SNRC.set
   sudo wget https://www.snrobotix.com/MT5/terminal64.exe

# 7. Keep everything up to date before restart
sudo apt clean -y && sudo apt-get update && sudo apt-get upgrade -y

###############################################################################
# Installation Complete - Next Steps
###############################################################################
echo ""
echo "NEXT STEPS:"
echo ""
echo "1. REBOOT THE SERVER (recommended):"
echo "   sudo shutdown -r now"
echo ""
echo "2. Once connected via RDP:"
echo "   - Run: cd ~/mt5 && wine terminal64.exe"
echo ""
echo "Note: DONT use SUDO with Wine EVER!!"
echo ""
echo "=========================================="

