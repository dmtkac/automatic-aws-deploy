# Welcoming introduction
Write-Output ""
Write-Output "  Welcome to the automated web application deploying script utilizing AWS infrastructure!"
Write-Output "  Make sure to run it in a PowerShell environment with administrative privileges."
Write-Output ""
Start-Sleep -Seconds 5
Write-Output ""
Write-Output "  The complete description of what this script does is in 'Readme.md' file."
Write-Output "  IMPORTANT! I strongly recommend creating a separate AWS account for trying this out."
Write-Output "  If you use it in your working/production AWS account, you are solely responsible for any caused damage."
Write-Output ""
Start-Sleep -Seconds 7
Write-Output ""
Write-Output "  The provisioned AWS architecture will be the following:"
Write-Output ""
Write-Output "  2 EC2 (GNU/Linux Ubuntu-based) instances with Docker set up on each:"
Write-Output "   > Reverse proxy Nginx server"
Write-Output "   > Node.js web application"
Write-Output "   > PostgreSQL database"
Write-Output "  1 S3 bucket for storing graphical files needed for the web app"
Write-Output "  1 Elastic Load Balancer"
Write-Output "-------"
Write-Output "  1 Elastic Container Registry (if enbaled)"
Write-Output "  1 Route 53 Service (if domain name is provided)"
Write-Output "  1 Amazon Certificate Manager (if domain name is provided)"
Write-Output ""
Start-Sleep -Seconds 10
Write-Output ""
Write-Output "  Please ensure you have the following prerequisites:"
Write-Output ""
Write-Output "1) AWS account with programmatic access granted to an IAM User and the following policies attached:"
Write-Output "   - AmazonEC2FullAccess"
Write-Output "   - AmazonS3FullAccess"
Write-Output "   - EC2InstanceConnect"
Write-Output "   - AmazonEC2ContainerRegistryFullAccess"
Write-Output "   - IAMFullAccess"
Write-Output ""
Write-Output "2) GitHub Action Secrets containing manually added AWS account credentials:"
Write-Output "   - AWS_ACCOUNT_ID"
Write-Output "   - AWS_ACCESS_KEY_ID"
Write-Output "   - AWS_SECRET_ACCESS_KEY"
Write-Output "   - AWS_REGION"
Write-Output "   - REPO_NAME"
Write-Output ""
Write-Output "Note: if you are using plain terminal then you must export all those variables manually before running the script:"
Write-Output '   $env:AWS_ACCOUNT_ID = "your AWS account ID"'
Write-Output '   $env:AWS_ACCESS_KEY_ID = "your AWS access key ID"'
Write-Output '   $env:AWS_SECRET_ACCESS_KEY = "your AWS secret access key"'
Write-Output '   etc.'
Write-Output ""
Write-Output "3) Optionally: if you own a domain name that you'd like to use for access to web app, the following"
Write-Output "   policies must be additionally attached to IAM User:"
Write-Output "   - AmazonRoute53FullAccess"
Write-Output "   - AWSCertificateManagerFullAccess"
Write-Output ""

Start-Sleep -Seconds 10

Write-Output ""
Write-Output "* Checking if all necessary software is installed on this machine (e.g., AWS CLI, Packer, Terraform, Git, etc.)..."

# Checks for required tools and prompt to install if missing
$requiredTools = @("aws", "terraform", "packer", "ssh", "git")
$missingTools = @()

foreach ($tool in $requiredTools) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        $missingTools += $tool
    }
}

if ($missingTools.Count -gt 0) {
    Write-Output ""
    Write-Output "  WARNING: The following tools are required but are not installed: $($missingTools -join ', ')"
    Write-Output "  Please install them and run the script again."
    Write-Output ""
    Write-Output "  Installation instructions can be found at the following links:"
    Write-Output ""
    Write-Output "  AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    Write-Output "  Packer: https://developer.hashicorp.com/packer/install"
    Write-Output "  Terraform: https://developer.hashicorp.com/terraform/install"
    Write-Output "  Git: https://git-scm.com/download/win"
    Write-Output "  OpenSSH server: https://github.com/PowerShell/Win32-OpenSSH/releases/"    
    exit 1
} else {
    Write-Output "  + All required tools are installed."
    Write-Output ""
}

# Makes sure script currently is on main branch
Write-Output "* Checking if 'main' is the current branch..."
git checkout main > $null 2>&1
Write-Output ""

# Creates and switches to a configured branch
$branchName = "main-configured"
if (git branch --list $branchName) {
    git branch -D $branchName > $null 2>&1
}

Write-Output "* Creating and switching to '$branchName' branch..."
git checkout -b $branchName > $null 2>&1
Write-Output ""

Write-Output "* Checking AWS CLI configuration..."

# Captures the AWS region from the configuration
$awsRegion = (aws configure get region)
if (-not $awsRegion) {
    Write-Output "  ! AWS CLI is not configured with a region. Please set it with 'aws configure' and run this script again."
    Write-Output ""
    exit 1
}

# Checkes if AWS CLI is configured correctly and prompt to configure if not
if (-not (aws configure list | Select-String 'access_key')) {
    Write-Output "  ! AWS CLI is not configured. Please run 'aws configure' to set up your credentials."
    aws configure
    if (-not (aws configure list | Select-String 'access_key')) {
        Write-Output "  ! AWS CLI is still not configured correctly. Please ensure your credentials are set up correctly and try again."
        exit 1
    }
}

# Extracts AWS credentials
$AWS_ACCOUNT_ID = (aws sts get-caller-identity --query 'Account' --output text)
$AWS_ACCESS_KEY_ID = (aws configure get aws_access_key_id)
$AWS_SECRET_ACCESS_KEY = (aws configure get aws_secret_access_key)
$AWS_REGION = (aws configure get region)

# Ensures credentials are extracted correctly
if ([string]::IsNullOrEmpty($AWS_ACCESS_KEY_ID) -or [string]::IsNullOrEmpty($AWS_SECRET_ACCESS_KEY) -or [string]::IsNullOrEmpty($AWS_REGION)) {
    Write-Host "  ! Unable to extract AWS credentials. Please ensure AWS CLI is configured correctly and try again."
    exit 1
} else {
    Write-Output "  + AWS CLI is configured correctly."    
}

Start-Sleep -Seconds 2

# Exportes these variables for use in the script
$env:AWS_ACCOUNT_ID = $AWS_ACCOUNT_ID
$env:AWS_ACCESS_KEY_ID = $AWS_ACCESS_KEY_ID
$env:AWS_SECRET_ACCESS_KEY = $AWS_SECRET_ACCESS_KEY
$env:AWS_REGION = $AWS_REGION

# Defines the key name and paths
$keyName = "my-local-key-pair"
$keyPath = "./key/$keyName.pem"
$pubKeyPath = "./key/$keyName.pub"
$openSshPubKeyPath = "./key/$keyName-openssh.pub"

# Ensures the directory exists
if (-Not (Test-Path "./key")) {
    New-Item -ItemType Directory -Path "./key"
}

# Checks if the key pair already exists
try {
    Write-Output ""
    Write-Output "* Deleting existing key files locally..."
    icacls $keyPath /grant:r "$($env:USERNAME):(F)" /c > $null 2>&1
    icacls $pubKeyPath /grant:r "$($env:USERNAME):(F)" /c > $null 2>&1
    icacls $openSshPubKeyPath /grant:r "$($env:USERNAME):(F)" /c > $null 2>&1    
    Remove-Item $keyPath, $pubKeyPath, $openSshPubKeyPath -Force > $null 2>&1
} catch {
    Write-Output ""
    Write-Output "  ! Error: Unable to delete existing key files. Please check permissions and try again."
    exit 1
}

# Fetches and delete the key pair in AWS
try {
    Write-Output ""
    Write-Output "* Fetching existing key pairs from AWS..."
    $existingKeyPair = aws ec2 describe-key-pairs --query "KeyPairs[?KeyName=='$keyName'].KeyName" --output text

    if ($existingKeyPair) {
        Write-Output ""
        Write-Output "* Deleting existing key pair '$existingKeyPair' in AWS..."
        aws ec2 delete-key-pair --key-name $existingKeyPair > $null 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Output "  + Key pair '$existingKeyPair' deleted successfully in AWS."
        } else {
            Write-Output "  ! Error: Failed to delete key pair in AWS."
            exit 1
        }
    } else {
        Write-Output " * No existing key pair named '$keyName' found in AWS. Proceeding..."
    }
} catch {
    Write-Output ""
    Write-Output "  ! Error: Failed to fetch or delete key pair in AWS. Please check your AWS CLI configuration."
    exit 1
}

# Generates RSA key pair using OpenSSL
Write-Output ""
Write-Output "* Generating a new SSH key pair..."
openssl genpkey -algorithm RSA -out $keyPath -outform PEM >$null 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Output ""
    Write-Output "  ! Error: Failed to generate SSH key pair."
    exit 1
}

# Sets correct permissions on the private key file before proceeding  
icacls $keyPath /inheritance:r >$null 2>&1
icacls $keyPath /grant:r "$($env:USERNAME):(R)" >$null 2>&1    

# Generates the public key in PEM format
openssl rsa -in $keyPath -pubout -out $pubKeyPath >$null 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Output ""
    Write-Output "  ! Error: Failed to generate public key."
    exit 1
}

# Converts the public key to OpenSSH format
ssh-keygen -y -f $keyPath | Out-File -FilePath $openSshPubKeyPath -Encoding ascii

if ($LASTEXITCODE -ne 0) {
    Write-Output ""
    Write-Output "  ! Error: Failed to generate public key in OpenSSH format."
    exit 1
}

# Validates the private key (suppress actual output)
Write-Output ""
Write-Output "* Validating the private key using OpenSSL..."
$validationOutput = openssl rsa -in $keyPath -check 2>&1

if ($validationOutput -match "RSA key ok") {
    Write-Output "  RSA key ok"

    # Reads and prepare the public key for import
    $publicKeyMaterial = Get-Content $pubKeyPath -Raw
    $publicKeyMaterial = $publicKeyMaterial -replace "-----BEGIN PUBLIC KEY-----", ""
    $publicKeyMaterial = $publicKeyMaterial -replace "-----END PUBLIC KEY-----", ""
    $publicKeyMaterial = $publicKeyMaterial -replace "`r`n", "" -replace "`n", ""
    $publicKeyMaterial = $publicKeyMaterial.Trim()

    # Ensures the public key is in valid base64 format
    $publicKeyMaterialBytes = [System.Text.Encoding]::ASCII.GetBytes($publicKeyMaterial)
    $publicKeyMaterialBase64 = [System.Convert]::ToBase64String($publicKeyMaterialBytes)

    # Imports the public key to AWS
    Write-Output ""
    Write-Output "* Importing the public key to AWS..."
    try {
        aws ec2 import-key-pair --key-name $keyName --public-key-material "$publicKeyMaterialBase64" | Out-Null
        Write-Output "  Key pair generation and import completed successfully."
    }
    catch {
        Write-Output ""
        Write-Output "  ! Error: Failed to import the public key to AWS."
        exit 1
    }
} else {
    Write-Output ""
    Write-Output "  ! Error: RSA key validation failed."
    exit 1
}

# Sets correct permissions on the private key file
icacls $keyPath /inheritance:r >$null 2>&1
icacls $keyPath /grant:r "$($env:USERNAME):(R)" >$null 2>&1

Write-Output ""
Write-Output "* Please answer following questions necessary to start the deployment process:"

Start-Sleep -Seconds 2

Write-Output ""

# Asks the user whether to enable the CI/CD pipeline
$enableCICD = Read-Host -Prompt "  Do you want to enable 'GitHub Actions -> AWS ECR -> AWS EC2' pipeline for updating Docker containers? (y/n)"

if ($enableCICD -eq "y") {
    Write-Output ""

    # Prompts for ECR repository name
    $REPO_NAME = Read-Host -Prompt "  Enter AWS ECR repository name ('REPO_NAME' that was previously added to GitHub Secrets or to your terminal as env. var.)"

    # Stores it in an environmental variable
    $env:REPO_NAME = $REPO_NAME
    
    # Checks if the ECR repository already exists
    $repoExists = aws ecr describe-repositories --repository-names $REPO_NAME --region $AWS_REGION --output json 2>&1

    if ($repoExists -like "*RepositoryNotFoundException*") {
        Write-Output ""
        Write-Output "* ECR repository '$REPO_NAME' does not exist. Creating it now..."
        
        # Creates ECR repository
        aws ecr create-repository --repository-name $REPO_NAME --region $AWS_REGION > $null 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Output "  + ECR repository '$REPO_NAME' created."
        } else {
            Write-Error "  ! Failed to create the ECR repository."
            exit 1
        }
    } elseif ($repoExists -like "*$REPO_NAME*") {
        Write-Output "  + ECR repository '$REPO_NAME' already exists. Proceeding with the setup..."
    } else {
        Write-Error "  ! Failed to check or create the ECR repository. Please check your AWS credentials and try again."
        exit 1
    }

    # Verifies that the ECR repository is accessible
    $repoCheck = aws ecr describe-repositories --repository-names $REPO_NAME --region $AWS_REGION --output json

    if ($repoCheck) {
        Write-Output "  + ECR repository '$REPO_NAME' is accessible."
    } else {
        Write-Error "  ! ECR repository '$REPO_NAME' could not be found. Please check AWS ECR for issues."
        exit 1
    }

} else {
    Write-Output "  ! CI/CD pipeline setup was skipped. Proceeding..."
}

Start-Sleep -Seconds 2
Write-Output ""

# Function to read and ensure correct formatting of certificate and key files
function Read-FileContentAsBase64 {
    param (
        [string]$filePath
    )

    # Reads the content of the file
    $fileContent = Get-Content $filePath -Raw

    # Removes any whitespace and ensure correct base64 formatting if necessary
    $cleanContent = $fileContent -replace "-----BEGIN [^-]+-----", "" `
                                         -replace "-----END [^-]+-----", "" `
                                         -replace "`r`n", "" -replace "`n", ""
    $cleanContent = $cleanContent.Trim()

    # Converts to base64 if necessary
    $base64Bytes = [System.Text.Encoding]::ASCII.GetBytes($cleanContent)
    $base64EncodedContent = [System.Convert]::ToBase64String($base64Bytes)

    return $base64EncodedContent
}

# Checks if the user has a domain name or use the EC2 instance's public IP (ensure OpenSSL is installed for creating a self-signed certificate)
$hasDomain = Read-Host -Prompt "  Do you have a registered domain name for the web app to be accessible online? (y/n)"

if ($hasDomain -eq "y") {
    Write-Output ""
    $domainName = Read-Host -Prompt "  Enter your domain name"
    Write-Output ""
    
    # Prompts the user to enter the path to the certificate, private key, and optional chain files
    $certFilePath = Read-Host -Prompt "  Enter the full path to your certificate (.crt) file (e.g., C:\Users\JohnDoe\Desktop\SSL\mydomain_cert.crt)"
    Write-Output ""
    $privateKeyFilePath = Read-Host -Prompt "  Enter the full path to your private key (.key) file (e.g., C:\Users\JohnDoe\Desktop\SSL\mydomain_key.key)"
    Write-Output ""
    $chainFilePath = Read-Host -Prompt "  Enter the full path to your certificate chain file (.pem), or press Enter if not applicable"

    # Fetches existing certificates for the domain
    $existingCerts = aws acm list-certificates --query "CertificateSummaryList[?DomainName=='$domainName'].CertificateArn" --output text
    
    # Deletes old certificates if they exist
    if ($existingCerts) {
        foreach ($certArn in $existingCerts) {
            Write-Output ""
            Write-Host "* Deleting existing certificate in ACM..."
            aws acm delete-certificate --certificate-arn $certArn > $null 2>&1
        }
    }
    
    # Uploads the new certificate to ACM
    Write-Output ""
    Write-Output "* Uploading your SSL certificate and private key to ACM..."

    try {
        # Prepares the upload arguments
        $uploadArgs = @(
            "--certificate", "fileb://$certFilePath"
            "--private-key", "fileb://$privateKeyFilePath"
            "--region", $AWS_REGION
            "--query", "CertificateArn"
            "--output", "text"
        )

        # Checks if the certificate chain file is provided
        if (-not [string]::IsNullOrWhiteSpace($chainFilePath)) {
            # Adds the certificate chain argument only if the file path is not empty
            $uploadArgs += "--certificate-chain", "fileb://$chainFilePath"
        }

        # Executes the AWS CLI command to upload the certificate
        $SSL_CERTIFICATE_ARN = aws acm import-certificate @uploadArgs

        Write-Output ""
        Write-Host "  + New Certificate ARN was uploaded successfully."

    } catch {
        Write-Output " ! Error: The certificate was not uploaded successfully. Please verify your certificate, private key, and chain files."
        exit 1
    }

    Write-Output ""
    Write-Output "  Route 53 will automatically map your domain to the load balancer. Make sure your domain's DNS settings are managed by Route 53:"
    Write-Output "  You will need to replace nameservers provided by your domain registrar with those provided by AWS."
    Write-Output "  Once setup is complete, you can access your web app via your custom domain."
    Write-Output ""
} else {
    $SSL_CERTIFICATE_ARN = ""
    $domainName = "***"
    Write-Output ""
    Write-Output "  Access to your web app will be possible via the ELB DNS name (see './connecting_commands.txt') or by mapping it manually to your domain's DNS settings."
    Write-Output "  Since a self-signed certificate is in use, you may see security warnings in the browser, which can be safely ignored for testing purposes."
    Write-Output ""    
}

Write-Output "  Also, you can test provisioned AWS load balancer on Unix-like systems using the './utilities/test_aws_balancer.sh' script."

Start-Sleep -Seconds 10
Write-Output ""

# Prompts user to about IP address
Write-Output "* Your IP address needs to be added to SSH whitelists in AWS VPC and EC2 firewalls."

# Asks for confirmation
$confirmation = Read-Host -Prompt "  Are you agree with fetching your public IP address? (y/n)"
if ($confirmation -ne "y") {
    Write-Output "  ! Operation cancelled."
    exit 1
}

# Fetches IP automatically
try {
    # Attempts to fetch the public IP using api.ipify.org
    $yourIp = (Invoke-RestMethod -Uri "https://api.ipify.org").Trim()
} catch {
    Write-Output "  ! Primary IP service unavailable, attempting fallback..."
    try {
        # Fallback to ipinfo.io if api.ipify.org is unavailable
        $yourIp = (Invoke-RestMethod -Uri "https://ipinfo.io/ip").Trim()
    } catch {
        Write-Output "  ! Fallback IP service also unavailable. Please check your network connection."
        exit 1
    }
}

# File path for ip_ranges.tf
$ipRangesFilePath = "./terraform/ip_ranges.tf"

# Reads the content of ip_ranges.tf
$ipRangesContent = Get-Content -Path $ipRangesFilePath

# Replaces the placeholder *** with the user's IP address
$updatedIpRangesContent = $ipRangesContent -replace "\*\*\*", "$yourIp/32"

# Replaces the placeholder ### with the AWS region
$updatedIpRangesContent = $updatedIpRangesContent -replace "###", $AWS_REGION

# Writes the updated content back to ip_ranges.tf
$updatedIpRangesContent | Set-Content -Path $ipRangesFilePath

# Extracts IP ranges
$ipRanges = Select-String -Path $ipRangesFilePath -Pattern 'ip_prefix\s*=\s*"\S+"' | ForEach-Object {
    $_.Matches.Value.Split('=')[1].Trim().Trim('"')
} | Where-Object { $_ -ne "***" -and $_.Trim() -ne "" }

# Removes any trailing newlines from the IP ranges
$ipRanges = $ipRanges -join "`n"

# Writes IPs to a file
$allowedIpsFile = "./allowed_aws_regional_ips.txt"
[System.IO.File]::WriteAllText($allowedIpsFile, $ipRanges)

Write-Output ""

# Step 1: Fetches the latest Ubuntu AMI ID
Write-Output "* Fetching the latest Ubuntu AMI ID..."
$ubuntuAmiId = (aws ec2 describe-images --owners 099720109477 --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" --query "Images | sort_by(@, &CreationDate)[-1].ImageId" --output text)

# Ensures UBUNTU_AMI_ID is not empty
if (-not $ubuntuAmiId) {
    Write-Error "! Error: Ubuntu AMI ID not found."
    exit 1
}

Write-Output ""

# Step 2: Updates Packer template with the new AMI ID
Write-Output "* Updating Packer template with the new AMI ID..."
$replacementString = '"source_ami": "' + $ubuntuAmiId + '"'
(Get-Content packer/packer-template.json) -replace '"source_ami": "ami-.*"', $replacementString | Set-Content packer/packer-template.json

Write-Output ""

# Step 3: Initializes Packer and download necessary plugins
Write-Output "* Initializing Packer and downloading necessary plugins..."
packer plugins install github.com/hashicorp/amazon

Write-Output ""

# Step 4: Validates the Packer template
Write-Output "* Validating Packer template..."
packer validate packer/packer-template.json

Write-Output ""

# Step 5: Builds the AMI with Packer and capture the output
Write-Output "* Building the AMI with Packer. This may take 3-4 minutes..."
$packerOutput = & packer build packer/packer-template.json

Write-Output ""

# Prints the Packer output for details
Write-Output "  Packer Output: $packerOutput"

# Extracts the most recent AMI ID from the Packer output
$amiId = ($packerOutput | Select-String -Pattern 'ami-\w{8,17}' | Select-Object -Last 1).Matches.Value

# Ensures AMI_ID is not empty
if (-not $amiId) {
    Write-Error "  ! Error: AMI ID not found in Packer output."
    exit 1
}

Write-Output "* Using AMI ID: $amiId for deployment"

Write-Output ""

# Step 6: Initializes Terraform
Write-Output "* Initializing Terraform..."
Set-Location -Path terraform
terraform init

Write-Output ""

# Step 7: Plans the deployment
Write-Output "* Planning the deployment..."
terraform plan -out=tfplan `
  -var "ami_id=$amiId" `
  -var "aws_region=$awsRegion" `
  -var "domain_name=$domainName" `
  -var "ssl_certificate_arn=$SSL_CERTIFICATE_ARN" `
  -var "aws_key_pair_name=$keyName" `
  -var "initial_private_key_path=$keyPath"

Write-Output ""

# Step 8: Waits for user confirmation before applying the plan
$continueDeployment = Read-Host -Prompt "  Review the plan and press Enter to continue with 'terraform apply' or type 'n' to cancel and delete the AMI"

if ($continueDeployment -eq "n") {
    # Deletes the AMI and its snapshots
    Write-Output ""
    Write-Output "* Deleting the AMI and associated snapshots..."

    # Gets the latest AMI ID
    $AmiId = aws ec2 describe-images --owners self --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" --output text

    # Deregisters the AMI ID
    aws ec2 deregister-image --image-id $AmiId

    # Waits for the deregistration to complete
    Write-Output ""
    Write-Output "* Waiting for AMI to deregister..."
    Start-Sleep -Seconds 5

    # Describes all snapshots to identify any that need deletion
    $snapshotIds = aws ec2 describe-snapshots --owner-ids self --query "Snapshots[*].SnapshotId" --output text
    if ($snapshotIds) {
        foreach ($snapshotId in $snapshotIds) {
            aws ec2 delete-snapshot --snapshot-id $snapshotId
        }
        Write-Output "  AMI and snapshots deleted."
    } else {
        Write-Output "  No snapshots found or AMI already deleted."
    }

    # Deletes the imported key pair
    Write-Output ""
    Write-Output "* Deleting the imported key pair..."
    try {
        aws ec2 delete-key-pair --key-name $keyName > $null 2>&1
        Write-Output "+ Key pair '$keyName' deleted successfully."
    } catch {
        Write-Output ""
        Write-Output " ! Error: Failed to delete the key pair '$keyName'. It may not exist or an error occurred."
    }

    # Deletes the ECR repository
    if ($REPO_NAME) {
        Write-Output ""
        Write-Output "* Deleting the ECR repository '$REPO_NAME'..."
        aws ecr delete-repository --repository-name $REPO_NAME --region $AWS_REGION --force > $null 2>&1
        Write-Output "+ ECR repository deleted."
    } else {
        Write-Output " ! ECR repository name not found. Skipping ECR deletion."
    }

    # Deletes any existing ACM certificates
    if (-not [string]::IsNullOrEmpty($domainName)) {
        Write-Output ""
        Write-Output "* Checking for ACM certificates to delete..."
        $existingCerts = aws acm list-certificates --query "CertificateSummaryList[?DomainName=='$domainName'].CertificateArn" --output text

        if ($existingCerts) {
            foreach ($certArn in $existingCerts) {
                Write-Output ""
                Write-Output "* Deleting certificate: $certArn"
                try {
                    aws acm delete-certificate --certificate-arn $certArn
                    Write-Output "+ Certificate deleted successfully."
                } catch {
                    Write-Output " ! Error deleting certificate: $certArn"
                }
            }
        } else {
            Write-Output " ! No certificates found for domain: $domainName"
        }
    } else {
        Write-Output " ! Domain name is not defined. Skipping certificate deletion..."
    }

    exit
}

Write-Output ""

# Step 9: Applies the Terraform plan
Write-Output "* Applying the Terraform plan. This may take a few minutes..."
terraform apply -auto-approve tfplan

Write-Output ""

# Step 10: Retrieves the instance IDs and public IPs
Write-Output "* Retrieving the instance IDs and public IPs..."
$instanceIds = (terraform output -json instance_ids | ConvertFrom-Json)

# Extracting instances IDs
$firstInstanceId = $instanceIds[0]
$secondInstanceId = $instanceIds[1]

# Extracting instances public IPs
$firstInstancePublicIp = (aws ec2 describe-instances --instance-ids $firstInstanceId --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
$secondInstancePublicIp = (aws ec2 describe-instances --instance-ids $secondInstanceId --query "Reservations[0].Instances[0].PublicIpAddress" --output text)

# Ensures FIRST_INSTANCE_PUBLIC_IP is not empty
if (-not $firstInstancePublicIp) {
    Write-Error "  ! Error: Public IP not found for the first EC2 instance."
    exit 1
}

# Ensures SECOND_INSTANCE_PUBLIC_IP is not empty
if (-not $secondInstancePublicIp) {
    Write-Error "  ! Error: Public IP not found for the second EC2 instance."
    exit 1
}

# Converts the IP addresses to FQDN format
$firstInstanceFqdn = "$($firstInstancePublicIp -replace '\.', '-')"
$secondInstanceFqdn = "$($secondInstancePublicIp -replace '\.', '-')"

Write-Output ""

# Path to the output file with connecting commands to EC2 instances
$outputFile = "../connecting_commands.txt"

Write-Output "* Writing SSH commands to 'connecting_commands.txt' file in project's root directory..."

Start-Sleep -Seconds 3

# Generates SSH commands
$firstInstanceSSH = "ssh -o StrictHostKeyChecking=no -i $keyPath ubuntu@ec2-$firstInstanceFqdn.$awsRegion.compute.amazonaws.com"
$secondInstanceSSH = "ssh -o StrictHostKeyChecking=no -i $keyPath ubuntu@ec2-$secondInstanceFqdn.$awsRegion.compute.amazonaws.com"

# Writes SSH commands to the file
@"
# SSH commands to connect to your provisioned EC2 instances:
$firstInstanceSSH
$secondInstanceSSH
"@ | Out-File -FilePath $outputFile -Encoding UTF8

Write-Output ""

# Step 11: Fetches the SSH host keys and add them to known_hosts
Write-Output "* Fetching the SSH host keys and adding them to known_hosts on this machine..."

# Defines the hostnames for your instances
$firstInstanceHost = "ec2-$firstInstanceFqdn.$awsRegion.compute.amazonaws.com"
$secondInstanceHost = "ec2-$secondInstanceFqdn.$awsRegion.compute.amazonaws.com"

ssh-keyscan -H $firstInstanceHost >> "C:\Users\$env:USERNAME\.ssh\known_hosts"
ssh-keyscan -H $secondInstanceHost >> "C:\Users\$env:USERNAME\.ssh\known_hosts"

Write-Output ""

# Step 12: Displays useful information
$elbDnsName = terraform output -raw elb_dns_name

if ($domainName -eq "***") {
    Write-Output "  You can access your web application using the following ELB DNS name:"
    Write-Output "  ELB DNS Name: $elbDnsName"
    Write-Output "  The generated ELB DNS name '$elbDnsName' is also added to the file './connecting_commands.txt'."
} else {
    Write-Output "  You can access your web application either by using your domain name:"
    Write-Output "  Domain Name: $domainName"
    Write-Output "  or by using the generated ELB DNS name:"
    Write-Output "  ELB DNS Name: $elbDnsName"
    Write-Output "  The generated ELB DNS name '$elbDnsName' is also added to the file './connecting_commands.txt'."
}

# Appends the ELB DNS information to connecting_commands.txt
Add-Content -Path $outputFile -Value "To access the web app in the browser, use the following URL:`n$elbDnsName"

# Updates 'test_aws_balancer.sh' script with the actual ELB DNS name
$testScriptPath = "../utilities/test_aws_balancer.sh"
(Get-Content $testScriptPath) -replace "\*\*\*", $elbDnsName | Set-Content $testScriptPath

# Step 13: Uploads illustrations to S3 bucket
$s3BucketName = $(terraform output -raw s3_bucket_name)

Write-Output ""
Write-Output "  For managing static assets, you can use the following S3 bucket:"
Write-Output "  S3 Bucket Name: $s3BucketName"

# Defines path to the illustrations folder
$illustrationsDir = "./illustrations"

Write-Output ""
Write-Output "* Uploading illustrations to S3 bucket: $s3BucketName"
Set-Location -Path ..
if (Test-Path $illustrationsDir -PathType Container) {
    aws s3 cp $illustrationsDir "s3://$s3BucketName/" --recursive
    if ($LASTEXITCODE -eq 0) {
        Write-Output "  + Illustrations uploaded successfully."
    } else {
        Write-Output "  ! Failed to upload illustrations."
        exit 1
    }
} else {
    Write-Output "  ! The provided path does not exist or is not a directory. Please check the path and try again."
    exit 1
}

Start-Sleep -Seconds 2
Write-Output ""

# Step 14: Pushes the modified files to the configured branch
Write-Output "* Creating and pushing the main-configured branch to the remote repository: $branchName"

# Adds and commit the changes
git add .
git commit -m "* Deploying infrastructure with configured user inputs..."

# Pushes the configured branch to the repository and set upstream
git push --set-upstream origin $branchName

Start-Sleep -Seconds 2
Write-Output ""

Write-Output "+ Configured branch $branchName created and pushed to the remote repository."

Start-Sleep -Seconds 2
Write-Output ""
Write-Output ""
Write-Output "+ Your infrastructure has been successfully provisioned."

# Step 15: Saves terraform variables to a text file for 'destroy.ps1' script
$terraformVarsFilePath = "./terraform/vars_for_destroy.txt"

# Truncates the file by writing the first line
"ami_id=$amiId" | Out-File -FilePath $terraformVarsFilePath -Encoding UTF8
# Appends the remaining variables to the file
"aws_region=$awsRegion" | Out-File -FilePath $terraformVarsFilePath -Encoding UTF8 -Append
"domain_name=$domainName" | Out-File -FilePath $terraformVarsFilePath -Encoding UTF8 -Append
"ssl_certificate_arn=$SSL_CERTIFICATE_ARN" | Out-File -FilePath $terraformVarsFilePath -Encoding UTF8 -Append
"aws_key_pair_name=$keyName" | Out-File -FilePath $terraformVarsFilePath -Encoding UTF8 -Append
"initial_private_key_path=$keyPath" | Out-File -FilePath $terraformVarsFilePath -Encoding UTF8 -Append

# Step 16: Option to log into provisioned EC2 instance
$useSSH = Read-Host -Prompt "  Do you want further monitor deployment process on provisioned EC2 instances now? (y/n)"
if ($useSSH -eq "y") {
    Write-Output "  Once connected run command 'tail -f ~/install_script.log'. Which instance do you want to connect to?"
    Write-Output ""
    Write-Output "1) First instance (Public IP: $firstInstancePublicIp)"
    Write-Output "2) Second instance (Public IP: $secondInstancePublicIp)"
    $instanceChoice = Read-Host -Prompt "  Enter 1 or 2"
    $exitCode = 0

    if ($instanceChoice -eq "1") {
        ssh -o StrictHostKeyChecking=no -i $keyPath ubuntu@ec2-$firstInstanceFqdn.$awsRegion.compute.amazonaws.com
        $exitCode = $LASTEXITCODE
    } elseif ($instanceChoice -eq "2") {
        ssh -o StrictHostKeyChecking=no -i $keyPath ubuntu@ec2-$secondInstanceFqdn.$awsRegion.compute.amazonaws.com
        $exitCode = $LASTEXITCODE
    } else {
        Write-Output "  ! Invalid choice. Exiting."
        Write-Output ""
        $exitCode = 1
    }

    if ($exitCode -ne 0) {
        Write-Output "  ! SSH connection failed."
        Write-Output ""

        # Option to destroy provisioned infrastructure to avoid charges
        $destroyInfra = Read-Host -Prompt "  Do you want to destroy the provisioned infrastructure and delete the AMI and snapshots now? (y/n)"
        if ($destroyInfra -eq "y") {

            Write-Output ""
            Write-Output "  Insert the following variables when asked:"
            Write-Output "   AMI ID: $amiId"
            Write-Output "   Key Name: $keyName"
            Write-Output "   AWS Region: $awsRegion"
            Write-Output "   Key Path: $keyPath"
            Write-Output "   Domain Name: $domainName"
            Write-Output "   SSL Certificate ARN: $SSL_CERTIFICATE_ARN"

            Set-Location -Path terraform
            & terraform destroy -auto-approve
                -var "ami_id=$amiId" `
                -var "aws_region=$awsRegion" `
                -var "domain_name=$domainName" `
                -var "ssl_certificate_arn=$SSL_CERTIFICATE_ARN" `
                -var "aws_key_pair_name=$keyName" `
                -var "initial_private_key_path=$keyPath"

            # Fetches existing certificates for the domain using the domain name from vars_for_destroy.txt
            if (-not [string]::IsNullOrEmpty($domainName)) {
                $existingCerts = aws acm list-certificates --query "CertificateSummaryList[?DomainName=='$domainName'].CertificateArn" --output text

                # Deletes old certificates if they exist
                if ($existingCerts) {
                    foreach ($certArn in $existingCerts) {
                        Write-Output ""
                        Write-Host "* Deleting existing certificate: $certArn"
                        try {
                            aws acm delete-certificate --certificate-arn $certArn > $null 2>&1
                            Write-Host "+ Certificate deleted successfully."
                        } catch {
                            Write-Host " ! Error deleting certificate: $certArn"
                        }
                    }
                } else {
                    Write-Host " ! No certificates found for domain: $domainName"
                }
            } else {
                Write-Host " ! Domain name is not defined. Skipping certificate deletion..."
            }

            # Deletes the AMI and its snapshots
            Write-Output ""
            Write-Output "* Deleting the AMI and associated snapshots..."

            # Gets the AMI ID
            $AmiId = aws ec2 describe-images --owners self --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" --output text

            # Deregisters the AMI ID
            aws ec2 deregister-image --image-id $AmiId

            # Waits for the deregistration to complete
            Write-Output ""
            Write-Output "* Waiting for AMI to deregister..."
            Write-Output ""
            Start-Sleep -Seconds 5

            # Describes all snapshots to identify any that need deletion
            $snapshotIds = aws ec2 describe-snapshots --owner-ids self --query "Snapshots[*].SnapshotId" --output text
            if ($snapshotIds) {
                foreach ($snapshotId in $snapshotIds) {
                    aws ec2 delete-snapshot --snapshot-id $snapshotId
                }
                Write-Output "  + AMI and snapshots deleted."
            } else {
                Write-Output "  ! No snapshots found or AMI already deleted."
            }

            # Deletes the imported key pair
            Write-Output ""
            Write-Output "* Deleting the imported key pair..."
            try {
                aws ec2 delete-key-pair --key-name $keyName
                Write-Output "  Key pair '$keyName' deleted successfully."
            } catch {
                Write-Output ""
                Write-Output "  ! Error: Failed to delete the key pair '$keyName'. It may not exist or an error occurred."
            }

            # Deletes the ECR repository
            if ($REPO_NAME) {
                Write-Output ""
                Write-Output "* Deleting the ECR repository '$REPO_NAME'..."
                aws ecr delete-repository --repository-name $REPO_NAME --region $AWS_REGION --force
                Write-Output "+ ECR repository deleted."
            } else {
                Write-Output "  ! ECR repository name not found. Skipping ECR deletion."
            }

            # Deletes any existing ACM certificates
            if (-not [string]::IsNullOrEmpty($domainName)) {
                Write-Output ""
                Write-Output "* Checking for ACM certificates to delete..."
                $existingCerts = aws acm list-certificates --query "CertificateSummaryList[?DomainName=='$domainName'].CertificateArn" --output text

                if ($existingCerts) {
                    foreach ($certArn in $existingCerts) {
                        Write-Output ""
                        Write-Output "* Deleting certificate: $certArn"
                        try {
                            aws acm delete-certificate --certificate-arn $certArn
                            Write-Output "+ Certificate deleted successfully."
                        } catch {
                            Write-Output " ! Error deleting certificate: $certArn"
                        }
                    }
                } else {
                    Write-Output " ! No certificates found for domain: $domainName"
                }
            } else {
                Write-Output " ! Domain name is not defined. Skipping certificate deletion..."
            }
            
            Write-Output ""
            Write-Output "+ Infrastructure and AMI deleted +"
        } else {
            Write-Output ""
            Write-Output "  You can destroy the infrastructure later using './utilities/destroy.ps1' script."
        }
    }
} else {
    Write-Output ""
    Write-Output "  You can connect to your EC2 instances later using the following commands:"
    Write-Output "  SSH commands to connect to your provisioned EC2 instances have been saved to './connecting_commands.txt'."
    Write-Output "  You can use these commands to connect to the instances at any time."
    Write-Output ""
    
    # Option to destroy provisioned infrastructure to avoid charges
    $destroyInfra = Read-Host -Prompt "Do you want to destroy the provisioned infrastructure and delete the AMI and snapshots now? (y/n)"
    if ($destroyInfra -eq "y") {

        Write-Output ""
        Write-Output "  Insert the following variables when asked:"
        Write-Output "   AMI ID: $amiId"
        Write-Output "   Key Name: $keyName"
        Write-Output "   AWS Region: $awsRegion"
        Write-Output "   Key Path: $keyPath"
        Write-Output "   Domain Name: $domainName"
        Write-Output "   SSL Certificate ARN: $SSL_CERTIFICATE_ARN"

        Set-Location -Path terraform
        & terraform destroy -auto-approve
            -var "ami_id=$amiId" `
            -var "aws_region=$awsRegion" `
            -var "domain_name=$domainName" `
            -var "ssl_certificate_arn=$SSL_CERTIFICATE_ARN" `
            -var "aws_key_pair_name=$keyName" `
            -var "initial_private_key_path=$keyPath"

        # Deletes any existing ACM certificates
        if (-not [string]::IsNullOrEmpty($domainName)) {
            $existingCerts = aws acm list-certificates --query "CertificateSummaryList[?DomainName=='$domainName'].CertificateArn" --output text
            
            if ($existingCerts) {
                foreach ($certArn in $existingCerts) {
                    Write-Output ""
                    Write-Host "* Deleting existing certificate: $certArn"
                    try {
                        aws acm delete-certificate --certificate-arn $certArn > $null 2>&1
                        Write-Host "+ Certificate deleted successfully."
                    } catch {
                        Write-Host " ! Error deleting certificate: $certArn"
                    }
                }
            } else {
                Write-Host " ! No certificates found for domain: $domainName"
            }
        } else {
            Write-Host " ! Domain name is not defined. Skipping certificate deletion..."
        }

        # Deletes the AMI and its snapshots
        Write-Output ""
        Write-Output "* Deleting the AMI and associated snapshots..."

        # Gets the AMI ID
        $AmiId = aws ec2 describe-images --owners self --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" --output text

        # Deregisters the AMI ID
        aws ec2 deregister-image --image-id $AmiId

        # Waits for the deregistration to complete
        Write-Output ""
        Write-Output "* Waiting for AMI to deregister..."
        Start-Sleep -Seconds 5

        # Describes all snapshots to identify any that need deletion
        $snapshotIds = aws ec2 describe-snapshots --owner-ids self --query "Snapshots[*].SnapshotId" --output text
        if ($snapshotIds) {
            foreach ($snapshotId in $snapshotIds) {
                aws ec2 delete-snapshot --snapshot-id $snapshotId
            }
            Write-Output ""
            Write-Output "  + AMI and snapshots deleted."
        } else {
            Write-Output ""
            Write-Output "  ! No snapshots found or AMI already deleted."
        }

        # Deletes the imported key pair
        Write-Output ""
        Write-Output "* Deleting the imported key pair..."
        try {
            aws ec2 delete-key-pair --key-name $keyName
            Write-Output "+ Key pair '$keyName' deleted successfully."
        } catch {
            Write-Output ""
            Write-Output "  ! Error: Failed to delete the key pair '$keyName'. It may not exist or an error occurred."
        }

        # Deletes the ECR repository
        if ($REPO_NAME) {
            Write-Output ""
            Write-Output "* Deleting the ECR repository '$REPO_NAME'..."
            aws ecr delete-repository --repository-name $REPO_NAME --region $AWS_REGION --force
            Write-Output "  + ECR repository deleted."
        } else {
            Write-Output "  ! ECR repository name not found. Skipping ECR deletion..."
        }

        Write-Output ""
        Write-Output "+ Infrastructure and AMI deleted +"
    } else {
        Write-Output ""
        Write-Output "  You can destroy the infrastructure later using './utilities/destroy.ps1' script."
    }
}