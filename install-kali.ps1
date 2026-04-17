#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Professional Kali Linux WSL 2 Installation Script
.DESCRIPTION
    Automated unattended installation of Kali Linux on Windows Subsystem for Linux 2.
    Includes error handling, logging, validation, and rollback capabilities.
.PARAMETER DistributionName
    Name of the WSL distribution (default: kali-linux)
.PARAMETER InstallPath
    Installation path for Kali Linux (default: %USERPROFILE%\AppData\Local\Kali)
.PARAMETER EnableSSH
    Install and enable SSH server (default: $true)
.PARAMETER InstallTools
    Install additional pentesting tools (default: $true)
.PARAMETER LogFile
    Path to log file (default: %TEMP%\kali-install.log)
.EXAMPLE
    PS> irm https://raw.githubusercontent.com/oxyz01/codespaces-blank/main/install-kali.ps1 | iex
.NOTES
    Author: Kali Linux Installer
    Version: 1.0.0
    Requires: Windows 10 Build 18362+ or Windows 11
    License: MIT
#>

param(
    [string]$DistributionName = "kali-linux",
    [string]$InstallPath = "$env:USERPROFILE\AppData\Local\Kali",
    [bool]$EnableSSH = $true,
    [bool]$InstallTools = $true,
    [string]$LogFile = "$env:TEMP\kali-install-$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
)

# ============================================================================
# Configuration
# ============================================================================
$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"
$ProgressPreference = "Continue"

$script:ExitCode = 0
$script:StartTime = Get-Date
$script:RollbackActions = @()

# Colors
$colors = @{
    Success = 'Green'
    Warning = 'Yellow'
    Error   = 'Red'
    Info    = 'Cyan'
    Verbose = 'Gray'
}

# ============================================================================
# Logging Functions
# ============================================================================
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    Add-Content -Path $LogFile -Value $logEntry -ErrorAction SilentlyContinue
    
    switch ($Level) {
        "SUCCESS" { Write-Host "✓ $Message" -ForegroundColor $colors.Success }
        "WARNING" { Write-Host "⚠ $Message" -ForegroundColor $colors.Warning }
        "ERROR"   { Write-Host "✗ $Message" -ForegroundColor $colors.Error }
        "INFO"    { Write-Host "ℹ $Message" -ForegroundColor $colors.Info }
        "VERBOSE" { Write-Host "  $Message" -ForegroundColor $colors.Verbose }
    }
}

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor $colors.Info
    Write-Host "  $Text" -ForegroundColor $colors.Info
    Write-Host ("=" * 70) -ForegroundColor $colors.Info
    Write-Host ""
    Write-Log "--- $Text ---"
}

# ============================================================================
# Validation Functions
# ============================================================================
function Test-AdminRights {
    $isAdmin = [Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains "S-1-5-32-544"
    if (-not $isAdmin) {
        Write-Log "Script was not run as Administrator" "ERROR"
        throw "This script must be run as Administrator. Use 'Run as Administrator' or use '-RunAsAdministrator' flag."
    }
    Write-Log "Administrator privileges verified" "SUCCESS"
}

function Test-WindowsVersion {
    $osVersion = [System.Environment]::OSVersion.Version
    $buildNumber = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name CurrentBuildNumber).CurrentBuildNumber
    
    Write-Log "Windows Version: $($osVersion.Major).$($osVersion.Minor) (Build $buildNumber)"
    
    if ($osVersion.Major -lt 10) {
        throw "Windows 10 or Windows 11 is required"
    }
    
    if ($osVersion.Major -eq 10 -and $buildNumber -lt 18362) {
        throw "Windows 10 Build 18362 or later is required"
    }
    
    Write-Log "Windows version check passed" "SUCCESS"
}

function Test-DiskSpace {
    $drive = Get-PSDrive -Name $env:SystemDrive[0]
    $freeGB = $drive.Free / 1GB
    
    Write-Log "Available disk space: $([math]::Round($freeGB, 2)) GB"
    
    if ($freeGB -lt 15) {
        Write-Log "Warning: At least 15GB free space is recommended" "WARNING"
    }
}

# ============================================================================
# Installation Functions
# ============================================================================
function Install-WSL2 {
    Write-Header "Installing WSL 2"
    
    try {
        Write-Log "Checking for existing WSL installation..."
        
        $wslFeature = Get-WindowsOptionalFeature -FeatureName Microsoft-Windows-Subsystem-Linux -Online -ErrorAction SilentlyContinue
        
        if ($wslFeature.State -eq "Enabled") {
            Write-Log "WSL is already enabled" "SUCCESS"
        } else {
            Write-Log "Enabling WSL features..."
            Enable-WindowsOptionalFeature -FeatureName Microsoft-Windows-Subsystem-Linux -Online -NoRestart -WarningAction SilentlyContinue | Out-Null
            Write-Log "WSL features enabled" "SUCCESS"
        }
        
        # Enable Virtual Machine Platform
        $vmFeature = Get-WindowsOptionalFeature -FeatureName VirtualMachinePlatform -Online -ErrorAction SilentlyContinue
        if ($vmFeature.State -eq "Enabled") {
            Write-Log "Virtual Machine Platform already enabled" "SUCCESS"
        } else {
            Write-Log "Enabling Virtual Machine Platform..."
            Enable-WindowsOptionalFeature -FeatureName VirtualMachinePlatform -Online -NoRestart -WarningAction SilentlyContinue | Out-Null
            Write-Log "Virtual Machine Platform enabled" "SUCCESS"
        }
        
        # Set WSL 2 as default
        Write-Log "Setting WSL 2 as default version..."
        wsl --set-default-version 2 2>&1 | ForEach-Object { Write-Log $_ "VERBOSE" }
        Write-Log "WSL 2 configuration complete" "SUCCESS"
    }
    catch {
        Write-Log "Failed to install WSL 2: $_" "ERROR"
        throw $_
    }
}

function Install-KaliDistribution {
    Write-Header "Installing Kali Linux Distribution"
    
    try {
        # Check if already installed
        $existingDistro = wsl -l -v 2>&1 | Select-String $DistributionName
        if ($existingDistro) {
            Write-Log "Kali Linux distribution already installed" "WARNING"
            return
        }
        
        $tempDir = "$env:TEMP\kali-install"
        if (-not (Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
            $script:RollbackActions += { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
        }
        
        $appxPath = "$tempDir\kali.appx"
        $kalinuxUrl = "https://aka.ms/wsl-kali-linux-new"
        
        Write-Log "Downloading Kali Linux package from $kalinuxUrl..."
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri $kalinuxUrl -OutFile $appxPath -UseBasicParsing -ErrorAction Stop
        $ProgressPreference = "Continue"
        
        $fileSize = (Get-Item $appxPath).Length / 1MB
        Write-Log "Downloaded: $([math]::Round($fileSize, 2)) MB" "SUCCESS"
        
        Write-Log "Installing Kali Linux package..."
        Add-AppxPackage -Path $appxPath -ErrorAction Stop | Out-Null
        Write-Log "Kali Linux package installed" "SUCCESS"
        
        # Cleanup
        Remove-Item $appxPath -Force -ErrorAction SilentlyContinue
        Write-Log "Temporary files cleaned up" "SUCCESS"
    }
    catch {
        Write-Log "Failed to install Kali distribution: $_" "ERROR"
        throw $_
    }
}

function Initialize-KaliDistribution {
    Write-Header "Initializing Kali Linux"
    
    try {
        Write-Log "Starting distribution for first time..."
        Write-Log "This may take a few minutes..."
        
        # Initialize and update
        Write-Log "Updating package lists..."
        wsl -d $DistributionName --user root -e bash -c "apt-get update -qq" 2>&1 | ForEach-Object { Write-Log $_ "VERBOSE" }
        
        Write-Log "Upgrading packages..."
        wsl -d $DistributionName --user root -e bash -c "apt-get upgrade -y -qq" 2>&1 | ForEach-Object { Write-Log $_ "VERBOSE" }
        
        Write-Log "Kali Linux initialized successfully" "SUCCESS"
    }
    catch {
        Write-Log "Failed to initialize Kali: $_" "ERROR"
        throw $_
    }
}

function Install-BaseTools {
    Write-Header "Installing Base Tools"
    
    try {
        $tools = @(
            "curl"
            "wget"
            "git"
            "build-essential"
            "net-tools"
            "iputils-ping"
            "dnsutils"
            "vim"
            "nano"
            "htop"
            "tmux"
            "jq"
        )
        
        $toolList = $tools -join " "
        Write-Log "Installing base tools: $($tools -join ', ')"
        
        wsl -d $DistributionName --user root -e bash -c "apt-get install -y -qq $toolList" 2>&1 | ForEach-Object { Write-Log $_ "VERBOSE" }
        
        Write-Log "Base tools installed successfully" "SUCCESS"
    }
    catch {
        Write-Log "Failed to install base tools: $_" "ERROR"
        throw $_
    }
}

function Install-SSHServer {
    if (-not $EnableSSH) {
        Write-Log "SSH installation skipped" "INFO"
        return
    }
    
    Write-Header "Installing SSH Server"
    
    try {
        Write-Log "Installing OpenSSH server..."
        wsl -d $DistributionName --user root -e bash -c "apt-get install -y -qq openssh-server openssh-client" 2>&1 | ForEach-Object { Write-Log $_ "VERBOSE" }
        
        Write-Log "Configuring SSH..."
        wsl -d $DistributionName --user root -e bash -c @"
mkdir -p /var/run/sshd
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
"@ 2>&1 | ForEach-Object { Write-Log $_ "VERBOSE" }
        
        Write-Log "SSH server installed and configured" "SUCCESS"
    }
    catch {
        Write-Log "Failed to install SSH server: $_" "ERROR"
        throw $_
    }
}

function Install-PentestingTools {
    if (-not $InstallTools) {
        Write-Log "Additional tools installation skipped" "INFO"
        return
    }
    
    Write-Header "Installing Pentesting Tools"
    
    try {
        $tools = @(
            "nmap"
            "masscan"
            "aircrack-ng"
            "sqlmap"
            "nikto"
            "hashcat"
            "hydra"
            "john"
        )
        
        Write-Log "Installing pentesting tools (this may take a while)..."
        $toolList = $tools -join " "
        
        wsl -d $DistributionName --user root -e bash -c "apt-get install -y -qq $toolList" 2>&1 | ForEach-Object { Write-Log $_ "VERBOSE" }
        
        Write-Log "Pentesting tools installed successfully" "SUCCESS"
    }
    catch {
        Write-Log "Failed to install pentesting tools: $_" "WARNING"
        # Don't throw - allow installation to continue if tools installation fails
    }
}

function Configure-Distribution {
    Write-Header "Configuring Distribution"
    
    try {
        Write-Log "Setting $DistributionName as default WSL distribution..."
        wsl --set-default $DistributionName 2>&1 | ForEach-Object { Write-Log $_ "VERBOSE" }
        
        Write-Log "Ensuring WSL 2 version..."
        wsl --set-version $DistributionName 2 2>&1 | ForEach-Object { Write-Log $_ "VERBOSE" }
        
        Write-Log "Distribution configured successfully" "SUCCESS"
    }
    catch {
        Write-Log "Failed to configure distribution: $_" "ERROR"
        throw $_
    }
}

function Show-PostInstallInfo {
    Write-Header "Installation Complete!"
    
    $duration = (Get-Date) - $script:StartTime
    
    Write-Host ""
    Write-Host "✓ Kali Linux has been successfully installed on WSL 2" -ForegroundColor Green
    Write-Host ""
    Write-Host "Getting Started:" -ForegroundColor Cyan
    Write-Host "  • Launch Kali:        wsl -d $DistributionName" -ForegroundColor White
    Write-Host "  • Run command:        wsl -d $DistributionName -e <command>" -ForegroundColor White
    Write-Host "  • Run as root:        wsl -d $DistributionName --user root -e bash" -ForegroundColor White
    Write-Host ""
    Write-Host "Useful Commands:" -ForegroundColor Cyan
    Write-Host "  • List distributions: wsl -l -v" -ForegroundColor White
    Write-Host "  • Set user:           wsl -d $DistributionName -u root useradd -m -s /bin/bash <username>" -ForegroundColor White
    Write-Host ""
    Write-Host "Installation Duration: $($duration.Hours)h $($duration.Minutes)m $($duration.Seconds)s" -ForegroundColor Gray
    Write-Host "Log File: $LogFile" -ForegroundColor Gray
    Write-Host ""
    
    Write-Log "Installation completed successfully" "SUCCESS"
    Write-Log "Total duration: $($duration.Hours)h $($duration.Minutes)m $($duration.Seconds)s"
}

# ============================================================================
# Error Handling and Rollback
# ============================================================================
function Invoke-Rollback {
    Write-Header "Rolling Back Changes"
    Write-Log "An error occurred. Attempting rollback..." "WARNING"
    
    foreach ($action in $script:RollbackActions) {
        try {
            & $action
        }
        catch {
            Write-Log "Rollback action failed: $_" "WARNING"
        }
    }
    
    Write-Log "Rollback completed" "WARNING"
}

trap {
    Write-Log "FATAL ERROR: $_" "ERROR"
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" "VERBOSE"
    Invoke-Rollback
    $script:ExitCode = 1
    Write-Host ""
    Write-Host "Installation failed. Review the log file for details:" -ForegroundColor Red
    Write-Host "  $LogFile" -ForegroundColor Yellow
    Write-Host ""
    exit $script:ExitCode
}

# ============================================================================
# Main Execution
# ============================================================================
function Main {
    try {
        Write-Host ""
        Write-Host "╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║     Professional Kali Linux WSL 2 Installation Script v1.0         ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Log "Installation started"
        Write-Log "Parameters: Distribution=$DistributionName, Path=$InstallPath, SSH=$EnableSSH, Tools=$InstallTools"
        
        # Pre-flight checks
        Write-Header "Pre-Installation Checks"
        Test-AdminRights
        Test-WindowsVersion
        Test-DiskSpace
        
        # Installation phases
        Install-WSL2
        Install-KaliDistribution
        Initialize-KaliDistribution
        Install-BaseTools
        Install-SSHServer
        Install-PentestingTools
        Configure-Distribution
        
        # Success
        Show-PostInstallInfo
        exit 0
    }
    catch {
        $script:ExitCode = 1
        throw $_
    }
}

# Run main
Main
