# Kali Linux Unattended WSL 2 Installation Script
# Run as Administrator

param(
    [string]$DistributionName = "kali-linux",
    [string]$InstallPath = "$env:USERPROFILE\AppData\Local\Kali"
)

# Check if running as administrator
$isAdmin = [Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains "S-1-5-32-544"
if (-not $isAdmin) {
    Write-Error "This script must be run as Administrator"
    exit 1
}

# Check Windows version (requires Windows 10 Build 18362 or later, or Windows 11)
$osVersion = [System.Environment]::OSVersion.Version
if ($osVersion.Major -lt 10 -or ($osVersion.Major -eq 10 -and $osVersion.Build -lt 18362)) {
    Write-Error "Windows 10 Build 18362 or later (or Windows 11) is required"
    exit 1
}

Write-Host "Installing Kali Linux on WSL 2..." -ForegroundColor Green

# Enable WSL 2 if not already enabled
Write-Host "Enabling WSL 2 features..." -ForegroundColor Yellow
try {
    wsl --install --no-launch --no-distribution 2>$null
    Write-Host "WSL 2 features enabled" -ForegroundColor Green
} catch {
    Write-Host "WSL 2 may already be enabled" -ForegroundColor Yellow
}

# Install Kali Linux from Microsoft Store (recommended)
Write-Host "Installing Kali Linux..." -ForegroundColor Yellow
& "powershell" -NoProfile -Command {
    # Alternative method: use Windows App or direct download
    # For headless/unattended, we can use the appx package

    $kalidl = "https://aka.ms/wsl-kali-linux-new"
    $appx = "$env:TEMP\kali.appx"

    Write-Host "Downloading Kali Linux package..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $kalidl -OutFile $appx -UseBasicParsing

    Write-Host "Installing Kali Linux package..." -ForegroundColor Cyan
    Add-AppxPackage -Path $appx

    Remove-Item $appx -Force
}

# Wait for installation to complete
Write-Host "Waiting for installation to complete..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Initialize Kali Linux distribution
Write-Host "Initializing Kali Linux distribution..." -ForegroundColor Yellow
& wsl -d $DistributionName --user root -e bash -c "echo 'Initialized'"

# Set as default if desired
Write-Host "Setting $DistributionName as default WSL 2 distribution..." -ForegroundColor Yellow
& wsl --set-default $DistributionName
& wsl --set-version $DistributionName 2

# Run initial setup in the distribution
Write-Host "Running unattended system setup..." -ForegroundColor Yellow
$setupScript = @'
#!/bin/bash
set -e

echo "Updating Kali Linux..."
apt-get update -qq
apt-get upgrade -y -qq

echo "Installing essential tools..."
apt-get install -y -qq \
    curl \
    wget \
    git \
    build-essential \
    net-tools \
    iputils-ping \
    dnsutils \
    vim \
    nano

echo "Kali Linux WSL 2 installation complete!"
ls -la / > /dev/null
'@

$setupScript | & wsl -d $DistributionName --user root -e bash

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Kali Linux WSL 2 Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "To start using Kali Linux:" -ForegroundColor Cyan
Write-Host "  wsl -d $DistributionName" -ForegroundColor White
Write-Host ""
Write-Host "To run commands directly:" -ForegroundColor Cyan
Write-Host "  wsl -d $DistributionName -e <command>" -ForegroundColor White
Write-Host ""
Write-Host "To set default user (optional):" -ForegroundColor Cyan
Write-Host "  wsl -d $DistributionName -u root useradd -m -s /bin/bash username" -ForegroundColor White
