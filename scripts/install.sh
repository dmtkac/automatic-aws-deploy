#!/bin/bash

# Defines log file
LOGFILE="/home/ubuntu/install_script.log"
ERRORFLAG=false

# Function to log the output of commands and set error flag if a command fails
log_command() {
    "$@" >> "$LOGFILE" 2>&1
    if [ $? -ne 0 ]; then
        ERRORFLAG=true
    fi
}

echo "Starting installation script..." | tee -a "$LOGFILE"

# Preconfigures iptables-persistent to accept defaults
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections

# Reads IP whitelist 
ALLOWED_IPS=$(cat /home/ubuntu/allowed_aws_regional_ips.txt)

# Set DEBIAN_FRONTEND to noninteractive to avoid prompts during package installations
export DEBIAN_FRONTEND=noninteractive

# Sets up passwordless sudo for ubuntu user
echo ""
echo " * Setting up passwordless sudo for 'ubuntu' user..." | tee -a "$LOGFILE"
echo "ubuntu ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ubuntu

# Updates and installs necessary packages
echo ""
echo " * Updating and installing necessary packages..." | tee -a "$LOGFILE"
log_command sudo apt-get update -y
log_command sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common fail2ban python3 openssh-server iptables-persistent unzip ec2-instance-connect openssl

# Installs AWS CLI
echo ""
echo " * Installing AWS CLI..." | tee -a "$LOGFILE"
log_command curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
log_command unzip -q awscliv2.zip > /dev/null 2>&1
log_command sudo ./aws/install

# Verifies AWS CLI installation
echo ""
echo " * Verifying AWS CLI installation..." | tee -a "$LOGFILE"
if ! command -v aws &> /dev/null; then
    log_command echo "! AWS CLI installation failed."
    echo " ! AWS CLI installation failed." | tee -a "$LOGFILE"
    exit 1
fi
log_command echo " + AWS CLI installed successfully."

# Configures and enables UFW
echo ""
echo " * Configuring and enabling UFW..." | tee -a "$LOGFILE"
log_command sudo ufw default deny incoming
log_command sudo ufw default allow outgoing

for ip in $ALLOWED_IPS; do
    log_command sudo ufw allow from $ip to any port 22 proto tcp
done

log_command sudo ufw allow 80/tcp
log_command sudo ufw allow 443/tcp
log_command sudo ufw allow 3000/tcp
log_command bash -c 'echo "y" | sudo ufw enable'
log_command sudo ufw logging on

# Saves the current iptables rules to be loaded on reboot
echo ""
echo " * Saving iptables rules to be loaded on reboot..." | tee -a "$LOGFILE"
log_command sudo systemctl enable netfilter-persistent
log_command sudo netfilter-persistent save

# Sets up the repository
log_command sudo apt-get update
log_command sudo apt-get install -y ca-certificates curl

# Adds Docker's official GPG key in .asc format
log_command sudo install -m 0755 -d /etc/apt/keyrings
log_command curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc > /dev/null
log_command sudo chmod a+r /etc/apt/keyrings/docker.asc

log_command sudo tee /etc/apt/sources.list.d/docker.list > /dev/null <<EOF
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable
EOF

# Updates package list after adding the repository
log_command sudo apt-get update -y

# Installs Docker Engine, CLI, and containerd
log_command sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Starts and enables Docker
echo ""
echo " * Starting and enabling Docker..." | tee -a "$LOGFILE"
log_command sudo systemctl enable docker
log_command sudo systemctl start docker

# Verifies Docker installation by running hello-world container
log_command sudo docker run hello-world
if [ $? -ne 0 ]; then
    echo "Docker hello-world test failed" | tee -a "$LOGFILE"
    exit 1
fi

# Adds 'ubuntu' user to the Docker group
echo ""
echo " * Adding 'ubuntu' user to the Docker group..." | tee -a "$LOGFILE"
log_command sudo usermod -aG docker ubuntu

# Re-evaluates group membership to avoid requiring re-login
newgrp docker

# Installs Docker Compose
echo ""
echo " * Installing Docker Compose..." | tee -a "$LOGFILE"
log_command sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
log_command sudo chmod +x /usr/local/bin/docker-compose

# Fetches AWS region using EC2 metadata
AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

# Fetches AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)

# Fetches the ECR repository name that matches the prefix 'web-app'
repoArn=$(aws ecr describe-repositories --region $AWS_REGION --query "repositories[*].repositoryArn" --output text)

if [ -z "$repoArn" ]; then
    echo " ! No ECR repository found. Skipping ECR-related steps..." | tee -a "$LOGFILE"
    SKIP_ECR=true
else
    echo " + ECR repository '$repoArn' found." | tee -a "$LOGFILE"

    # Extracts the repository name from the ARN using awk (assuming multiple ARNs are space-separated)
    repoName=$(echo "$repoArn" | awk -F'/' '{print $NF}')

    # Handles cases where multiple ARNs may be returned by selecting the first repo name
    repoName=$(echo "$repoName" | awk '{print $1}')

    # Exports REPO_NAME as an environment variable
    export REPO_NAME=$repoName
    SKIP_ECR=false
fi

# Creates .env file with necessary variables
echo " * Creating the .env file with necessary variables..." | tee -a "$LOGFILE"
echo "AWS_REGION=$AWS_REGION" > /home/ubuntu/.env

if [ "$SKIP_ECR" = false ]; then
    echo "REPO_NAME=$REPO_NAME" >> /home/ubuntu/.env
    echo "AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID" >> /home/ubuntu/.env
fi

# Fetches the dynamically generated S3 bucket name from AWS using tags or the specific Terraform output
S3_BUCKET_NAME=$(aws s3api list-buckets --query "Buckets[?contains(Name, 'web-app-bucket')].Name" --output text)

if [ -z "$S3_BUCKET_NAME" ]; then
    echo " ! Error: No S3 bucket found. Ensure the bucket exists and is named correctly." | tee -a "$LOGFILE"
    exit 1
else
    echo " + S3 bucket '$S3_BUCKET_NAME' found." | tee -a "$LOGFILE"
    export S3_BUCKET_NAME
    echo "S3_BUCKET_NAME=$S3_BUCKET_NAME" >> /home/ubuntu/.env
fi

# Proceeds with ECR-related steps only if SKIP_ECR is not set to true
if [ "$SKIP_ECR" = false ]; then
    
    # Fetches AWS account ID
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)

    # Docker login using the transferred credentials
    echo ""
    echo " * Logging into AWS ECR..." | tee -a "$LOGFILE"
    aws ecr get-login-password --region $AWS_REGION | sudo docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

    if [ $? -ne 0 ]; then
        echo " ! Docker login to AWS ECR failed." | tee -a "$LOGFILE"
        exit 1
    else
        echo " + Docker login to AWS ECR succeeded." | tee -a "$LOGFILE"
    fi

    # Creates Docker Compose override file
    echo ""
    echo " * Creating Docker Compose override file..." | tee -a "$LOGFILE"
    cat <<EOL > /home/ubuntu/docker-compose.override.yml
services:
  postgres:
    image: '${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}:postgres'

  frontend:
    image: '${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}:frontend'

  gateway:
    image: '${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}:gateway'
EOL

    # Sets up pipeline docker-compose cron jobs for checking new images available in AWS ECR
    echo ""
    echo " * Setting up docker-compose cron jobs for all containers..." | tee -a "$LOGFILE"

    (crontab -l 2>/dev/null; echo "
        # Cron job for postgres container
        0 * * * * sudo docker-compose -f /home/ubuntu/docker-compose.yml -f /home/ubuntu/docker-compose.override.yml pull postgres && [ \"\$(docker images -q ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}:postgres)\" != \"\$(docker inspect --format='{{.Image}}' web_app-postgres-1)\" ] && sudo docker-compose -f /home/ubuntu/docker-compose.yml stop postgres && sudo docker-compose -f /home/ubuntu/docker-compose.yml -f /home/ubuntu/docker-compose.override.yml up --build -d postgres | sudo tee -a /var/log/pipeline-docker-compose-postgres.log 2>&1
        # Cron job for frontend container
        5 * * * * sudo docker-compose -f /home/ubuntu/docker-compose.yml -f /home/ubuntu/docker-compose.override.yml pull frontend && [ \"\$(docker images -q ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}:frontend)\" != \"\$(docker inspect --format='{{.Image}}' web_app-frontend-1)\" ] && sudo docker-compose -f /home/ubuntu/docker-compose.yml stop frontend && sudo docker-compose -f /home/ubuntu/docker-compose.yml -f /home/ubuntu/docker-compose.override.yml up --build -d frontend | sudo tee -a /var/log/pipeline-docker-compose-frontend.log 2>&1
        # Cron job for gateway container
        15 * * * * sudo docker-compose -f /home/ubuntu/docker-compose.yml -f /home/ubuntu/docker-compose.override.yml pull gateway && [ \"\$(docker images -q ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}:gateway)\" != \"\$(docker inspect --format='{{.Image}}' web_app-gateway-1)\" ] && sudo docker-compose -f /home/ubuntu/docker-compose.yml stop gateway && sudo docker-compose -f /home/ubuntu/docker-compose.yml -f /home/ubuntu/docker-compose.override.yml up --build -d gateway && sudo bash /home/ubuntu/update_nginx_conf_after_ecr_pull.sh | sudo tee -a /var/log/pipeline-docker-compose-gateway.log 2>&1
    ") | crontab -

    if [ $? -ne 0 ]; then
        echo " ! Pipeline cron job setup failed." | tee -a "$LOGFILE"
        exit 1
    else
        echo " + Pipeline cron job setup succeeded." | tee -a "$LOGFILE"
    fi
fi

# Runs the nginx configuration update script
echo ""
echo " * Running nginx configuration update script..." | tee -a "$LOGFILE"
echo "   See '~/nginx_update.log' for details" | tee -a "$LOGFILE"
log_command sudo bash /home/ubuntu/update_nginx_conf.sh

# Builds and starts Docker containers using Docker Compose
echo ""
echo " * Building and starting Docker containers using Docker Compose..." | tee -a "$LOGFILE"
cd /home/ubuntu

# Builds and runs containers using the included Dockerfiles
log_command sudo docker-compose -f /home/ubuntu/docker-compose.yml up --build -d
if [ $? -ne 0 ]; then
    echo " ! Docker Compose failed to build from local Dockerfiles." | tee -a "$LOGFILE"
    ERRORFLAG=true
fi

# Ensures Docker containers restart after reboot
echo ""
echo " * Ensuring Docker containers restart after reboot..." | tee -a "$LOGFILE"
log_command sudo docker update --restart=always web_app-postgres-1
log_command sudo docker update --restart=always web_app-gateway-1
log_command sudo docker update --restart=always web_app-frontend-1

# Creates and sets permissions for the ModSecurity audit log file inside Docker
echo ""
echo " * Creating and setting permissions for the ModSecurity audit log file inside Docker..." | tee -a "$LOGFILE"
log_command sudo docker exec web_app-gateway-1 /bin/sh -c "touch /var/log/modsec_audit.log && chown nginx:nginx /var/log/modsec_audit.log && chmod 660 /var/log/modsec_audit.log"

# Creates the scripts directory
echo ""
echo " * Creating the scripts directory..." | tee -a "$LOGFILE"
log_command sudo mkdir -p /home/ubuntu/scripts

# Moves the log rotation and parsing scripts
echo ""
echo " * Moving the log rotation and parsing scripts..." | tee -a "$LOGFILE"
log_command sudo mv /home/ubuntu/every_min_dump.sh /home/ubuntu/scripts/every_min_dump.sh
log_command sudo mv /home/ubuntu/every_minute_modsec_dump.sh /home/ubuntu/scripts/every_minute_modsec_dump.sh
log_command sudo mv /home/ubuntu/every_minute_modsec_dump_parsed.py /home/ubuntu/scripts/every_minute_modsec_dump_parsed.py

# Makes scripts executable
echo ""
echo " * Making scripts executable..." | tee -a "$LOGFILE"
log_command sudo chmod +x /home/ubuntu/scripts/every_min_dump.sh
log_command sudo chmod +x /home/ubuntu/scripts/every_minute_modsec_dump.sh
log_command sudo chmod +x /home/ubuntu/scripts/every_minute_modsec_dump_parsed.py

# Places Fail2ban configuration files
echo ""
echo " * Placing Fail2ban configuration files..." | tee -a "$LOGFILE"
# Extracts the last line from the file and remove the /32 suffix
YOUR_IP=$(tail -n 1 /home/ubuntu/allowed_aws_regional_ips.txt | sed 's/\/32//')
log_command sed -i "s/{{YOUR_IP}}/$YOUR_IP/" /home/ubuntu/jail.local
log_command sudo mv /home/ubuntu/jail.local /etc/fail2ban/jail.local

# Creates dummy log files to start up Fail2ban service
echo ""
echo " * Creating dummy log file for Fail2ban service..." | tee -a "$LOGFILE"
log_command touch /home/ubuntu/modsec_audit_parsed.log
log_command sudo chown root:root /home/ubuntu/modsec_audit_parsed.log
log_command sudo chmod 660 /home/ubuntu/modsec_audit_parsed.log
log_command touch /home/ubuntu/web_app-gateway-1_logs.log
log_command sudo chown root:root /home/ubuntu/web_app-gateway-1_logs.log
log_command sudo chmod 660 /home/ubuntu/web_app-gateway-1_logs.log

# Creates 'modsecurity' filter for jail.local
echo ""
echo " * Creating 'modsecurity' filter for jail.local..." | tee -a "$LOGFILE"
log_command sudo tee /etc/fail2ban/filter.d/modsecurity.conf > /dev/null <<EOF
[Definition]
failregex = ^<HOST> - -
EOF

log_command sudo chown root:root /etc/fail2ban/filter.d/modsecurity.conf
log_command sudo chmod 600 /etc/fail2ban/filter.d/modsecurity.conf

# Starts and enables Fail2ban
echo ""
echo " * Starting and enabling Fail2ban..." | tee -a "$LOGFILE"
log_command sudo systemctl enable fail2ban
log_command sudo systemctl start fail2ban

# Ensures cron service starts and persists after reboot
echo ""
echo " * Ensuring cron service starts and persists after reboot..." | tee -a "$LOGFILE"
log_command sudo systemctl enable cron

# Sets up cron jobs
echo ""
echo " * Setting up cron jobs..." | tee -a "$LOGFILE"
(crontab -l ; echo "*/1 * * * * /home/ubuntu/scripts/every_min_dump.sh > /dev/null 2>> /home/ubuntu/scripts/log_dump_errors.log") | crontab -
(crontab -l ; echo "*/1 * * * * /home/ubuntu/scripts/every_minute_modsec_dump.sh > /dev/null 2>> /home/ubuntu/scripts/modsec_log_dump_errors.log") | crontab -
(crontab -l ; echo "*/1 * * * * /usr/bin/python3 /home/ubuntu/scripts/every_minute_modsec_dump_parsed.py > /dev/null 2>> /home/ubuntu/scripts/modsec_log_dump_parsed_errors.log") | crontab -

# Enables and ensures that SSH server persists after reboot
echo ""
echo " * Enabling and ensuring SSH server persists after reboot..." | tee -a "$LOGFILE"
log_command sudo systemctl enable ssh

# Checks SSH service status and generate host keys if necessary
echo ""
echo " * Checking SSH service status and generating host keys if necessary..." | tee -a "$LOGFILE"
log_command sudo service ssh status || log_command sudo service ssh start

# Generates RSA key if it doesn't exist
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    log_command sudo ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
fi

# Generates ECDSA key if it doesn't exist
if [ ! -f /etc/ssh/ssh_host_ecdsa_key ]; then
    log_command sudo ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N ''
fi

# Generates ED25519 key if it doesn't exist
if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
    log_command sudo ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ''
fi

# Ensures SSH config is set correctly
echo ""
echo " * Ensuring SSH config is set correctly..." | tee -a "$LOGFILE"
log_command sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
log_command sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Completely disables root login
echo ""
echo " * Completely disabling root login..." | tee -a "$LOGFILE"
log_command sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config

# Restarts services to apply configurations
echo ""
echo " * Restarting services to apply configurations..." | tee -a "$LOGFILE"
log_command sudo systemctl restart fail2ban
log_command sudo systemctl restart docker
log_command sudo systemctl restart ssh
log_command sudo systemctl restart cron

# Checks for errors and log final message
if [ "$ERRORFLAG" = true ]; then
    echo " ! There were errors during the installation. Please check the log file at $LOGFILE for details." | tee -a "$LOGFILE"
else
    echo " + All configurations are successfully installed and applied on EC2 instance." | tee -a "$LOGFILE"
fi

echo ""
echo " * Installation script completed." | tee -a "$LOGFILE"

# Final checks on service statuses

# Checks UFW status
echo ""
echo ""
echo " * Checking UFW status..." | tee -a "$LOGFILE"
log_command sudo ufw status | tee -a "$LOGFILE"

# Checks netfilter-persistent service status
echo ""
echo " * Checking netfilter-persistent service status..." | tee -a "$LOGFILE"
log_command sudo systemctl status netfilter-persistent | tee -a "$LOGFILE"

# Checks Docker service status
echo ""
echo " * Checking Docker service status..." | tee -a "$LOGFILE"
log_command sudo systemctl status docker | tee -a "$LOGFILE"

# Checks Fail2Ban service status
echo ""
echo " * Checking Fail2Ban service status..." | tee -a "$LOGFILE"
log_command sudo systemctl status fail2ban | tee -a "$LOGFILE"

# Checks Fail2Ban client status
echo ""
echo " * Checking Fail2Ban client status..." | tee -a "$LOGFILE"
log_command sudo fail2ban-client status | tee -a "$LOGFILE"

# Checks cron service status
echo ""
echo " * Checking cron service status..." | tee -a "$LOGFILE"
log_command sudo systemctl status cron | tee -a "$LOGFILE"

# Lists root's cron jobs
echo ""
echo " * Listing root's cron jobs..." | tee -a "$LOGFILE"
log_command sudo crontab -u root -l | tee -a "$LOGFILE"

# Cleans up Docker resources
echo ""
echo " * Cleaning up unused Docker resources..." | tee -a "$LOGFILE"
sudo docker volume prune --force > /dev/null 2>> "$LOGFILE"
sudo docker system prune --all --volumes --force > /dev/null 2>> "$LOGFILE"

# Shows disk space usage
echo ""
echo " * Showing remaining free space on server..." | tee -a "$LOGFILE"
log_command df -h

# Sets restrictive permissions on sensitive files before cleanup (in case cleaning up fails)
log_command sudo chmod 600 /home/ubuntu/allowed_aws_regional_ips.txt

# Cleans up sensitive information
log_command rm -f /home/ubuntu/allowed_aws_regional_ips.txt

echo ""
echo "End of transcript." | tee -a "$LOGFILE"