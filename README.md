# Professional Kali Linux WSL 2 Installer

**Fully automated, production-grade installation of Kali Linux on Windows Subsystem for Linux 2 (WSL 2)**

![License](https://img.shields.io/badge/License-MIT-blue.svg)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)
![Windows](https://img.shields.io/badge/Windows-10%20%2F%2011-blue.svg)

---

## 🚀 Quick Start

### One-liner Installation (Run as Administrator in PowerShell)

```powershell
irm https://raw.githubusercontent.com/oxyz01/kali-wsl-installer/main/install-kali.ps1 | iex
```

### Local Installation

```powershell
# Allow script execution for this session
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Run the installer
& ".\install-kali.ps1"
```

---

## ✨ Features

### Core Installation
- ✅ **Automated WSL 2 Setup** - Enables all required Windows features automatically
- ✅ **Official Kali Linux** - Downloads directly from Microsoft's official Kali package
- ✅ **Zero Interaction** - Unattended installation with sensible defaults
- ✅ **Error Recovery** - Comprehensive error handling and rollback capabilities

### Professional Features
- 📊 **Detailed Logging** - Full installation logs with timestamps and status levels
- 🔄 **Validation Checks** - Pre-flight system requirements verification
- 🛠️ **Configurable Installation** - Optional tools and features
- 🚀 **Performance Optimized** - Quiet downloads, parallel operations where possible
- 📈 **Progress Tracking** - Clear visual feedback throughout installation
- 🔙 **Intelligent Rollback** - Automatic cleanup on failure

### Post-Installation Tools
- **Base Tools**: curl, wget, git, build-essential, net-tools, vim, nano, htop, tmux, jq
- **SSH Server**: Pre-configured OpenSSH with remote root access option
- **Pentesting Tools**: nmap, masscan, aircrack-ng, sqlmap, nikta, hashcat, hydra, john

---

## 📋 Requirements

| Requirement | Details |
|---|---|
| **OS** | Windows 10 Build 18362+ or Windows 11 |
| **Privileges** | Administrator access required |
| **Disk Space** | Minimum 15GB free (30GB recommended) |
| **RAM** | 4GB minimum (8GB+ recommended) |
| **Internet** | Required for downloading packages |

---

## 🔧 Advanced Usage

### Custom Parameters

```powershell
# Minimal installation (no extra tools)
$params = @{
    DistributionName = "kali-linux"
    InstallTools     = $false
    EnableSSH        = $false
}
irm https://raw.githubusercontent.com/oxyz01/kali-wsl-installer/main/install-kali.ps1 | iex

# Full installation with custom distribution name
$params = @{
    DistributionName = "kali-custom"
    InstallTools     = $true
    EnableSSH        = $true
}
```

### Script Parameters

```powershell
-DistributionName <string>
    Name of the WSL distribution
    Default: "kali-linux"

-InstallPath <string>
    Installation path for Kali Linux
    Default: "%USERPROFILE%\AppData\Local\Kali"

-EnableSSH <bool>
    Install and enable SSH server
    Default: $true

-InstallTools <bool>
    Install additional pentesting tools
    Default: $true

-LogFile <string>
    Custom log file path
    Default: "%TEMP%\kali-install-YYYYMMDD_HHMMSS.log"
```

---

## 📖 After Installation

### Launch Kali Linux

```powershell
# Open Kali terminal
wsl -d kali-linux

# Run as root
wsl -d kali-linux --user root -e bash

# Run specific commands
wsl -d kali-linux -e apt list --upgradable
```

### Manage WSL Distributions

```powershell
# List all distributions
wsl -l -v

# Set Kali as default
wsl --set-default kali-linux

# Check Kali version
wsl -d kali-linux -e lsb_release -a

# Uninstall (if needed)
wsl --unregister kali-linux
```

### Create Non-Root User

```powershell
wsl -d kali-linux --user root -e bash -c "useradd -m -s /bin/bash kaliuser"
wsl -d kali-linux --user root -e bash -c "passwd kaliuser"
```

### Enable SSH Server

```powershell
wsl -d kali-linux --user root -e bash -c "systemctl start ssh"
wsl -d kali-linux --user root -e bash -c "systemctl enable ssh"
```

---

## 🐛 Troubleshooting

### "Run as Administrator" Error
```powershell
# Use the -RunAsAdministrator flag
Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -Command `". '$PSScriptRoot\install-kali.ps1'`"" -Verb RunAs
```

### WSL 2 Not Available
```powershell
# Check Windows version
[System.Environment]::OSVersion.Version

# Verify WSL is enabled
Get-WindowsOptionalFeature -FeatureName Microsoft-Windows-Subsystem-Linux -Online

# Enable WSL manually
Enable-WindowsOptionalFeature -FeatureName Microsoft-Windows-Subsystem-Linux -Online
Enable-WindowsOptionalFeature -FeatureName VirtualMachinePlatform -Online
```

### Disk Space Issues
- Kali Linux requires ~15GB minimum
- Additional tools may require another 5-10GB
- Check free space: `Get-PSDrive -Name C`

### Installation Hangs
- Check internet connectivity
- Verify administrator privileges
- Check log file for details (path shown during installation)
- Try running the script again

---

## 📝 Logging

Installation logs are automatically created in:
```
%TEMP%\kali-install-YYYYMMDD_HHMMSS.log
```

### Log Levels
- `SUCCESS` - Operation completed successfully
- `ERROR` - Operation failed
- `WARNING` - Non-critical issue or recovery action
- `INFO` - General information
- `VERBOSE` - Detailed diagnostic information

### View Logs
```powershell
# View real-time logs
Get-Content $env:TEMP\kali-install-*.log -Tail 50 -Wait

# Search logs for errors
Select-String "ERROR" $env:TEMP\kali-install-*.log
```

---

## 🔒 Security Notes

- Script requires administrator privileges (necessary for WSL installation)
- Downloads official Kali Linux package from Microsoft
- SSH server defaults to root access—create non-root users for production
- Always review scripts before execution from the internet
- Keep WSL and Kali Linux updated: `apt update && apt upgrade`

---

## 📊 Installation Performance

Typical installation times (varies by system and internet speed):

| Phase | Duration |
|---|---|
| WSL 2 Setup | 2-5 minutes |
| Distribution Download | 5-10 minutes |
| Initial Setup | 3-5 minutes |
| **Total** | **10-20 minutes** |

---

## 🔄 Uninstallation

```powershell
# Remove Kali Linux distribution
wsl --unregister kali-linux

# Optional: Disable WSL features
Disable-WindowsOptionalFeature -FeatureName Microsoft-Windows-Subsystem-Linux -Online
Disable-WindowsOptionalFeature -FeatureName VirtualMachinePlatform -Online
```

---

## 📚 Official Resources

- [Kali Linux Official](https://www.kali.org/)
- [Kali Linux on WSL](https://www.kali.org/docs/wsl/)
- [Windows Subsystem for Linux Docs](https://docs.microsoft.com/en-us/windows/wsl/)
- [Microsoft Kali Linux Package](https://aka.ms/wsl-kali-linux-new)

---

## 📄 License

MIT License - See LICENSE file for details

---

## 🤝 Contributing

Found an issue? Have a suggestion? Feel free to open an issue or submit a pull request.

---

## 💡 Tips & Tricks

### Faster Access
```powershell
# Add to PowerShell profile for quick access
Set-Alias wk 'wsl -d kali-linux -e bash'
```

### WSL Configuration
Create `~/.wslconfig` for advanced options:
```ini
[wsl2]
memory=4GB
processors=4
swap=2GB
localhostForwarding=true
```

### Performance Tips
- Run `wsl --update` monthly
- Keep Kali packages updated
- Use SSD storage for WSL
- Limit memory allocation appropriately

---

**Last Updated:** April 2026  
**Script Version:** 1.0.0  
**Status:** Production Ready ✅
