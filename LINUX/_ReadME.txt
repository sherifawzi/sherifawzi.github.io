
cd /

sudo wget https://sherifawzi.github.io/LINUX/setup.sh

sudo chmod +x setup.sh

sudo ./setup.sh

sudo wget https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5ubuntu.sh

sudo chmod +x mt5ubuntu.sh

sudo ./mt5ubuntu.sh

cd /usr/local/bin/

sudo wget https://sherifawzi.github.io/LINUX/restart_monitor.sh

sudo chmod +x restart_monitor.sh

cd /etc/systemd/system/

sudo wget https://sherifawzi.github.io/LINUX/restart-monitor.service

sudo chmod +x restart-monitor.service

sudo systemctl daemon-reload

sudo systemctl enable restart-monitor.service

sudo systemctl start restart-monitor.service

- Edit the GDM3 configuration:

sudo nano /etc/gdm3/custom.conf

- Modify the file to look like this:

    [daemon]
    # Uncomment the line below to force the login screen to use Xorg
    #WaylandEnable=false
    
    # Enabling automatic login
    AutomaticLoginEnable = true
    AutomaticLogin = ubuntu

sudo shutdown -r now

- To test write the following:

touch /home/ubuntu/.mt5/dosdevices/c:/users/ubuntu/AppData/Roaming/MetaQuotes/Terminal/Common/Files/restart.me
