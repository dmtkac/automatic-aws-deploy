#!/bin/bash

LOGFILE="/home/ubuntu/nginx_update.log"

# Function to log commands and their output
log_command() {
    echo " * Running: $*" | sudo tee -a "$LOGFILE"
    "$@" 2>&1 | sudo tee -a "$LOGFILE"
    local exit_code=${PIPESTATUS[0]}
    if [ $exit_code -ne 0 ]; then
        echo " ! Error: Command failed with exit code $exit_code" | sudo tee -a "$LOGFILE"
    fi
    return $exit_code
}

# Function to retrieve the public IP of the instance using OpenDNS
get_public_ip() {
    log_command dig +short myip.opendns.com @resolver1.opendns.com
}

# Function to update nginx.conf and handle SSL certificates
update_nginx_conf() {
    echo " * Updating nginx.conf and handling SSL certificates..." | sudo tee -a "$LOGFILE"
    local INSTANCE_PUBLIC_IP=$(get_public_ip | tail -n 1)
    local escaped_ip=$(echo "$INSTANCE_PUBLIC_IP" | sed 's/[&/\]/\\&/g')

    # Replaces 'localhost' with the instance's public IP
    log_command sudo sed -i "s|localhost|$escaped_ip|g" /home/ubuntu/nginx.conf

    # Generates a self-signed certificate
    echo " * Generating a self-signed certificate..." | sudo tee -a "$LOGFILE"
    log_command sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /home/ubuntu/certs/selfsigned.key -out /home/ubuntu/certs/selfsigned.crt -subj "/CN=$escaped_ip"
}

# Runs the update function
update_nginx_conf