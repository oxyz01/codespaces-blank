# WSL Kali Installer

Automated unattended installation of Kali Linux on WSL 2 for Windows.

## Quick Start

### One-liner (Run as Administrator in PowerShell):
```powershell
irm https://raw.githubusercontent.com/YOUR_USERNAME/wsl-kali-installer/main/kali-install-minimal.ps1 | iex
```

### Or run locally:
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
& ".\kali-install-minimal.ps1"
```

## What it does

✅ Checks for Administrator privileges  
✅ Verifies Windows version (10/11)  
✅ Enables WSL 2 features  
✅ Downloads and installs Kali Linux from Microsoft's official source  
✅ Initializes the distribution  
✅ Runs unattended updates and installs base tools  
✅ Sets Kali as default WSL distro  

## After Installation

```powershell
# Launch Kali
wsl -d kali-linux

# Run commands directly
wsl -d kali-linux -e kali --help

# List distributions
wsl -l -v
```

## Files

- **kali-install-minimal.ps1** - Streamlined installer for one-liner usage
- **kali-wsl2-install.ps1** - Full-featured installer with additional options

## Requirements

- Windows 10 Build 18362+ or Windows 11
- Administrator privileges
- ~10GB free disk space

## License

MIT
