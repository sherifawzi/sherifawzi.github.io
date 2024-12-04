
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
