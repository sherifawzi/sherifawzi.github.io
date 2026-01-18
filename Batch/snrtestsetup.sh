#!/bin/bash

###############################################################################
# MetaTrader 5 + XRDP Setup Script for Ubuntu Server
# This script installs a desktop environment and configures RDP access
###############################################################################

set -e  # Exit on any error

echo "=========================================="
echo "Starting MT5 + XRDP Setup"
echo "=========================================="
echo ""

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

###############################################################################
# STEP 1: Update system packages
###############################################################################
echo -e "${BLUE}[STEP 1/6]${NC} Updating system packages..."
echo "This ensures all package lists are current before installation"
sudo apt update
echo -e "${GREEN}✓ System packages updated${NC}"
echo ""

###############################################################################
# STEP 2: Install XFCE Desktop Environment
###############################################################################
echo -e "${BLUE}[STEP 2/6]${NC} Installing XFCE Desktop Environment..."
echo "XFCE is lightweight and works well with RDP"
echo "xfce4-goodies includes useful additional applications"
sudo apt install -y xfce4 xfce4-goodies
echo -e "${GREEN}✓ XFCE Desktop installed${NC}"
echo ""

###############################################################################
# STEP 3: Install and Configure XRDP
###############################################################################
echo -e "${BLUE}[STEP 3/6]${NC} Installing XRDP server..."
echo "XRDP allows Windows Remote Desktop to connect to Linux"
sudo apt install -y xrdp

echo "Configuring XRDP to use XFCE..."
# Set XFCE as the default session for the current user
echo xfce4-session > ~/.xsession

# Also create a startup script for XRDP
sudo bash -c 'cat > /etc/xrdp/startwm.sh <<EOF
#!/bin/sh
if [ -r /etc/default/locale ]; then
  . /etc/default/locale
  export LANG LANGUAGE
fi
startxfce4
EOF'

# Make the startup script executable
sudo chmod +x /etc/xrdp/startwm.sh

echo "Enabling XRDP service to start on boot..."
sudo systemctl enable xrdp

echo "Starting XRDP service..."
sudo systemctl start xrdp
echo -e "${GREEN}✓ XRDP installed and configured${NC}"
echo ""

###############################################################################
# STEP 4: Configure Firewall (if UFW is active)
###############################################################################
echo -e "${BLUE}[STEP 4/6]${NC} Configuring firewall..."
if sudo ufw status | grep -q "Status: active"; then
    echo "UFW firewall is active, adding RDP port (3389)..."
    sudo ufw allow 3389/tcp
    echo -e "${GREEN}✓ Firewall configured - RDP port 3389 opened${NC}"
else
    echo "UFW firewall is not active, skipping firewall configuration"
    echo "Note: Ensure your Contabo firewall allows port 3389"
fi
echo ""

###############################################################################
# STEP 5: Install Wine for Windows Applications
###############################################################################
echo -e "${BLUE}[STEP 5/6]${NC} Installing Wine..."
echo "Wine allows running Windows applications (like MT5) on Linux"

echo "Enabling 32-bit architecture support..."
sudo dpkg --add-architecture i386

echo "Updating package lists with 32-bit support..."
sudo apt update

echo "Installing Wine and Winetricks..."
echo "This may take several minutes..."
sudo apt install -y wine64 wine32 winetricks

echo "Configuring Wine initial setup..."
# Run winecfg once to initialize Wine (will create ~/.wine directory)
DISPLAY=:0 winecfg &
sleep 5
pkill winecfg || true

echo -e "${GREEN}✓ Wine installed and configured${NC}"
echo ""

###############################################################################
# STEP 6: Download and Prepare MT5 Installation
###############################################################################
echo -e "${BLUE}[STEP 6/6]${NC} Downloading MetaTrader 5..."

# Create directory for MT5
MT5_DIR="$HOME/mt5"
mkdir -p "$MT5_DIR"
cd "$MT5_DIR"

echo "Downloading MT5 installer..."
# Download the latest MT5 installer
wget -O mt5setup.exe https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe

echo -e "${GREEN}✓ MT5 installer downloaded to $MT5_DIR${NC}"
echo ""

###############################################################################
# Installation Complete - Next Steps
###############################################################################
echo "=========================================="
echo -e "${GREEN}Installation Complete!${NC}"
echo "=========================================="
echo ""
echo "NEXT STEPS:"
echo ""
echo "1. REBOOT THE SERVER (recommended):"
echo "   sudo reboot"
echo ""
echo "2. After reboot, connect via RDP:"
echo "   - Open Remote Desktop Connection on Windows"
echo "   - Enter your server IP address"
echo "   - Use your Ubuntu username and password"
echo ""
echo "3. Once connected via RDP, install MT5:"
echo "   - Open a terminal in the RDP session"
echo "   - Run: cd ~/mt5 && wine mt5setup.exe"
echo "   - Follow the MT5 installation wizard"
echo ""
echo "4. Create a desktop shortcut for MT5 (optional):"
echo "   After installation, you can create a shortcut to launch MT5"
echo ""
echo "TROUBLESHOOTING:"
echo "- Check XRDP status: sudo systemctl status xrdp"
echo "- View XRDP logs: sudo tail -f /var/log/xrdp.log"
echo "- Restart XRDP: sudo systemctl restart xrdp"
echo ""
echo "Port Information:"
echo "- RDP Port: 3389 (ensure this is open in Contabo firewall)"
echo ""
echo "=========================================="
