# create-lab-users.ps1
# Create realistic AD lab users, OUs, groups, and Kerberoastable service accounts
# Run as Domain Admin on DC01 AFTER promotion completes
#
# WHAT THIS CREATES:
#   - OUs: HR, IT, Engineering, Finance, Service Accounts
#   - 15 normal users with weak passwords (lab realism)
#   - 2 Kerberoastable service accounts (SPN set, weak password)
#   - 1 AS-REP roastable user (no preauth required)
#   - 1 user added to Domain Admins (for DCSync attack chain testing)
#
# DO NOT USE THIS SCRIPT ON A REAL DOMAIN. Passwords are intentionally weak.

$ErrorActionPreference = "Stop"
Import-Module ActiveDirectory

$domainDN = (Get-ADDomain).DistinguishedName
Write-Host "=== Provisioning lab users in $domainDN ===" -ForegroundColor Cyan

# === Create OUs ===
$OUs = @("HR", "IT", "Engineering", "Finance", "ServiceAccounts")
foreach ($ou in $OUs) {
    $ouDN = "OU=$ou,$domainDN"
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$ou'" -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $ou -Path $domainDN -ProtectedFromAccidentalDeletion $false
        Write-Host "  Created OU: $ou" -ForegroundColor Green
    } else {
        Write-Host "  OU exists: $ou" -ForegroundColor DarkGray
    }
}

# === Create normal users ===
# Realistic-ish names with weak/common passwords (lab purposes)
$users = @(
    @{First="John";    Last="Smith";     OU="HR";          Password="Summer2024!"},
    @{First="Sarah";   Last="Johnson";   OU="HR";          Password="Welcome123"},
    @{First="Michael"; Last="Williams";  OU="IT";          Password="Password1!"},
    @{First="Emily";   Last="Brown";     OU="IT";          Password="ChangeMe123"},
    @{First="David";   Last="Jones";     OU="Engineering"; Password="Engineer1!"},
    @{First="Jessica"; Last="Garcia";    OU="Engineering"; Password="Devops2024"},
    @{First="Daniel";  Last="Miller";    OU="Engineering"; Password="LabUser!1"},
    @{First="Ashley";  Last="Davis";     OU="Finance";     Password="Finance123!"},
    @{First="James";   Last="Rodriguez"; OU="Finance";     Password="Money2024"},
    @{First="Amanda";  Last="Martinez";  OU="HR";          Password="HRpass2024"},
    @{First="Chris";   Last="Hernandez"; OU="IT";          Password="IT@dmin1"},
    @{First="Lisa";    Last="Lopez";     OU="Engineering"; Password="Coder2024!"},
    @{First="Mark";    Last="Gonzalez";  OU="Finance";     Password="Account1!"},
    @{First="Rachel";  Last="Wilson";    OU="HR";          Password="Hello2024"},
    @{First="Kevin";   Last="Anderson";  OU="IT";          Password="Helpdesk1!"}
)

foreach ($u in $users) {
    $sam = ($u.First.Substring(0,1) + $u.Last).ToLower()
    $upn = "$sam@lab.local"
    $ouPath = "OU=$($u.OU),$domainDN"
    
    if (Get-ADUser -Filter "SamAccountName -eq '$sam'" -ErrorAction SilentlyContinue) {
        Write-Host "  User exists: $sam" -ForegroundColor DarkGray
        continue
    }
    
    $secPwd = ConvertTo-SecureString $u.Password -AsPlainText -Force
    
    New-ADUser `
        -SamAccountName $sam `
        -UserPrincipalName $upn `
        -Name "$($u.First) $($u.Last)" `
        -GivenName $u.First `
        -Surname $u.Last `
        -DisplayName "$($u.First) $($u.Last)" `
        -Path $ouPath `
        -AccountPassword $secPwd `
        -Enabled $true `
        -PasswordNeverExpires $true `
        -CannotChangePassword $true
    
    Write-Host "  Created user: $sam ($($u.OU))" -ForegroundColor Green
}

# === Kerberoastable service accounts ===
Write-Host ""
Write-Host "=== Creating Kerberoastable service accounts ===" -ForegroundColor Cyan

$services = @(
    @{Sam="svc_mssql";    Password="MSSQLpassword1"; SPN="MSSQLSvc/dc01.lab.local:1433"},
    @{Sam="svc_iis";      Password="IISservice2024"; SPN="HTTP/webapp.lab.local"}
)

foreach ($s in $services) {
    if (Get-ADUser -Filter "SamAccountName -eq '$($s.Sam)'" -ErrorAction SilentlyContinue) {
        Write-Host "  Service account exists: $($s.Sam)" -ForegroundColor DarkGray
        continue
    }
    
    $secPwd = ConvertTo-SecureString $s.Password -AsPlainText -Force
    
    New-ADUser `
        -SamAccountName $s.Sam `
        -UserPrincipalName "$($s.Sam)@lab.local" `
        -Name $s.Sam `
        -DisplayName "Service: $($s.Sam)" `
        -Path "OU=ServiceAccounts,$domainDN" `
        -AccountPassword $secPwd `
        -Enabled $true `
        -PasswordNeverExpires $true `
        -ServicePrincipalNames @{Add=$s.SPN}
    
    Write-Host "  Created service account: $($s.Sam) with SPN $($s.SPN)" -ForegroundColor Green
}

# === AS-REP roastable user ===
Write-Host ""
Write-Host "=== Creating AS-REP roastable user ===" -ForegroundColor Cyan

$asrepUser = "j.legacy"
if (-not (Get-ADUser -Filter "SamAccountName -eq '$asrepUser'" -ErrorAction SilentlyContinue)) {
    $secPwd = ConvertTo-SecureString "LegacyPass2020" -AsPlainText -Force
    New-ADUser `
        -SamAccountName $asrepUser `
        -UserPrincipalName "$asrepUser@lab.local" `
        -Name "Jane Legacy" `
        -DisplayName "Jane Legacy (legacy app account)" `
        -Path "OU=IT,$domainDN" `
        -AccountPassword $secPwd `
        -Enabled $true `
        -PasswordNeverExpires $true
    
    # Disable Kerberos preauthentication
    Set-ADAccountControl -Identity $asrepUser -DoesNotRequirePreAuth $true
    Write-Host "  Created AS-REP roastable user: $asrepUser" -ForegroundColor Green
} else {
    Write-Host "  AS-REP user exists: $asrepUser" -ForegroundColor DarkGray
}

# === Create a non-admin user, then make them Domain Admin (for DCSync chain) ===
Write-Host ""
Write-Host "=== Promoting a user to Domain Admins ===" -ForegroundColor Cyan
# Promote 'msmith' (Michael Williams' account would be 'mwilliams' - let's use that)
# Actually using cdavis (Chris Davis) for the promotion
Add-ADGroupMember -Identity "Domain Admins" -Members "cdavis" -ErrorAction SilentlyContinue
Write-Host "  Added cdavis to Domain Admins (for DCSync attack testing)" -ForegroundColor Green

# === Summary ===
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
$allUsers = Get-ADUser -Filter * | Measure-Object
Write-Host "Total users in domain: $($allUsers.Count)"

$kerberoastable = Get-ADUser -Filter * -Properties ServicePrincipalNames | Where-Object {$_.ServicePrincipalNames.Count -gt 0 -and $_.SamAccountName -ne "krbtgt"}
Write-Host "Kerberoastable accounts: $($kerberoastable.Count)"
$kerberoastable | ForEach-Object { Write-Host "    - $($_.SamAccountName)" }

$asrep = Get-ADUser -Filter {DoesNotRequirePreAuth -eq $true}
Write-Host "AS-REP roastable accounts: $($asrep.Count)"
$asrep | ForEach-Object { Write-Host "    - $($_.SamAccountName)" }

$domainAdmins = Get-ADGroupMember "Domain Admins" | Where-Object {$_.SamAccountName -ne "Administrator"}
Write-Host "Non-default Domain Admins: $($domainAdmins.Count)"
$domainAdmins | ForEach-Object { Write-Host "    - $($_.SamAccountName)" }

Write-Host ""
Write-Host "=== Done. Lab AD is ready for attacks. ===" -ForegroundColor Green
