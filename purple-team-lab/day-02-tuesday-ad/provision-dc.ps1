# provision-dc.ps1
# Promote a Windows Server 2022 to a Domain Controller for lab.local
# Run as Administrator on the target server (currently named DC01, IP 10.10.10.10)

# IMPORTANT: This script will reboot the server at the end.

$ErrorActionPreference = "Stop"

Write-Host "=== Lab DC Provisioning ===" -ForegroundColor Cyan

# Confirm we're on the right machine
if ($env:COMPUTERNAME -ne "DC01") {
    Write-Warning "Computer name is $env:COMPUTERNAME, expected DC01"
    $continue = Read-Host "Continue anyway? (y/N)"
    if ($continue -ne "y") { exit 1 }
}

# Confirm IP
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -like "Ethernet*"}).IPAddress
Write-Host "Current IP: $ip"
if ($ip -ne "10.10.10.10") {
    Write-Warning "IP is not 10.10.10.10 — DC promotion may fail or use wrong address."
    $continue = Read-Host "Continue anyway? (y/N)"
    if ($continue -ne "y") { exit 1 }
}

# Install AD DS role
Write-Host "[1/3] Installing AD DS role..." -ForegroundColor Yellow
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Install DNS role
Write-Host "[2/3] Installing DNS role..." -ForegroundColor Yellow
Install-WindowsFeature -Name DNS -IncludeManagementTools

# Promote to DC
Write-Host "[3/3] Promoting to DC for lab.local..." -ForegroundColor Yellow
Write-Host "You will be prompted for the DSRM (Directory Services Restore Mode) password."
Write-Host "Use the same password as your domain admin password for lab simplicity."
Write-Host ""

$dsrmPassword = Read-Host "DSRM password" -AsSecureString

Import-Module ADDSDeployment

Install-ADDSForest `
    -DomainName "lab.local" `
    -DomainNetbiosName "LAB" `
    -DomainMode "WinThreshold" `
    -ForestMode "WinThreshold" `
    -InstallDns:$true `
    -SafeModeAdministratorPassword $dsrmPassword `
    -DatabasePath "C:\Windows\NTDS" `
    -SysvolPath "C:\Windows\SYSVOL" `
    -LogPath "C:\Windows\NTDS" `
    -NoRebootOnCompletion:$false `
    -Force:$true

# Server reboots automatically after this point
