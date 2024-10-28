# Welcoming introduction
Write-Output ""
Write-Output "  Welcome to the automated AWS infrastructure destroying script!"
Write-Output "  Use it with CAUTION!"

Start-Sleep -Seconds 3

# Checks for required tools
Write-Output ""
Write-Output "* Checking for requiered tools..."
$requiredTools = @("aws", "terraform", "git")
$missingTools = @()

foreach ($tool in $requiredTools) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        $missingTools += $tool
    }
}

if ($missingTools.Count -gt 0) {
    Write-Output ""
    Write-Output " ! The following tools are required but are not installed: $($missingTools -join ', ')"
    Write-Output "   Please install them and run the script again."
    exit 1
} else {
    Write-Output " + All required tools are installed."
}

# Checks AWS CLI configuration
Write-Output ""
Write-Output "* Checking AWS CLI configuration..."

$awsRegion = (aws configure get region)
if (-not $awsRegion) {
    Write-Output " ! AWS CLI is not configured with a region. Please set it with 'aws configure' and run this script again."
    exit 1
}

if (-not (aws configure list | Select-String 'access_key')) {
    Write-Output " ! AWS CLI is not configured. Please run 'aws configure' to set up your credentials."
    aws configure
    if (-not (aws configure list | Select-String 'access_key')) {
        Write-Output " ! AWS CLI is still not configured correctly. Please ensure your credentials are set up correctly and try again."
        exit 1
    }
}

# Extracts AWS Account ID, Access Key, Secret Access Key, Region, and ECR Repository Name
$AWS_ACCOUNT_ID = (aws sts get-caller-identity --query 'Account' --output text)
$AWS_ACCESS_KEY_ID = (aws configure get aws_access_key_id)
$AWS_SECRET_ACCESS_KEY = (aws configure get aws_secret_access_key)
$AWS_REGION = (aws configure get region)
$REPO_NAME = (aws ecr describe-repositories --query "repositories[0].repositoryName" --region $AWS_REGION --output text)

if ([string]::IsNullOrEmpty($AWS_ACCESS_KEY_ID) -or [string]::IsNullOrEmpty($AWS_SECRET_ACCESS_KEY) -or [string]::IsNullOrEmpty($AWS_REGION)) {
    Write-Output " ! Unable to extract AWS credentials. Please ensure AWS CLI is configured correctly and try again."
    exit 1
} else {
    Write-Output " + AWS CLI is configured correctly."
}

if ([string]::IsNullOrEmpty($REPO_NAME)) {
    Write-Output " ! No ECR repository found."
} else {
    Write-Output " + ECR repository '$REPO_NAME' found."
    $env:REPO_NAME = $REPO_NAME
}

$env:AWS_ACCOUNT_ID = $AWS_ACCOUNT_ID
$env:AWS_ACCESS_KEY_ID = $AWS_ACCESS_KEY_ID
$env:AWS_SECRET_ACCESS_KEY = $AWS_SECRET_ACCESS_KEY
$env:AWS_REGION = $AWS_REGION

Start-Sleep -Seconds 2

# Switches to a configured branch
Write-Output ""
Write-Output "* Checking current git branch..."

# Checks if on 'main-configured' branch
$currentBranch = git rev-parse --abbrev-ref HEAD
if ($currentBranch -ne "main-configured") {
    Write-Output " ! You are not on the 'main-configured' branch."

    # Checks if 'main-configured' branch exists
    $branchExists = git branch --list "main-configured"
    if (-not $branchExists) {
        Write-Output ""
        Write-Output " ! The 'main-configured' branch does not exist."
        Write-Output " ! This might be because the 'deploy.ps1' script has not been run yet."
        Write-Output " ! Please run it first to create the 'main-configured' branch."
        exit 1
    } else {
        Write-Output ""
        Write-Output " + Switching to 'main-configured' branch..."
        git checkout main-configured > $null 2>&1
    }
}

Start-Sleep -Seconds 2

# Checks if Terraform has any resources managed
Write-Output ""
Write-Output "* Checking for Terraform configuration..."

# Changes working directory to terraform
$terraformDir = "../terraform"
Set-Location -Path $terraformDir

$tfStateFile = "terraform.tfstate"
if (-not (Test-Path $tfStateFile)) {
    Write-Output " ! No Terraform state file found. No infrastructure to destroy."
    exit 0
}

$stateContent = Get-Content -Path $tfStateFile -Raw | ConvertFrom-Json
if ($stateContent.resources.Count -eq 0) {
    Write-Output " ! No resources are currently provisioned. Nothing to destroy."
    exit 0
} else {
    Write-Output " + Resources detected. Proceeding with destruction..."
}

Start-Sleep -Seconds 2

# Path to the vars_for_destroy.txt file
$terraformVarsFilePath = "./vars_for_destroy.txt"

# Checks if the file exists
if (Test-Path $terraformVarsFilePath) {
    # Reads the file line by line
    $terraformVars = Get-Content -Path $terraformVarsFilePath

    # Initializes a hashtable to store the variables
    $terraformVarsHashtable = @{}

    # Parses each line and store the key-value pairs in the hashtable
    foreach ($line in $terraformVars) {
        $key, $value = $line -split '='
        $terraformVarsHashtable[$key] = $value
    }

    # Accesses the variables from the hashtable
    $amiId = $terraformVarsHashtable["ami_id"]
    $awsRegion = $terraformVarsHashtable["aws_region"]
    $domainName = $terraformVarsHashtable["domain_name"]
    $SSL_CERTIFICATE_ARN = $terraformVarsHashtable["ssl_certificate_arn"]
    $keyName = $terraformVarsHashtable["aws_key_pair_name"]
    $keyPath = $terraformVarsHashtable["initial_private_key_path"]

    Write-Output ""
    Write-Output "  The following variables will be used:"
    Write-Output ""
    Write-Output "   AMI ID: $amiId"
    Write-Output "   Key Name: $keyName"
    Write-Output "   AWS Region: $awsRegion"
    Write-Output "   Key Path: $keyPath"
    Write-Output "   Domain Name: $domainName"
    Write-Output "   SSL Certificate ARN: $SSL_CERTIFICATE_ARN"

} else {
    Write-Output "Error: file 'vars_for_destroy.txt' not found. Cannot proceed with destruction."
}

# Confirms destruction
Write-Output ""
$destroyInfra = Read-Host -Prompt "Do you want to destroy the provisioned infrastructure and delete the AMI and snapshots now? (y/n)"
if ($destroyInfra -eq "y") {

    # Proceeds with destroying infrastructure
    Write-Output "* Destroying the provisioned infrastructure..."
    & terraform destroy -auto-approve `
        -var "ami_id=$amiId" `
        -var "aws_region=$awsRegion" `
        -var "domain_name=$domainName" `
        -var "ssl_certificate_arn=$SSL_CERTIFICATE_ARN" `
        -var "aws_key_pair_name=$keyName" `
        -var "initial_private_key_path=$keyPath"

    # Deregisters the AMI ID with retry logic
    $maxRetries = 5
    $retryCount = 0
    $deregistered = $false

    while (-not $deregistered -and $retryCount -lt $maxRetries) {
        try {
            Write-Output ""
            Write-Output "* Attempting to deregister AMI (Attempt: $($retryCount + 1))..."
            aws ec2 deregister-image --image-id $AmiId
            Write-Output "  + AMI deregistered successfully."
            $deregistered = $true
        } catch {
            Write-Output "  ! Error: Failed to deregister AMI. Retrying in 10 seconds..."
            Start-Sleep -Seconds 10
            $retryCount++
        }
    }

    if (-not $deregistered) {
        Write-Output "  ! Failed to deregister AMI after multiple attempts."
        exit 1
    }

    # Waits for the deregistration to complete
    Write-Output ""
    Write-Output "* Waiting for AMI to deregister fully..."
    Start-Sleep -Seconds 30

    # Deletes associated snapshots with retry logic
    $snapshotIds = aws ec2 describe-snapshots --owner-ids self --query "Snapshots[*].SnapshotId" --output text
    foreach ($snapshotId in $snapshotIds) {
        $snapshotDeleted = $false
        $retryCount = 0
        while (-not $snapshotDeleted -and $retryCount -lt $maxRetries) {
            try {
                Write-Output ""
                Write-Output "* Attempting to delete snapshot $snapshotId (Attempt: $($retryCount + 1))..."
                aws ec2 delete-snapshot --snapshot-id $snapshotId
                Write-Output "  + Snapshot deleted successfully."
                $snapshotDeleted = $true
            } catch {
                Write-Output "  ! Error: Failed to delete snapshot $snapshotId. Retrying in 10 seconds..."
                Start-Sleep -Seconds 10
                $retryCount++
            }
        }

        if (-not $snapshotDeleted) {
            Write-Output "  ! Failed to delete snapshot $snapshotId after multiple attempts."
        }
    }

    # Deletes the imported key pair
    Write-Output ""
    Write-Output "* Deleting the imported key pair..."
    try {
        aws ec2 delete-key-pair --key-name $keyName > $null 2>&1
        Write-Output "  + Key pair '$keyName' deleted successfully."
    } catch {
        Write-Output ""
        Write-Output "  ! Error: Failed to delete the key pair '$keyName'. It may not exist or an error occurred."
    }

    # Deletes the ECR repository
    if ($REPO_NAME) {
        Write-Output ""
        Write-Output "* Deleting the ECR repository '$REPO_NAME'..."
        aws ecr delete-repository --repository-name $REPO_NAME --region $AWS_REGION --force > $null 2>&1
        Write-Output "  + ECR repository deleted."
    } else {
        Write-Output "  ! ECR repository name not found. Skipping ECR deletion."
    }

    # Fetches existing certificates for the domain using the domain name from vars_for_destroy.txt
    if (-not [string]::IsNullOrEmpty($domainName)) {
        $existingCerts = aws acm list-certificates --query "CertificateSummaryList[?DomainName=='$domainName'].CertificateArn" --output text

        # Deletes old certificates if they exist
        if ($existingCerts) {
            foreach ($certArn in $existingCerts) {
                Write-Output ""
                Write-Host "* Attempting to delete certificate: $certArn"
                try {
                    # Checks if the certificate is associated with other resources and disassociate if necessary
                    $associations = aws acm describe-certificate --certificate-arn $certArn --query 'Certificate.DomainValidationOptions[*].ValidationStatus' --output text
                    if ($associations -ne "SUCCESS") {
                        Write-Host "  ! Certificate $certArn is associated with resources. Disassociating..."
                        # Adds logic to disassociate the certificate if necessary
                    }
                    aws acm delete-certificate --certificate-arn $certArn
                    Write-Host "  + Certificate deleted successfully."
                } catch {
                    Write-Host "  ! Error deleting certificate: $certArn"
                }
            }
        } else {
            Write-Host " ! No certificates found for domain: $domainName"
        }
    } else {
        Write-Host " ! Domain name is not defined. Skipping certificate deletion..."
    }

    Write-Output ""
    Write-Output "+ Infrastructure and AMI deleted +"
}