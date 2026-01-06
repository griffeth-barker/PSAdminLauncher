# Testing
To test the source script, you'll need the `Pester` PowerShell module.  
  
Invoke the tests:
```powershell
# Ensure Pester v5+ is installed:
# Install-Module Pester -Scope CurrentUser -Force

# Run tests
Invoke-Pester "$pwd\tests\PSAdminLauncher.Tests.ps1" -Output Detail
```