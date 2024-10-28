#!/bin/bash

# Welcoming introduction
echo ""
echo "  Welcome to the automated AWS infrastructure destroying script!"
echo "  Use it with CAUTION!"

sleep 3

# Checks for required tools
echo ""
echo "* Checking for required tools..."
required_tools=("aws" "terraform" "git")
missing_tools=()

for tool in "${required_tools[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        missing_tools+=("$tool")
    fi
done

if [ ${#missing_tools[@]} -gt 0 ]; then
    echo ""
    echo " ! The following tools are required but are not installed: ${missing_tools[*]}"
    echo "   Please install them and run the script again."
    exit 1
else
    echo " + All required tools are installed."
fi

# Checks AWS CLI configuration
echo ""
echo "* Checking AWS CLI configuration..."

aws_region=$(aws configure get region)
if [ -z "$aws_region" ]; then
    echo " ! AWS CLI is not configured with a region. Please set it with 'aws configure' and run this script again."
    exit 1
fi

if ! aws configure list | grep -q 'access_key'; then
    echo " ! AWS CLI is not configured. Please run 'aws configure' to set up your credentials."
    aws configure
    if ! aws configure list | grep -q 'access_key'; then
        echo " ! AWS CLI is still not configured correctly. Please ensure your credentials are set up correctly and try again."
        exit 1
    fi
fi

# Extracts AWS Account ID, Access Key, Secret Access Key, Region, and ECR Repository Name
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)
AWS_REGION=$(aws configure get region)
REPO_NAME=$(aws ecr describe-repositories --query "repositories[0].repositoryName" --region "$AWS_REGION" --output text)

if [[ -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" || -z "$AWS_REGION" ]]; then
    echo " ! Unable to extract AWS credentials. Please ensure AWS CLI is configured correctly and try again."
    exit 1
else
    echo " + AWS CLI is configured correctly."
fi

if [[ -z "$REPO_NAME" ]]; then
    echo " ! No ECR repository found."
else
    echo " + ECR repository '$REPO_NAME' found."
    export REPO_NAME="$REPO_NAME"
fi

export AWS_ACCOUNT_ID="$AWS_ACCOUNT_ID"
export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
export AWS_REGION="$AWS_REGION"

sleep 2

# Switches to a configured branch
echo ""
echo "* Checking current git branch..."

# Checks if on 'main-configured' branch
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$current_branch" != "main-configured" ]; then
    echo " ! You are not on the 'main-configured' branch."

    # Checks if 'main-configured' branch exists
    if ! git show-ref --verify --quiet refs/heads/main-configured; then
        echo ""
        echo " ! The 'main-configured' branch does not exist."
        echo " ! This might be because the 'deploy.sh' script has not been run yet."
        echo " ! Please run it first to create the 'main-configured' branch."
        exit 1
    else
        echo ""
        echo " + Switching to 'main-configured' branch..."
        git checkout main-configured > /dev/null 2>&1
    fi
fi

sleep 2

# Checks if Terraform has any resources managed
echo ""
echo "* Checking for Terraform configuration..."

# Changes working directory to terraform
terraform_dir="../terraform"
cd "$terraform_dir"

tf_state_file="terraform.tfstate"
if [ ! -f "$tf_state_file" ]; then
    echo " ! No Terraform state file found. No infrastructure to destroy."
    exit 0
fi

# Check if any resources are listed in the state file without using jq
state_content=$(grep -c '"type": "aws_' "$tf_state_file")
if [ "$state_content" -eq 0 ]; then
    echo " ! No resources are currently provisioned. Nothing to destroy."
    exit 0
else
    echo " + Resources detected. Proceeding with destruction..."
fi

sleep 2

# Path to the vars_for_destroy.txt file
terraformVarsFilePath="./vars_for_destroy.txt"

# Checks if the file exists
if [[ -f "$terraformVarsFilePath" ]]; then
    # Initializes an associative array to store the variables
    declare -A terraformVarsHashtable

    # Reads the file line by line and parse key-value pairs
    while IFS='=' read -r key value; do
        terraformVarsHashtable["$key"]="$value"
    done < "$terraformVarsFilePath"

    # Accesses the variables from the associative array
    amiId="${terraformVarsHashtable[ami_id]}"
    awsRegion="${terraformVarsHashtable[aws_region]}"
    domainName="${terraformVarsHashtable[domain_name]}"
    SSL_CERTIFICATE_ARN="${terraformVarsHashtable[ssl_certificate_arn]}"
    keyName="${terraformVarsHashtable[aws_key_pair_name]}"
    keyPath="${terraformVarsHashtable[initial_private_key_path]}"

    echo ""
    echo "  The following variables will be used:"
    echo ""
    echo "   AMI ID: $amiId"
    echo "   Key Name: $keyName"
    echo "   AWS Region: $awsRegion"
    echo "   Key Path: $keyPath"
    echo "   Domain Name: $domainName"
    echo "   SSL Certificate ARN: $SSL_CERTIFICATE_ARN"

else
    echo "Error: file 'vars_for_destroy.txt' not found. Cannot proceed with destruction."
fi

# Confirms destruction
echo ""
read -p "Do you want to destroy the provisioned infrastructure and delete the AMI and snapshots now? (y/n): " destroyInfra

if [[ "$destroyInfra" == "y" ]]; then
    # Proceeds with destroying infrastructure
    echo "* Destroying the provisioned infrastructure..."
    terraform destroy -auto-approve \
        -var "ami_id=$amiId" \
        -var "aws_region=$awsRegion" \
        -var "domain_name=$domainName" \
        -var "ssl_certificate_arn=$SSL_CERTIFICATE_ARN" \
        -var "aws_key_pair_name=$keyName" \
        -var "initial_private_key_path=$keyPath"

    # Deregisters the AMI ID with retry logic
    maxRetries=5
    retryCount=0
    deregistered=false

    while [[ "$deregistered" == false && "$retryCount" -lt "$maxRetries" ]]; do
        echo ""
        echo "* Attempting to deregister AMI (Attempt: $((retryCount + 1)))..."
        if aws ec2 deregister-image --image-id "$amiId"; then
            echo "  + AMI deregistered successfully."
            deregistered=true
        else
            echo "  ! Error: Failed to deregister AMI. Retrying in 10 seconds..."
            sleep 10
            ((retryCount++))
        fi
    done

    if [[ "$deregistered" == false ]]; then
        echo "  ! Failed to deregister AMI after multiple attempts."
        exit 1
    fi

    # Waits for the deregistration to complete
    echo ""
    echo "* Waiting for AMI to deregister fully..."
    sleep 30

    # Deletes associated snapshots with retry logic
    snapshotIds=$(aws ec2 describe-snapshots --owner-ids self --query "Snapshots[*].SnapshotId" --output text)
    for snapshotId in $snapshotIds; do
        snapshotDeleted=false
        retryCount=0
        while [[ "$snapshotDeleted" == false && "$retryCount" -lt "$maxRetries" ]]; do
            echo ""
            echo "* Attempting to delete snapshot $snapshotId (Attempt: $((retryCount + 1)))..."
            if aws ec2 delete-snapshot --snapshot-id "$snapshotId"; then
                echo "  + Snapshot deleted successfully."
                snapshotDeleted=true
            else
                echo "  ! Error: Failed to delete snapshot $snapshotId. Retrying in 10 seconds..."
                sleep 10
                ((retryCount++))
            fi
        done

        if [[ "$snapshotDeleted" == false ]]; then
            echo "  ! Failed to delete snapshot $snapshotId after multiple attempts."
        fi
    done

    # Deletes the imported key pair
    echo ""
    echo "* Deleting the imported key pair..."
    if aws ec2 delete-key-pair --key-name "$keyName"; then
        echo "  + Key pair '$keyName' deleted successfully."
    else
        echo "  ! Error: Failed to delete the key pair '$keyName'. It may not exist or an error occurred."
    fi

    # Deletes the ECR repository
    if [[ -n "$REPO_NAME" ]]; then
        echo ""
        echo "* Deleting the ECR repository '$REPO_NAME'..."
        if aws ecr delete-repository --repository-name "$REPO_NAME" --region "$awsRegion" --force; then
            echo "  + ECR repository deleted."
        else
            echo "  ! Error: Failed to delete ECR repository."
        fi
    else
        echo "  ! ECR repository name not found. Skipping ECR deletion."
    fi

    # Fetches existing certificates for the domain using the domain name
    if [[ -n "$domainName" ]]; then
        existingCerts=$(aws acm list-certificates --query "CertificateSummaryList[?DomainName=='$domainName'].CertificateArn" --output text)
        if [[ -n "$existingCerts" ]]; then
            for certArn in $existingCerts; do
                echo ""
                echo "* Attempting to delete certificate: $certArn"
                if aws acm delete-certificate --certificate-arn "$certArn"; then
                    echo "  + Certificate deleted successfully."
                else
                    echo "  ! Error deleting certificate: $certArn"
                fi
            done
        else
            echo "  ! No certificates found for domain: $domainName"
        fi
    else
        echo "  ! Domain name is not defined. Skipping certificate deletion..."
    fi

    echo ""
    echo "+ Infrastructure and AMI deleted +"
fi