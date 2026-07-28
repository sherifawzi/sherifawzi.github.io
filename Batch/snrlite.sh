#!/bin/bash

   # >>> RUN ON UBUNTU 24.04 (noble)
   # Clean base: XFCE desktop + XRDP only. NO Wine, NO MT5.
   # Purpose: RDP in, then run MetaQuotes' own mt5 install script to test it.

   # sudo -i
   # sudo passwd
   # sudo chmod +x snrbase_rdp.sh
   # sudo ./snrbase_rdp.sh

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

echo ""
echo "=============================================="
echo "BASE READY - RDP ENABLED, NO WINE INSTALLED"
echo "=============================================="
echo ""
echo "NEXT STEPS:"
echo ""
echo "1. REBOOT:"
echo "   sudo shutdown -r now"
echo ""
echo "2. Connect via RDP (port 3389)."
echo ""
echo "3. Open a terminal and run MetaQuotes' own MT5 install script"
echo "   to test whether their recipe builds Wine + MT5 without hanging."
echo ""
echo "   Run it as a NORMAL user, NOT with sudo (Wine must not run as root"
echo "   via sudo). The script itself calls sudo where it needs to."
echo ""
echo "=============================================="
