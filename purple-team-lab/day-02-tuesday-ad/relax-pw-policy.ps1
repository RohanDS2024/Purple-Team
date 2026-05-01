# Relax default domain password policy for lab use only
# DO NOT do this in production
$ErrorActionPreference = "Stop"

Write-Host "=== Current policy ===" -ForegroundColor Cyan
Get-ADDefaultDomainPasswordPolicy | Format-List ComplexityEnabled, MinPasswordLength, PasswordHistoryCount, MaxPasswordAge, MinPasswordAge, LockoutThreshold

Write-Host ""
Write-Host "=== Relaxing policy for lab ===" -ForegroundColor Yellow
Set-ADDefaultDomainPasswordPolicy -Identity lab.local `
    -ComplexityEnabled $false `
    -MinPasswordLength 4 `
    -PasswordHistoryCount 0 `
    -MinPasswordAge "0.00:00:00" `
    -MaxPasswordAge "0.00:00:00" `
    -LockoutThreshold 0

Write-Host ""
Write-Host "=== New policy ===" -ForegroundColor Cyan
Get-ADDefaultDomainPasswordPolicy | Format-List ComplexityEnabled, MinPasswordLength, PasswordHistoryCount, MaxPasswordAge, MinPasswordAge, LockoutThreshold

Write-Host ""
Write-Host "Done. Now re-run fix-passwords.ps1 to set the lab passwords." -ForegroundColor Green
