#!/bin/bash

LOG_FILE="/home/ubuntu/gateway_logs.log"
OLD_LOG_FILE="/home/ubuntu/gateway_logs_old.log"
MAX_SIZE=10485760 # 10 MB in bytes
LAST_DUMP_FILE="/home/ubuntu/last_dump_time.txt"

# Get the last dump time, or use the current time if the file doesn't exist
if [ -f "$LAST_DUMP_FILE" ]; then
    LAST_DUMP_TIME=$(cat "$LAST_DUMP_FILE")
else
    LAST_DUMP_TIME=$(date --iso-8601=seconds)
fi

# Dumps logs into the log file
docker logs gateway --since "$LAST_DUMP_TIME" >> "$LOG_FILE"

# Updates the last dump time
date --iso-8601=seconds > "$LAST_DUMP_FILE"

# Checks if the log file size exceeds the maximum size
if [ $(stat -c%s "$LOG_FILE") -ge $MAX_SIZE ]; then
    # Deletes the old log file if it exists
    if [ -f "$OLD_LOG_FILE" ]; then
        rm "$OLD_LOG_FILE"
    fi

    # Renames the current log file to the old log file
    mv "$LOG_FILE" "$OLD_LOG_FILE"

    # Creates a new log file
    touch "$LOG_FILE"
fi