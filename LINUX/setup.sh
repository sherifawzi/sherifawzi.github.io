	#!/bin/bash
	
	# -------------------- Update package lists and upgrade system
	sudo apt-get update && sudo apt-get upgrade -y
	sudo apt-get clean -y
	
	# -------------------- Install Ubuntu desktop environment
	sudo apt-get install ubuntu-desktop -y
	
	# -------------------- Install XRDP for remote desktop access
	sudo apt-get install xrdp -y
	sudo systemctl enable xrdp
	sudo systemctl start xrdp
	
	# -------------------- Create a new user account
	sudo useradd -m ubuntu
	# -------------------- Note: You'll need to set the password manually or use a secure method
	# -------------------- sudo echo "ubuntu:password" | chpasswd  # Be cautious with this method
	
	# -------------------- Add the new user to the sudo group
	sudo usermod -aG sudo ubuntu
	groups ubuntu
	
	# -------------------- Disable screen lock and idle
	gsettings set org.gnome.desktop.session idle-delay 0
	gsettings set org.gnome.desktop.screensaver lock-enabled false
	
	# -------------------- Optionally prevent sleep (use with caution)
	sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

	# -------------------- Install CURL
 	sudo apt-get install -y curl jq
 
	# -------------------- Final system cleanup
	sudo apt-get clean -y
	
	# -------------------- Reboot the system
	sudo shutdown -r now
