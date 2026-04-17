# Minimal Kali Linux WSL 2 installer - can be piped with irm | iex
$ErrorActionPreference = "Stop"

if (-not ([Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains "S-1-5-32-544")) {
    Write-Error "Run as Administrator"; exit 1
}

Write-Host "Installing Kali Linux on WSL 2..." -ForegroundColor Green

# Enable WSL 2
wsl --install --no-launch --no-distribution 2>$null | Out-Null

# Install Kali
$appx = "$env:TEMP\kali.appx"
Write-Host "Downloading..." -ForegroundColor Yellow
Invoke-WebRequest -Uri "https://aka.ms/wsl-kali-linux-new" -OutFile $appx -UseBasicParsing
Write-Host "Installing..." -ForegroundColor Yellow
Add-AppxPackage -Path $appx
Remove-Item $appx -Force

# Initialize
Write-Host "Initializing..." -ForegroundColor Yellow
Start-Sleep -Seconds 5
wsl -d kali-linux --user root -e bash -c "apt-get update -qq && apt-get upgrade -y -qq && echo 'Complete!'"

Write-Host "Kali Linux is ready! Run: wsl -d kali-linux" -ForegroundColor Green
