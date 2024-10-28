#!/bin/bash

LOGFILE="/home/ubuntu/nginx_update_after_pull.log"

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

# Function to extract nginx.conf from the running container
extract_nginx_conf() {
    echo " * Extracting nginx.conf from the 'gateway' container..." | sudo tee -a "$LOGFILE"
    sudo docker cp web_app-gateway-1:/etc/nginx/nginx.conf /home/ubuntu/nginx.conf
    if [ $? -ne 0 ]; then
        echo " ! Failed to extract nginx.conf from the container." | sudo tee -a "$LOGFILE"
        exit 1
    else
        echo " + Successfully extracted nginx.conf." | sudo tee -a "$LOGFILE"
    fi
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
}

# Function to check if SSL certificates exist
check_certificates() {
    if [ ! -f /home/ubuntu/certs/selfsigned.key ] || [ ! -f /home/ubuntu/certs/selfsigned.crt ]; then
        echo " ! SSL certificates not found. Exiting." | sudo tee -a "$LOGFILE"
        exit 1
    else
        echo " + SSL certificates found." | sudo tee -a "$LOGFILE"
    fi
}

# Function to copy the updated files back into the container
copy_back_to_container() {
    echo " * Copying updated nginx.conf and certificates back to the container..." | sudo tee -a "$LOGFILE"
    sudo docker cp /home/ubuntu/nginx.conf web_app-gateway-1:/etc/nginx/nginx.conf
    sudo docker cp /home/ubuntu/certs/selfsigned.key web_app-gateway-1:/etc/nginx/certs/selfsigned.key
    sudo docker cp /home/ubuntu/certs/selfsigned.crt web_app-gateway-1:/etc/nginx/certs/selfsigned.crt

    if [ $? -ne 0 ]; then
        echo " ! Failed to copy updated files back to the container." | sudo tee -a "$LOGFILE"
        exit 1
    else
        echo " + Successfully updated nginx.conf and certificates in the container." | sudo tee -a "$LOGFILE"
    fi
}

# Function to restart the container
restart_gateway_container() {
    echo " * Restarting the 'gateway' container..." | sudo tee -a "$LOGFILE"
    sudo docker-compose -f /home/ubuntu/docker-compose.yml -f /home/ubuntu/docker-compose.override.yml restart gateway
    if [ $? -ne 0 ]; then
        echo " ! Failed to restart the 'gateway' container." | sudo tee -a "$LOGFILE"
        exit 1
    else
        echo " + Successfully restarted the 'gateway' container." | sudo tee -a "$LOGFILE"
    fi
}

# Function to run tests on the container
run_tests() {
    echo "Running tests on gateway container:" | sudo tee -a "$LOGFILE"

    # Nginx syntax test on the container
    echo "Testing Nginx configuration syntax..."
    if ! sudo docker exec web_app-gateway-1 nginx -t 2>&1 | tee /dev/stderr | grep -q "syntax is ok"; then
        echo "Error: Nginx configuration test failed inside the container."
        sudo docker logs web_app-gateway-1 || echo "No container logs available."
        exit 1
    else
        echo "Nginx configuration syntax test passed."
    fi
}

# Step 1: Extracts nginx.conf from the container
extract_nginx_conf

# Step 2: Runs the update function
update_nginx_conf

# Step 3: Checks availability of certificates
check_certificates

# Step 4: Copies the updated nginx.conf and certificates back to the container
copy_back_to_container

# Step 5: Restarts the 'gateway' container to apply changes
restart_gateway_container

# Step 6: Runs syntax test on the nginx.conf in updated container
run_tests