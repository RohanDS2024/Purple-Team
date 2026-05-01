# Set valid complex passwords on accounts that exist but are disabled
$ErrorActionPreference = "Continue"

# Service account 1
$pw1 = ConvertTo-SecureString "MSSQLp@ssw0rd1!" -AsPlainText -Force
Set-ADAccountPassword -Identity "svc_mssql" -Reset -NewPassword $pw1
Enable-ADAccount -Identity "svc_mssql"
Set-ADUser -Identity "svc_mssql" -PasswordNeverExpires $true
Write-Host "Reset password and enabled: svc_mssql" -ForegroundColor Green

# Service account 2
$pw2 = ConvertTo-SecureString "IISservice2024!" -AsPlainText -Force
Set-ADAccountPassword -Identity "svc_iis" -Reset -NewPassword $pw2
Enable-ADAccount -Identity "svc_iis"
Set-ADUser -Identity "svc_iis" -PasswordNeverExpires $true
Write-Host "Reset password and enabled: svc_iis" -ForegroundColor Green

# AS-REP roastable user
$pw3 = ConvertTo-SecureString "LegacyP@ss2020!" -AsPlainText -Force
Set-ADAccountPassword -Identity "j.legacy" -Reset -NewPassword $pw3
Enable-ADAccount -Identity "j.legacy"
Set-ADUser -Identity "j.legacy" -PasswordNeverExpires $true
Set-ADAccountControl -Identity "j.legacy" -DoesNotRequirePreAuth $true
Write-Host "Reset password, enabled, and set no-preauth: j.legacy" -ForegroundColor Green

Write-Host ""
Write-Host "=== Final verification ===" -ForegroundColor Cyan
Get-ADUser svc_mssql, svc_iis, j.legacy -Properties Enabled, ServicePrincipalNames, DoesNotRequirePreAuth | Format-Table Name, Enabled, ServicePrincipalNames, DoesNotRequirePreAuth -AutoSize
Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Green
