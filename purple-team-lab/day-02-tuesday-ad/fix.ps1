# Fix script — completes the parts that failed in create-lab-users.ps1
$ErrorActionPreference = "Continue"
Import-Module ActiveDirectory
$domainDN = (Get-ADDomain).DistinguishedName

Write-Host "=== Creating service accounts ===" -ForegroundColor Cyan

$pw1 = ConvertTo-SecureString "MSSQLpassword1" -AsPlainText -Force
New-ADUser -SamAccountName "svc_mssql" -UserPrincipalName "svc_mssql@lab.local" -Name "svc_mssql" -DisplayName "Service: svc_mssql" -Path "OU=ServiceAccounts,$domainDN" -AccountPassword $pw1 -Enabled $true -PasswordNeverExpires $true
Set-ADUser -Identity "svc_mssql" -ServicePrincipalNames @{Add="MSSQLSvc/dc01.lab.local:1433"}
Write-Host "Created svc_mssql with MSSQL SPN" -ForegroundColor Green

$pw2 = ConvertTo-SecureString "IISservice2024" -AsPlainText -Force
New-ADUser -SamAccountName "svc_iis" -UserPrincipalName "svc_iis@lab.local" -Name "svc_iis" -DisplayName "Service: svc_iis" -Path "OU=ServiceAccounts,$domainDN" -AccountPassword $pw2 -Enabled $true -PasswordNeverExpires $true
Set-ADUser -Identity "svc_iis" -ServicePrincipalNames @{Add="HTTP/webapp.lab.local"}
Write-Host "Created svc_iis with HTTP SPN" -ForegroundColor Green

Write-Host ""
Write-Host "=== Creating AS-REP roastable user ===" -ForegroundColor Cyan
$pw3 = ConvertTo-SecureString "LegacyPass2020" -AsPlainText -Force
New-ADUser -SamAccountName "j.legacy" -UserPrincipalName "j.legacy@lab.local" -Name "Jane Legacy" -DisplayName "Jane Legacy (legacy app account)" -Path "OU=IT,$domainDN" -AccountPassword $pw3 -Enabled $true -PasswordNeverExpires $true
Set-ADAccountControl -Identity "j.legacy" -DoesNotRequirePreAuth $true
Write-Host "Created j.legacy as AS-REP roastable" -ForegroundColor Green

Write-Host ""
Write-Host "=== Promoting chernandez to Domain Admins ===" -ForegroundColor Cyan
Add-ADGroupMember -Identity "Domain Admins" -Members "chernandez"
Write-Host "Added chernandez to Domain Admins" -ForegroundColor Green

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
$total = (Get-ADUser -Filter *).Count
Write-Host "Total users in domain: $total"

Write-Host "Kerberoastable accounts:"
Get-ADUser -Filter * -Properties ServicePrincipalNames | Where-Object {$_.ServicePrincipalNames.Count -gt 0 -and $_.SamAccountName -ne "krbtgt"} | ForEach-Object { Write-Host "  - $($_.SamAccountName) -> $($_.ServicePrincipalNames -join ', ')" }

Write-Host "AS-REP roastable:"
Get-ADUser -Filter {DoesNotRequirePreAuth -eq $true} | ForEach-Object { Write-Host "  - $($_.SamAccountName)" }

Write-Host "Non-default Domain Admins:"
Get-ADGroupMember "Domain Admins" | Where-Object {$_.SamAccountName -ne "Administrator"} | ForEach-Object { Write-Host "  - $($_.SamAccountName)" }

Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Green
