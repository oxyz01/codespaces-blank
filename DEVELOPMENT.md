# Development Guide

## Project Structure

```
codespaces-blank/
├── install-kali.ps1          # Main installation script
├── README.md                  # User documentation
├── CHANGELOG.md               # Version history
├── LICENSE                    # MIT License
├── DEVELOPMENT.md             # This file
└── .gitignore                # Git ignore rules
```

## Building & Testing

### Local Testing

```powershell
# Test syntax
$syntaxTest = Get-Content .\install-kali.ps1 | Invoke-Expression -ErrorVariable e
if ($e) { Write-Error "Syntax error: $e" }

# Test with verbose output
Set-PSDebug -Trace 1
& ".\install-kali.ps1" -Verbose

# Test remote execution
irm https://raw.githubusercontent.com/oxyz01/codespaces-blank/main/install-kali.ps1 | iex
```

### Parameter Testing

```powershell
# Test with custom parameters
& ".\install-kali.ps1" -DistributionName "kali-test" -InstallTools $false -EnableSSH $false

# Test logging
$logPath = "C:\Temp\test-install.log"
& ".\install-kali.ps1" -LogFile $logPath
Get-Content $logPath
```

## Code Quality Standards

### PowerShell Best Practices
- Use explicit error handling (`trap`, `try-catch`)
- Explicit parameter types
- Comment complex operations
- Use consistent naming conventions (camelCase for variables, PascalCase for functions)
- Suppress unnecessary output (`| Out-Null`, `-ErrorAction SilentlyContinue`)

### Script Structure
1. Requires statement
2. Script documentation (synopsis, description, parameters, examples)
3. Configuration section
4. Function definitions
5. Main execution block

### Error Handling
- All external commands wrapped in try-catch
- Meaningful error messages
- Rollback on failure
- Detailed logging

## Adding New Features

### Adding Installation Steps

1. Create a new function following the pattern:
```powershell
function Install-NewFeature {
    Write-Header "Installing New Feature"
    
    try {
        Write-Log "Doing something..."
        # Installation commands
        Write-Log "Feature installed successfully" "SUCCESS"
    }
    catch {
        Write-Log "Failed to install feature: $_" "ERROR"
        throw $_
    }
}
```

2. Add to `Main()` function in execution order

3. Add documentation to README.md

4. Update CHANGELOG.md

### Adding Parameters

1. Add to `param()` block with type and default
2. Add help documentation with `.PARAMETER` section
3. Implement logic based on parameter
4. Document in README.md

## Versioning

Uses semantic versioning: MAJOR.MINOR.PATCH

- **MAJOR**: Breaking changes or complete rewrites
- **MINOR**: New features or significant improvements
- **PATCH**: Bug fixes and minor updates

Update version in:
- Script help documentation
- CHANGELOG.md
- This file

## Git Workflow

### Commits
- Use clear, descriptive commit messages
- Reference issues when applicable
- Include Co-authored-by trailer for Copilot contributions

### Branches
- Main branch is stable/production
- Use feature branches for development
- Merge via pull request with review

## Troubleshooting Development

### Script Won't Execute
```powershell
# Check execution policy
Get-ExecutionPolicy

# Set to Bypass for testing
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
```

### Remote Execution Issues
```powershell
# Test URL accessibility
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/oxyz01/codespaces-blank/main/install-kali.ps1" -UseBasicParsing -Method Head

# Test parsing
$script = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/oxyz01/codespaces-blank/main/install-kali.ps1"
$script | Invoke-Expression -ErrorVariable e
```

### WSL Testing Challenges
- Requires Administrator mode
- May need system restart for changes
- Test on clean VM if possible
- Always back up system state before testing

## Performance Optimization

- Suppress verbose output where not needed: `$ProgressPreference = "SilentlyContinue"`
- Batch WSL commands to reduce sub-process overhead
- Use `-ErrorAction SilentlyContinue` for expected non-critical errors
- Minimize network calls

## Security Considerations

- Validate all user inputs
- Don't store credentials in script
- Use HTTPS for all remote operations
- Verify package sources
- Keep script permissions restricted
- Review external dependencies

## Support & Issues

- Check existing issues before reporting
- Include full error messages and logs
- Specify Windows version and build number
- Include PowerShell version: `$PSVersionTable.PSVersion`
- Describe steps to reproduce

## Release Checklist

- [ ] Update version number
- [ ] Update CHANGELOG.md
- [ ] Test on clean Windows 10 and Windows 11
- [ ] Test with various parameter combinations
- [ ] Verify remote execution works
- [ ] Review error handling and logging
- [ ] Update documentation if needed
- [ ] Commit and tag release
- [ ] Push to GitHub
- [ ] Create GitHub release notes
