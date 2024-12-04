
#!/bin/bash

# Path to the directory to monitor (change this to your desired directory)
MONITOR_DIR="/home/ubuntu/.mt5/dosdevices/c:/users/ubuntu/AppData/Roaming/MetaQuotes/Terminal/Common/Files"
LOG_FILE="/var/log/restart_monitor.log"
TELEGRAM_BOT_TOKEN="6385486447:AAEZCGszJz5U-71Dm8lrePiUsZR6sPx2Y18"
TELEGRAM_CHAT_ID="-1002087660238"
RESTART_INTERVAL=450

# Ensure the monitor directory exists
mkdir -p "$MONITOR_DIR"
chmod 777 "$MONITOR_DIR"

# Log file to track script operations
LOG_FILE="/var/log/restart_monitor.log"

# Function to log messages
log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local full_message="${timestamp} - ${message}"
    # -------------------- Send Telegram message
    local encoded_message=$(printf "%s" "$message" | jq -s -R -r @uri)
    curl -s -X GET "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage?chat_id=${TELEGRAM_CHAT_ID}&parse_mode=HTML&text=${encoded_message}" > /dev/null
    # -------------------- Save to log file
    echo "$full_message" >> "$LOG_FILE"
    # -------------------- Echo to command line
    echo "$full_message"
}

# Function to check and handle restart trigger
check_restart_trigger() {
    # Path to the restart trigger file
    RESTART_FILE="${MONITOR_DIR}/restart.me"

    # Check if the restart trigger file exists
    if [ -f "$RESTART_FILE" ]; then
        # Log the restart attempt
        log_message "Restart trigger found. Removing trigger file and restarting server."
        
        # Remove the restart trigger file
        rm "$RESTART_FILE"
        
        # Log the file removal
        log_message "Trigger file removed."
        
        # Restart the server
        systemctl reboot
    fi
}

# Log script startup
log_message "Restart monitor script started."

# Run continuously, checking every 3 minutes
while true; do
    check_restart_trigger
    sleep 180  # Sleep for 3 minutes (180 seconds)
done
