#!/bin/bash

   # sudo chmod +x snrtestsetup.sh
   # sudo ./snrtestsetup.sh
   
   # https://sherifawzi.github.io
   # https://t.me
   # https://api.telegram.org
   # http://3.66.106.21

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

# Install Wine for MetaTrader 5
   sudo dpkg --add-architecture i386
   sudo apt update
   sudo apt install -y wine64 wine32 winetricks mesa-utils libgl1-mesa-glx

# Set Wine to Windows 10 mode & Disable debug messages
   export WINEPREFIX="$HOME/.wine"
   export WINEARCH=win64
   export WINEDEBUG=-all

# Set Wine to Windows 10 mode & Disable debug messages
   winetricks vcrun2015 corefonts
   winecfg

# Download and Install MetaTrader 5
   mkdir -p ~/mt5
   cd ~/mt5
   wget https://sherifawzi.github.io/Tools/mt5setup.exe
   wget https://sherifawzi.github.io/Pics/SNRTSTBKG.jpg
   wget https://sherifawzi.github.io/Tools/SNRC.ex5
   wget https://sherifawzi.github.io/Tools/SNRC.set
   wget https://www.snrobotix.com/MT5/terminal64.exe

# Keep everything up to date before restart
   sudo apt clean -y && sudo apt-get update && sudo apt-get upgrade -y

# Turn off wine logging permanently
   echo 'export WINEDEBUG=-all' >> ~/.bashrc

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

