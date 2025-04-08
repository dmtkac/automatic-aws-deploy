#!/bin/bash

# Welcoming introduction
echo ""
echo "  Welcome to the automated web application deploying script utilizing AWS infrastructure!"
echo "  Make sure to run it in a Bash environment with appropriate permissions."
echo ""
sleep 5
echo ""
echo "  The complete description of what this script does is in 'Readme.md' file."
echo "  IMPORTANT! I strongly recommend creating a separate AWS account for trying this out."
echo "  If you use it in your working/production AWS account, you are solely responsible for any caused damage."
echo ""
sleep 7
echo ""
echo "  The provisioned AWS architecture will be the following:"
echo ""
echo "  2 EC2 (GNU/Linux Ubuntu-based) instances with Docker set up on each:"
echo ""
echo "   Web app stack:"
echo "   > Reverse proxy Nginx server"
echo "   > Node.js web application"
echo "   > PostgreSQL database"
echo ""
echo "   Monitoring stack:"
echo "   > Telegraf/Prometheus/Grafana pipeline for monitoring server's metrics"
echo "   > Process_exporter/Prometheus/Grafana pipeline for monitoring server's processes"
echo "   > Postgres_exporter/Prometheus/Grafana pipeline for monitoring PostgreSQL database"
echo "   > Prom-client/Prometheus/Grafana pipeline for monitoring Node.js metrics"
echo "   > Custom 'Log_pusher'/Loki/Grafana pipeline for monitoring server's logs"
echo ""
echo "  1 S3 bucket for storing graphical files needed for the web app"
echo "  1 Elastic Load Balancer"
echo "-------"
echo "  1 Elastic Container Registry (if enabled)"
echo "  1 Route 53 Service (if domain name is provided)"
echo "  1 Amazon Certificate Manager (if domain name is provided)"
echo ""
sleep 10
echo ""
echo "  Please ensure you have the following prerequisites:"
echo ""
echo "1) AWS account with programmatic access granted to an IAM User and the following policies attached:"
echo "   - AmazonEC2FullAccess"
echo "   - AmazonS3FullAccess"
echo "   - EC2InstanceConnect"
echo "   - AmazonEC2ContainerRegistryFullAccess"
echo "   - IAMFullAccess"
echo ""
echo "2) GitHub Action Secrets containing manually added AWS account credentials:"
echo "   - AWS_ACCOUNT_ID"
echo "   - AWS_ACCESS_KEY_ID"
echo "   - AWS_SECRET_ACCESS_KEY"
echo "   - AWS_REGION"
echo "   - REPO_NAME"
echo ""
echo "Note: if you are using plain terminal then you must export all those variables manually before running the script:"
echo "   export AWS_ACCOUNT_ID=\"your AWS account ID\""
echo "   export AWS_ACCESS_KEY_ID=\"your AWS access key ID\""
echo "   export AWS_SECRET_ACCESS_KEY=\"your AWS secret access key\""
echo "   etc."
echo ""
echo "3) Optionally: if you own a domain name that you'd like to use for access to web app, the following"
echo "   policies must be additionally attached to IAM User:"
echo "   - AmazonRoute53FullAccess"
echo "   - AWSCertificateManagerFullAccess"
echo ""

sleep 10

echo ""
echo "* Checking if all necessary software is installed on this machine (e.g., AWS CLI, Packer, Terraform, Git, etc.)..."

# Checks for required tools and prompt to install if missing
required_tools=("aws" "terraform" "packer" "ssh" "git" "jq")
missing_tools=()

for tool in "${required_tools[@]}"; do
    if ! command -v $tool &> /dev/null; then
        missing_tools+=($tool)
    fi
done

if [ ${#missing_tools[@]} -gt 0 ]; then
    echo ""
    echo "  WARNING: The following tools are required but are not installed: ${missing_tools[@]}"
    echo "  Please install them and run the script again."
    echo ""
    echo "  Installation instructions can be found at the following links:"
    echo ""
    echo "  AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    echo "  Packer: https://developer.hashicorp.com/packer/install"
    echo "  Terraform: https://developer.hashicorp.com/terraform/install"
    echo "  Git: sudo apt install git (for Debian-based Linux distros) or 'brew install git' (for macOS)"
    echo "  OpenSSH server: 'sudo apt install openssh-server' (for Debian-based Linux distros) or 'brew install openssh' (for macOS)"
    echo "  jq: sudo apt install jq (for Debian-based Linux distros) or 'brew install jq' (for macOS)"
    exit 1
else
    echo "  + All required tools are installed."
    echo ""
fi

# Makes sure script currently is on main branch
echo "* Checking if 'main' is the current branch..."
git checkout main > /dev/null 2>&1
echo ""

# Creates and switch to a configured branch
BRANCH_NAME="main-configured"
if git show-ref --verify --quiet refs/heads/$BRANCH_NAME; then
    git branch -D $BRANCH_NAME > /dev/null 2>&1
fi

echo "* Creating and switching to '$BRANCH_NAME' branch..."
git checkout -b "$BRANCH_NAME" > /dev/null 2>&1
echo ""

echo "* Checking AWS CLI configuration..."

# Captures the AWS region from the configuration
AWS_REGION=$(aws configure get region)
if [ -z "$AWS_REGION" ]; then
    echo " ! AWS CLI is not configured with a region. Please set it with 'aws configure' and run this script again."
    echo ""
    exit 1
fi

# Checks if AWS CLI is configured correctly and prompt to configure if not
if ! aws configure list | grep -q 'access_key'; then
    echo " ! AWS CLI is not configured. Please run 'aws configure' to set up your credentials."
    aws configure
    if ! aws configure list | grep -q 'access_key'; then
        echo " ! AWS CLI is still not configured correctly. Please ensure you have set up your credentials and try again."
        exit 1
    fi
fi

# Extracts AWS credentials
AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)
AWS_REGION=$(aws configure get region)

# Ensures credentials are extracted correctly
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$AWS_REGION" ]; then
    echo " ! Unable to extract AWS credentials. Please ensure AWS CLI is configured correctly and try again."
    exit 1
else
    echo ""
    echo " + AWS CLI configured correctly."    
fi

sleep 2

# Exports these variables for use in the script
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_REGION

# Defines the key name and paths
KEY_NAME="my-local-key-pair"
KEY_PATH="./key/$KEY_NAME.pem"
PUB_KEY_PATH="./key/$KEY_NAME.pub"
OPENSSH_PUB_KEY_PATH="./key/$KEY_NAME-openssh.pub"

# Ensures the directory exists
if [ ! -d "./key" ]; then
    mkdir -p "./key"
fi

# Checks if the key pair already exists and delete
echo ""
echo "* Deleting existing key files locally..."
if [ -f "$KEY_PATH" ] || [ -f "$PUB_KEY_PATH" ] || [ -f "$OPENSSH_PUB_KEY_PATH" ]; then
    chmod 777 "$KEY_PATH" "$PUB_KEY_PATH" "$OPENSSH_PUB_KEY_PATH"
    rm -f "$KEY_PATH" "$PUB_KEY_PATH" "$OPENSSH_PUB_KEY_PATH"
    if [ $? -ne 0 ]; then
        echo " ! Error: Unable to delete existing key files locally. Please check permissions and try again."
        exit 1
    else
        echo "  Existing key files deleted locally."
    fi
else
    echo " + No existing key files found locally."
fi

# Fetches and delete the key pair in AWS
echo ""
echo "* Fetching existing key pairs from AWS..."
EXISTING_KEY_PAIR=$(aws ec2 describe-key-pairs --query "KeyPairs[?KeyName=='$KEY_NAME'].KeyName" --output text)

if [ "$EXISTING_KEY_PAIR" ]; then
    echo ""
    echo "* Deleting existing key pair '$EXISTING_KEY_PAIR' in AWS..."
    aws ec2 delete-key-pair --key-name "$EXISTING_KEY_PAIR"

    if [ $? -eq 0 ]; then
        echo "* Key pair '$EXISTING_KEY_PAIR' deleted successfully in AWS."
    else
        echo " ! Error: Failed to delete key pair in AWS."
        exit 1
    fi
else
    echo "* No existing key pair named '$KEY_NAME' found in AWS. Proceeding..."
fi

# Generates RSA key pair using OpenSSL
echo ""
echo "* Generating a new SSH key pair..."
openssl genpkey -algorithm RSA -out "$KEY_PATH" -outform PEM > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo ""
    echo " ! Error: Failed to generate SSH key pair."
    exit 1
fi

# Sets correct permissions on the private key file before proceeding
chmod 400 "$KEY_PATH"

# Generates the public key in PEM format
openssl rsa -in "$KEY_PATH" -pubout -out "$PUB_KEY_PATH" > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo ""
    echo " ! Error: Failed to generate public key."
    exit 1
fi

# Converts the public key to OpenSSH format
ssh-keygen -y -f "$KEY_PATH" > "$OPENSSH_PUB_KEY_PATH"

if [ $? -ne 0 ]; then
    echo " ! Error: Failed to generate public key in OpenSSH format."
    exit 1
fi

# Validates the private key (suppress actual output)
echo ""
echo "* Validating the private key using OpenSSL..."
openssl rsa -in "$KEY_PATH" -check > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "  RSA key ok"

    # Reads and prepare the public key for import
    PUBLIC_KEY_MATERIAL=$(cat "$PUB_KEY_PATH" | sed '1d;$d' | tr -d '\n')

    # Ensures the public key is in valid base64 format
    PUBLIC_KEY_MATERIAL_BASE64=$(echo -n "$PUBLIC_KEY_MATERIAL" | base64)

    # Imports the public key to AWS EC2
    echo ""
    echo "* Importing the public key to AWS..."
    aws ec2 import-key-pair --key-name "$KEY_NAME" --public-key-material "$PUBLIC_KEY_MATERIAL_BASE64" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo "  Key pair generation and import completed successfully."
    else
        echo ""
        echo " ! Error: Failed to import the public key to AWS."
        exit 1
    fi
else
    echo ""
    echo " ! Error: RSA key validation failed."
    exit 1
fi

# Sets correct permissions on the private key file
chmod 400 "$KEY_PATH"

echo ""
echo "* Please answer the following questions necessary to start the deployment process:"

sleep 2
echo ""

# Asks the user whether to enable the CI/CD pipeline
read -p "  Do you want to enable 'GitHub Actions -> AWS ECR -> AWS EC2' pipeline for updating Docker containers? (y/n): " enableCICD

if [ "$enableCICD" == "y" ]; then
    echo ""

    # Prompts for ECR repository name
    read -p "  Enter AWS ECR repository name ('REPO_NAME' that was previously added to GitHub Secrets  or to your terminal as env. var.): " REPO_NAME

    # Stores it in an environmental variable
    export REPO_NAME=$REPO_NAME

    # Checks if the ECR repository already exists
    repoExists=$(aws ecr describe-repositories --repository-names "$REPO_NAME" --region "$AWS_REGION" 2>&1)

    if echo "$repoExists" | grep -q "RepositoryNotFoundException"; then
        echo ""
        echo "* ECR repository '$REPO_NAME' does not exist. Creating it now..."

        # Creates ECR repository
        aws ecr create-repository --repository-name "$REPO_NAME" --region "$AWS_REGION" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "  + ECR repository '$REPO_NAME' created."
        else
            echo "  ! Failed to create the ECR repository."
            exit 1
        fi
    elif echo "$repoExists" | grep -q '"repositoryName": "'$REPO_NAME'"'; then
        echo "  + ECR repository '$REPO_NAME' already exists. Proceeding with the setup..."
    else
        echo "  ! Failed to check or create the ECR repository. Please check your AWS credentials and try again."
        exit 1
    fi

    # Verifies that the ECR repository is accessible
    repoCheck=$(aws ecr describe-repositories --repository-names "$REPO_NAME" --region "$AWS_REGION" --output json)

    if [ "$repoCheck" ]; then
        echo "  + ECR repository '$REPO_NAME' is accessible."
    else
        echo "  ! ECR repository '$REPO_NAME' could not be found. Please check AWS ECR for issues."
        exit 1
    fi

else
    echo "  ! CI/CD pipeline setup was skipped. Proceeding..."
fi

sleep 2
echo ""

# Checks if the user has a domain name or uses the EC2 instance's public IP
read -p "  Do you have a registered domain name for the web app to be accessible online? (y/n): " hasDomain

if [ "$hasDomain" == "y" ]; then
    echo ""
    read -p "  Enter your domain name: " domainName
    echo ""

    # Prompts the user to enter the path to the certificate, private key, and optional chain files
    read -p "  Enter the full path to your certificate (.crt) file: " certFilePath
    echo ""
    read -p "  Enter the full path to your private key (.key) file: " privateKeyFilePath
    echo ""
    read -p "  Enter the full path to your certificate chain file (.pem), or press Enter if not applicable: " chainFilePath

    # Fetches existing certificates for the domain
    existingCerts=$(aws acm list-certificates --query "CertificateSummaryList[?DomainName=='$domainName'].CertificateArn" --output text)

    # Deletes old certificates if they exist
    if [ "$existingCerts" ]; then
        for certArn in $existingCerts; do
            echo "* Deleting existing certificate in ACM..."
            aws acm delete-certificate --certificate-arn "$certArn" > /dev/null 2>&1
        done
    fi

    # Uploads the new certificate to ACM
    echo ""
    echo "* Uploading your SSL certificate and private key to ACM..."

    # Prepares the upload arguments
    uploadArgs="--certificate fileb://$certFilePath --private-key fileb://$privateKeyFilePath --region $AWS_REGION --query CertificateArn --output text"

    # Checks if the certificate chain file is provided
    if [ ! -z "$chainFilePath" ]; then
        # Adds the certificate chain argument only if the file path is not empty
        uploadArgs="$uploadArgs --certificate-chain fileb://$chainFilePath"
    fi

    # Executes the AWS CLI command to upload the certificate
    SSL_CERTIFICATE_ARN=$(aws acm import-certificate $uploadArgs)

    if [ "$SSL_CERTIFICATE_ARN" ]; then
        echo "  + New Certificate ARN was uploaded successfully."
    else
        echo "  ! Error: The certificate was not uploaded successfully. Please verify your certificate, private key, and chain files."
        exit 1
    fi

    echo ""
    echo "  Route 53 will automatically map your domain to the load balancer. Make sure your domain's DNS settings are managed by Route 53."
    echo "  Once setup is complete, you can access your web app via your custom domain."
    echo ""

else
    SSL_CERTIFICATE_ARN=""
    domainName="***"
    echo ""
    echo "  Access to your web app will be possible via the ELB DNS name or by mapping it manually to your domain's DNS settings."
    echo "  Since a self-signed certificate is in use, you may see security warnings in the browser, which can be safely ignored for testing purposes."
    echo ""
fi

echo "* You can test the provisioned AWS load balancer using the './utilities/test_aws_balancer.sh' script."

sleep 10
echo ""

# Prompts user about IP address
echo "* Your IP address needs to be added to SSH whitelists in AWS VPC and EC2 firewalls."

# Asks for confirmation
read -p "  Are you okay with fetching your public IP address? (y/n): " confirmation
if [ "$confirmation" != "y" ]; then
    echo "  ! Operation cancelled."
    exit 1
fi

# Fetches IP automatically
yourIp=$(curl -s https://api.ipify.org)
if [ -z "$yourIp" ]; then
    echo "  ! Primary IP service unavailable, attempting fallback..."
    yourIp=$(curl -s https://ipinfo.io/ip)
    if [ -z "$yourIp" ]; then
        echo "  ! Fallback IP service also unavailable. Please check your network connection."
        exit 1
    fi
fi

# File path for ip_ranges.tf
ipRangesFilePath="./terraform/ip_ranges.tf"

# Reads and updates the content of ip_ranges.tf
if [ -f "$ipRangesFilePath" ]; then
    sed -i "s/\*\*\*/$yourIp\/32/g" "$ipRangesFilePath"
    sed -i "s/###/$AWS_REGION/g" "$ipRangesFilePath"
else
    echo "  ! ip_ranges.tf not found."
    exit 1
fi

# Extracts IP ranges and writes them to a file
allowedIpsFile="./allowed_aws_regional_ips.txt"
grep 'ip_prefix\s*=\s*"\S*"' "$ipRangesFilePath" | awk -F'=' '{print $2}' | tr -d '"' > "$allowedIpsFile"

echo ""

# Step 1: Fetch the latest Ubuntu AMI ID
echo "* Fetching the latest Ubuntu AMI ID..."
UBUNTU_AMI_ID=$(aws ec2 describe-images --owners 099720109477 --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" --query "Images | sort_by(@, &CreationDate)[-1].ImageId" --output text)

# Ensure UBUNTU_AMI_ID is not empty
if [ -z "$UBUNTU_AMI_ID" ]; then
  echo " ! Error: Ubuntu AMI ID not found."
  exit 1
fi

echo ""

# Step 2: Updates Packer template with the new AMI ID
echo "* Updating Packer template with the new AMI ID..."
replacement_string="\"source_ami\": \"$UBUNTU_AMI_ID\""
sed -i "s/\"source_ami\": \"ami-.*\"/$replacement_string/" packer/packer-template.json

echo ""

# Step 3: Initializes Packer and download necessary plugins
echo "* Initializing Packer and downloading necessary plugins..."
packer plugins install github.com/hashicorp/amazon

echo ""

# Step 4: Validates the Packer template
echo "* Validating Packer template..."
packer validate packer/packer-template.json

echo ""

# Step 5: Builds the AMI with Packer and capture the output
echo "* Building the AMI with Packer. This may take 3-4 minutes..."
PACKER_OUTPUT=$(packer build packer/packer-template.json)

echo ""

# Prints the Packer output for details
echo "  Packer Output: $PACKER_OUTPUT"

# Extracts the most recent AMI ID from the Packer output
AMI_ID=$(echo "$PACKER_OUTPUT" | grep -oP 'ami-\w+' | tail -1)

# Ensures AMI_ID is not empty
if [ -z "$AMI_ID" ]; then
  echo " ! Error: AMI ID not found in Packer output."
  exit 1
fi

echo "* Using AMI ID: $AMI_ID for deployment"

echo ""

# Step 6: Initializes Terraform
echo "* Initializing Terraform..."
cd terraform
terraform init

echo ""

# Step 7: Plans the deployment
echo "* Planning the deployment..."
terraform plan -out=tfplan \
  -var "ami_id=$AMI_ID" \
  -var "aws_region=$AWS_REGION" \
  -var "domain_name=$DOMAIN_NAME" \
  -var "ssl_certificate_arn=$SSL_CERTIFICATE_ARN" \
  -var "aws_key_pair_name=$KEY_NAME" \
  -var "initial_private_key_path=$KEY_PATH"

echo ""

# Step 8: Waits for user confirmation before applying the plan
read -p "  Review the plan and press Enter to continue with 'terraform apply' or type 'n' to cancel and delete the AMI: " continueDeployment

if [ "$continueDeployment" == "n" ]; then
    # Deletes the AMI and its snapshots
    echo ""
    echo "* Deleting the AMI and associated snapshots..."

    # Gets the latest AMI ID
    AmiId=$(aws ec2 describe-images --owners self --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" --output text)

    if [ -n "$AmiId" ]; then
        # Deregisters the AMI ID
        aws ec2 deregister-image --image-id "$AmiId"
        echo "* Waiting for AMI to deregister..."
        sleep 5

        # Describes all snapshots to identify any that need deletion
        snapshotIds=$(aws ec2 describe-snapshots --owner-ids self --query "Snapshots[*].SnapshotId" --output text)
        if [ -n "$snapshotIds" ]; then
            for snapshotId in $snapshotIds; do
                aws ec2 delete-snapshot --snapshot-id "$snapshotId"
            done
            echo "  AMI and snapshots deleted."
        else
            echo "  No snapshots found or AMI already deleted."
        fi
    else
        echo "  No AMI found to delete."
    fi

    # Deletes the imported key pair
    echo ""
    echo "* Deleting the imported key pair..."
    if aws ec2 delete-key-pair --key-name "$KEY_NAME" > /dev/null 2>&1; then
        echo "+ Key pair '$KEY_NAME' deleted successfully."
    else
        echo " ! Error: Failed to delete the key pair '$KEY_NAME'. It may not exist or an error occurred."
    fi

    # Deletes the ECR repository
    if [ -n "$REPO_NAME" ]; then
        echo ""
        echo "* Deleting the ECR repository '$REPO_NAME'..."
        aws ecr delete-repository --repository-name "$REPO_NAME" --region "$AWS_REGION" --force > /dev/null 2>&1
        echo "+ ECR repository deleted."
    else
        echo " ! ECR repository name not found. Skipping ECR deletion."
    fi

    # Deletes any existing ACM certificates
    if [ -n "$domainName" ]; then
        echo ""
        echo "* Checking for ACM certificates to delete..."
        existingCerts=$(aws acm list-certificates --query "CertificateSummaryList[?DomainName=='$domainName'].CertificateArn" --output text)

        if [ -n "$existingCerts" ]; then
            for certArn in $existingCerts; do
                echo ""
                echo "* Deleting certificate: $certArn"
                if aws acm delete-certificate --certificate-arn "$certArn"; then
                    echo "+ Certificate deleted successfully."
                else
                    echo " ! Error deleting certificate: $certArn"
                fi
            done
        else
            echo " ! No certificates found for domain: $domainName"
        fi
    else
        echo " ! Domain name is not defined. Skipping certificate deletion..."
    fi

    exit
fi

echo ""

# Step 9: Applies the Terraform plan
echo "* Applying the Terraform plan. This may take a few minutes..."
terraform apply -auto-approve tfplan

echo ""

# Step 10: Retrieves the instance IDs and public IPs
echo "* Retrieving the instance IDs and public IPs..."

# Uses Terraform's JSON output and parse it correctly with jq
INSTANCE_IDS=$(terraform output -json instance_ids | jq -r '.[]')

# Extracting instances IDs
FIRST_INSTANCE_ID=$(echo "$INSTANCE_IDS" | awk 'NR==1')
SECOND_INSTANCE_ID=$(echo "$INSTANCE_IDS" | awk 'NR==2')

# Checks if instance IDs are properly set
if [ -z "$FIRST_INSTANCE_ID" ]; then
  echo " ! Error: First instance ID not found."
  exit 1
fi

if [ -z "$SECOND_INSTANCE_ID" ]; then
  echo " ! Error: Second instance ID not found."
  exit 1
fi

# Extracting instances public IPs
FIRST_INSTANCE_PUBLIC_IP=$(aws ec2 describe-instances --instance-ids "$FIRST_INSTANCE_ID" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
SECOND_INSTANCE_PUBLIC_IP=$(aws ec2 describe-instances --instance-ids "$SECOND_INSTANCE_ID" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)

# Ensures FIRST_INSTANCE_PUBLIC_IP is not empty
if [ -z "$FIRST_INSTANCE_PUBLIC_IP" ]; then
  echo " ! Error: Public IP not found for the first EC2 instance."
  exit 1
fi

# Ensures SECOND_INSTANCE_PUBLIC_IP is not empty
if [ -z "$SECOND_INSTANCE_PUBLIC_IP" ]; then
  echo " ! Error: Public IP not found for the second EC2 instance."
  exit 1
fi

# Converts the IP addresses to FQDN format (replace '.' with '-')
FIRST_INSTANCE_FQDN=$(echo "$FIRST_INSTANCE_PUBLIC_IP" | sed 's/\./-/g')
SECOND_INSTANCE_FQDN=$(echo "$SECOND_INSTANCE_PUBLIC_IP" | sed 's/\./-/g')

echo ""

# Path to the output file with connecting commands to EC2 instances
outputFile="../connecting_commands.txt"

echo "* Writing SSH commands to 'connecting_commands.txt' file in project's root directory..."

sleep 3

# Generate SSH commands
firstInstanceSSH="ssh -o StrictHostKeyChecking=no -i $KEY_PATH ubuntu@ec2-$FIRST_INSTANCE_FQDN.$AWS_REGION.compute.amazonaws.com"
secondInstanceSSH="ssh -o StrictHostKeyChecking=no -i $KEY_PATH ubuntu@ec2-$SECOND_INSTANCE_FQDN.$AWS_REGION.compute.amazonaws.com"

# Write SSH commands to the file
cat << EOF > "$outputFile"
# SSH commands to connect to your provisioned EC2 instances:
$firstInstanceSSH
$secondInstanceSSH
EOF

echo ""

# Step 11: Fetches the SSH host keys and add them to known_hosts
echo "* Fetching the SSH host keys and adding them to known_hosts on this machine..."

# Defines the hostnames for your instances
FIRST_INSTANCE_HOST="ec2-$FIRST_INSTANCE_FQDN.$AWS_REGION.compute.amazonaws.com"
SECOND_INSTANCE_HOST="ec2-$SECOND_INSTANCE_FQDN.$AWS_REGION.compute.amazonaws.com"

ssh-keyscan -H "$FIRST_INSTANCE_HOST" >> ~/.ssh/known_hosts
ssh-keyscan -H "$SECOND_INSTANCE_HOST" >> ~/.ssh/known_hosts

echo ""

# Step 12: Displays useful information
elbDnsName=$(terraform output -raw elb_dns_name)

if [ "$domainName" == "***" ]; then
    echo "  You can access your web application using the following ELB DNS name:"
    echo "  ELB DNS Name: $elbDnsName"
    echo "  The generated ELB DNS name '$elbDnsName' is also added to the file './connecting_commands.txt'."
else
    echo "  You can access your web application either by using your domain name:"
    echo "  Domain Name: $domainName"
    echo "  or by using the generated ELB DNS name:"
    echo "  ELB DNS Name: $elbDnsName"
    echo "  The generated ELB DNS name '$elbDnsName' is also added to the file './connecting_commands.txt'."
fi

# Appends the ELB DNS information to connecting_commands.txt
echo -e "To access the web app in the browser, use the following URL:\n$elbDnsName" >> "$outputFile"

# Updates 'test_aws_balancer.sh' script with the actual ELB DNS name
testScriptPath="../utilities/test_aws_balancer.sh"
sed -i "s/\*\*\*/$elbDnsName/g" "$testScriptPath"

echo ""

# Step 13: Uploads illustrations to S3 bucket
s3BucketName=$(terraform output -raw s3_bucket_name)

echo ""
echo "  For managing static assets, you can use the following S3 bucket:"
echo "  S3 Bucket Name: $s3BucketName"

# Defines path to the illustrations folder
illustrationsDir="./illustrations"

echo ""
echo "* Uploading illustrations to S3 bucket: $s3BucketName"
cd ..

if [ -d "$illustrationsDir" ]; then
    aws s3 cp "$illustrationsDir" "s3://$s3BucketName/" --recursive
    if [ $? -eq 0 ]; then
        echo "  + Illustrations uploaded successfully."
    else
        echo "  ! Failed to upload illustrations."
        exit 1
    fi
else
    echo "  ! The provided path does not exist or is not a directory. Please check the path and try again."
    exit 1
fi

sleep 2
echo ""

# Step 14: Pushes the modified files to the configured branch
echo "* Creating and pushing the main-configured branch to the remote repository: $BRANCH_NAME"

# Adds and commits the changes
git add .
git commit -m "* Deploying infrastructure with configured user inputs..."

# Pushes the configured branch to the repository and sets upstream
git push --set-upstream origin "$BRANCH_NAME"

sleep 2
echo ""

echo "+ Configured branch $BRANCH_NAME created and pushed to the remote repository."

sleep 2
echo ""
echo ""
echo "+ Your infrastructure has been successfully provisioned."

# Step 15: Saves terraform variables to a text file for 'destroy.sh' script
terraformVarsFilePath="./terraform/vars_for_destroy.txt"

# Truncates the file to clear it
> "$terraformVarsFilePath"

# Appends variables to the file
echo "ami_id=$AMI_ID" >> "$terraformVarsFilePath"
echo "aws_region=$AWS_REGION" >> "$terraformVarsFilePath"
echo "domain_name=$domainName" >> "$terraformVarsFilePath"
echo "ssl_certificate_arn=$SSL_CERTIFICATE_ARN" >> "$terraformVarsFilePath"
echo "aws_key_pair_name=$KEY_NAME" >> "$terraformVarsFilePath"
echo "initial_private_key_path=$KEY_PATH" >> "$terraformVarsFilePath"

# Step 16: Option to log into provisioned EC2 instance
read -p "  Do you want to further monitor the deployment process on provisioned EC2 instances now? (y/n): " useSSH

if [ "$useSSH" == "y" ]; then
    echo "  Once connected, run the command 'tail -f ~/install_script.log'. Which instance do you want to connect to?"
    echo ""
    echo "1) First instance (Public IP: $FIRST_INSTANCE_PUBLIC_IP)"
    echo "2) Second instance (Public IP: $SECOND_INSTANCE_PUBLIC_IP)"
    read -p "  Enter 1 or 2: " instanceChoice
    exitCode=0

    if [ "$instanceChoice" == "1" ]; then
        ssh -o StrictHostKeyChecking=no -i "$KEY_PATH" ubuntu@ec2-$FIRST_INSTANCE_FQDN.$AWS_REGION.compute.amazonaws.com
        exitCode=$?
    elif [ "$instanceChoice" == "2" ]; then
        ssh -o StrictHostKeyChecking=no -i "$KEY_PATH" ubuntu@ec2-$SECOND_INSTANCE_FQDN.$AWS_REGION.compute.amazonaws.com
        exitCode=$?
    else
        echo "  ! Invalid choice. Exiting."
        exitCode=1
    fi

    if [ "$exitCode" -ne 0 ]; then
        echo "  ! SSH connection failed."
        echo ""

        # Option to destroy provisioned infrastructure to avoid charges
        read -p "  Do you want to destroy the provisioned infrastructure and delete the AMI and snapshots now? (y/n): " destroyInfra
        if [ "$destroyInfra" == "y" ]; then
            echo ""
            echo "  Insert the following variables when asked:"
            echo "   AMI ID: $AMI_ID"
            echo "   Key Name: $KEY_NAME"
            echo "   AWS Region: $AWS_REGION"
            echo "   Key Path: $KEY_PATH"
            echo "   Domain Name: $domainName"
            echo "   SSL Certificate ARN: $SSL_CERTIFICATE_ARN"

            cd terraform
            terraform destroy -auto-approve \
                -var "ami_id=$AMI_ID" \
                -var "aws_region=$AWS_REGION" \
                -var "domain_name=$domainName" \
                -var "ssl_certificate_arn=$SSL_CERTIFICATE_ARN" \
                -var "aws_key_pair_name=$KEY_NAME" \
                -var "initial_private_key_path=$KEY_PATH"

            # Fetches existing certificates for the domain using the domain name from vars_for_destroy.txt
            if [ ! -z "$domainName" ]; then
                existingCerts=$(aws acm list-certificates --query "CertificateSummaryList[?DomainName=='$domainName'].CertificateArn" --output text)

                # Deletes old certificates if they exist
                if [ "$existingCerts" ]; then
                    for certArn in $existingCerts; do
                        echo ""
                        echo "* Deleting existing certificate: $certArn"
                        aws acm delete-certificate --certificate-arn $certArn
                        echo "+ Certificate deleted successfully."
                    done
                else
                    echo "  ! No certificates found for domain: $domainName"
                fi
            else
                echo "  ! Domain name is not defined. Skipping certificate deletion..."
            fi

            # Deletes the AMI and its snapshots
            echo ""
            echo "* Deleting the AMI and associated snapshots..."

            # Gets the AMI ID
            AmiId=$(aws ec2 describe-images --owners self --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" --output text)

            # Deregisters the AMI ID
            aws ec2 deregister-image --image-id "$AmiId"

            # Waits for the deregistration to complete
            echo ""
            echo "* Waiting for AMI to deregister..."
            sleep 5

            # Describes all snapshots to identify any that need deletion
            snapshotIds=$(aws ec2 describe-snapshots --owner-ids self --query "Snapshots[*].SnapshotId" --output text)
            if [ "$snapshotIds" ]; then
                for snapshotId in $snapshotIds; do
                    aws ec2 delete-snapshot --snapshot-id "$snapshotId"
                done
                echo "  + AMI and snapshots deleted."
            else
                echo "  ! No snapshots found or AMI already deleted."
            fi

            # Deletes the imported key pair
            echo ""
            echo "* Deleting the imported key pair..."
            aws ec2 delete-key-pair --key-name "$KEY_NAME"
            echo "  Key pair '$KEY_NAME' deleted successfully."

            # Deletes the ECR repository
            if [ ! -z "$REPO_NAME" ]; then
                echo ""
                echo "* Deleting the ECR repository '$REPO_NAME'..."
                aws ecr delete-repository --repository-name "$REPO_NAME" --region "$AWS_REGION" --force
                echo "+ ECR repository deleted."
            else
                echo "  ! ECR repository name not found. Skipping ECR deletion."
            fi

            echo ""
            echo "+ Infrastructure and AMI deleted +"
        else
            echo ""
            echo "  You can destroy the infrastructure later using './utilities/destroy.sh' script."
        fi
    fi
else
    echo ""
    echo "  You can connect to your EC2 instances later using the following commands:"
    echo "  SSH commands to connect to your provisioned EC2 instances have been saved to './connecting_commands.txt'."
    echo "  You can use these commands to connect to the instances at any time."
    echo ""

    # Option to destroy provisioned infrastructure to avoid charges
    read -p "  Do you want to destroy the provisioned infrastructure and delete the AMI and snapshots now? (y/n): " destroyInfra
    if [ "$destroyInfra" == "y" ]; then
        echo ""
        echo "  Insert the following variables when asked:"
        echo "   AMI ID: $AMI_ID"
        echo "   Key Name: $KEY_NAME"
        echo "   AWS Region: $AWS_REGION"
        echo "   Key Path: $KEY_PATH"
        echo "   Domain Name: $domainName"
        echo "   SSL Certificate ARN: $SSL_CERTIFICATE_ARN"

        cd terraform
        terraform destroy -auto-approve \
            -var "ami_id=$AMI_ID" \
            -var "aws_region=$AWS_REGION" \
            -var "domain_name=$domainName" \
            -var "ssl_certificate_arn=$SSL_CERTIFICATE_ARN" \
            -var "aws_key_pair_name=$KEY_NAME" \
            -var "initial_private_key_path=$KEY_PATH"

        # Deletes any existing ACM certificates
        if [ ! -z "$domainName" ]; then
            existingCerts=$(aws acm list-certificates --query "CertificateSummaryList[?DomainName=='$domainName'].CertificateArn" --output text)

            if [ "$existingCerts" ]; then
                for certArn in $existingCerts; do
                    echo ""
                    echo "* Deleting existing certificate: $certArn"
                    aws acm delete-certificate --certificate-arn $certArn
                    echo "+ Certificate deleted successfully."
                done
            else
                echo "  ! No certificates found for domain: $domainName"
            fi
        else
            echo "  ! Domain name is not defined. Skipping certificate deletion..."
        fi

        # Deletes the AMI and its snapshots
        echo ""
        echo "* Deleting the AMI and associated snapshots..."

        # Gets the AMI ID
        AmiId=$(aws ec2 describe-images --owners self --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" --output text)

        # Deregisters the AMI ID
        aws ec2 deregister-image --image-id "$AmiId"

        # Waits for the deregistration to complete
        echo ""
        echo "* Waiting for AMI to deregister..."
        sleep 5

        # Describes all snapshots to identify any that need deletion
        snapshotIds=$(aws ec2 describe-snapshots --owner-ids self --query "Snapshots[*].SnapshotId" --output text)
        if [ "$snapshotIds" ]; then
            for snapshotId in $snapshotIds; do
                aws ec2 delete-snapshot --snapshot-id "$snapshotId"
            done
            echo ""
            echo "  + AMI and snapshots deleted."
        else
            echo ""
            echo "  ! No snapshots found or AMI already deleted."
        fi

        # Deletes the imported key pair
        echo ""
        echo "* Deleting the imported key pair..."
        aws ec2 delete-key-pair --key-name "$KEY_NAME"
        echo "+ Key pair '$KEY_NAME' deleted successfully."

        # Deletes the ECR repository
        if [ ! -z "$REPO_NAME" ]; then
            echo ""
            echo "* Deleting the ECR repository '$REPO_NAME'..."
            aws ecr delete-repository --repository-name "$REPO_NAME" --region "$AWS_REGION" --force
            echo "  + ECR repository deleted."
        else
            echo "  ! ECR repository name not found. Skipping ECR deletion..."
        fi

        echo ""
        echo "+ Infrastructure and AMI deleted +"
    else
        echo ""
        echo "  You can destroy the infrastructure later using './utilities/destroy.sh' script."
    fi
fi