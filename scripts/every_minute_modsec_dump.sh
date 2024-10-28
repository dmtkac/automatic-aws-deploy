#!/bin/bash

# Paths for the audit log file inside Docker and the corresponding file on the host
MODSEC_LOG_PATH="/var/log/modsec_audit.log"
HOST_LOG_FILE="/home/ubuntu/modsec_audit.log"
HOST_OLD_LOG_FILE="/home/ubuntu/modsec_audit_old.log"
MAX_SIZE=52428800 # 50 MB in bytes

# Ensures the log file exists on the host, create if not
if [ ! -f "$HOST_LOG_FILE" ]; then
    touch "$HOST_LOG_FILE"
fi

# Dumps the ModSecurity audit log from the Docker container to the host file
docker exec web_app-gateway-1 cat $MODSEC_LOG_PATH >> $HOST_LOG_FILE
if [ $? -ne 0 ]; then
    echo "Failed to dump ModSecurity audit log."
    exit 1
fi

# Clears the audit log file inside the Docker container to avoid log buildup
docker exec web_app-gateway-1 bash -c "echo '' > $MODSEC_LOG_PATH"
if [ $? -ne 0 ]; then
    echo "Failed to clear ModSecurity audit log inside Docker."
    exit 1
fi

# Rotates logs if needed
if [ $(stat -c %s "$HOST_LOG_FILE") -ge $MAX_SIZE ]; then
    if [ -f "$HOST_OLD_LOG_FILE" ]; then
        rm "$HOST_OLD_LOG_FILE" || { echo "Failed to remove old log file."; exit 1; }
    fi
    mv "$HOST_LOG_FILE" "$HOST_OLD_LOG_FILE" || { echo "Failed to rotate log file."; exit 1; }
    touch "$HOST_LOG_FILE" || { echo "Failed to create new log file."; exit 1; }
fi