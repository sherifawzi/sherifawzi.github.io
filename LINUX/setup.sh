	#!/bin/bash
	
	# -------------------- Update package lists and upgrade system
	sudo apt-get clean -y && sudo apt-get update && sudo apt-get upgrade -y
	sudo apt-get clean -y && sudo apt-get update && sudo apt-get upgrade -y
	sudo apt-get clean -y && sudo apt-get update && sudo apt-get upgrade -y
	
	# -------------------- Install Ubuntu MATE desktop environment
	# sudo apt-get install ubuntu-mate-core -y
	sudo apt-get install ubuntu-desktop -y
	
	# -------------------- Install XRDP for remote desktop access
	sudo apt-get install xrdp -y
	sudo systemctl enable xrdp
	
	# -------------------- Configure XRDP for better performance
	echo "export PULSE_LATENCY_MSEC=60" | sudo tee -a /etc/xrdp/xrdp.ini
	echo "ts_setup" | sudo tee -a /etc/xrdp/xrdp.ini
	
	# -------------------- Create a new user account
	sudo useradd -m ubuntu
	sudo passwd ubuntu
	
	# -------------------- Add the new user to the sudo group
	sudo usermod -aG sudo ubuntu
	groups ubuntu
	
	# -------------------- Diable screen lock and idle
	sudo gsettings set org.gnome.desktop.session idle-delay 0
	sudo gsettings set org.gnome.desktop.screensaver lock-enabled false
	sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

	# -------------------- Clean up and optimize the system
	sudo apt-get clean -y && sudo apt-get update && sudo apt-get upgrade -y
	sudo shutdown -r now

