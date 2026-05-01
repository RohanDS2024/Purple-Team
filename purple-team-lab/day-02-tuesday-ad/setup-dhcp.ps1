# setup-dhcp.ps1 — Configure DHCP role on DC01 for the lab subnet
# Run as Administrator on DC01 (10.10.10.10) AFTER promotion to DC

$ErrorActionPreference = "Stop"

Write-Host "=== Step 1: Install DHCP role ===" -ForegroundColor Cyan
Install-WindowsFeature DHCP -IncludeManagementTools

Write-Host ""
Write-Host "=== Step 2: Authorize DHCP server in AD ===" -ForegroundColor Cyan
Add-DhcpServerInDC -DnsName "dc01.lab.local" -IPAddress 10.10.10.10
Write-Host "DHCP server authorized in AD" -ForegroundColor Green

Write-Host ""
Write-Host "=== Step 3: Bind DHCP only to the lab NIC ===" -ForegroundColor Cyan
$labNic = Get-NetIPAddress -IPAddress "10.10.10.10" -ErrorAction SilentlyContinue
if ($labNic) {
    # First disable all bindings, then enable only the lab NIC
    Get-DhcpServerv4Binding | ForEach-Object { Set-DhcpServerv4Binding -BindingState $false -InterfaceAlias $_.InterfaceAlias -ErrorAction SilentlyContinue }
    Set-DhcpServerv4Binding -BindingState $true -InterfaceAlias $labNic.InterfaceAlias
    Write-Host "DHCP bound to interface: $($labNic.InterfaceAlias)" -ForegroundColor Green
} else {
    Write-Warning "Could not find NIC with IP 10.10.10.10. Check network config."
}

Write-Host ""
Write-Host "=== Step 4: Create DHCP scope for lab subnet ===" -ForegroundColor Cyan
Add-DhcpServerv4Scope `
    -Name "Lab Scope" `
    -StartRange 10.10.10.50 `
    -EndRange 10.10.10.200 `
    -SubnetMask 255.255.255.0 `
    -State Active
Write-Host "Created scope: 10.10.10.50 - 10.10.10.200" -ForegroundColor Green

Write-Host ""
Write-Host "=== Step 5: Set scope DNS option ===" -ForegroundColor Cyan
Set-DhcpServerv4OptionValue `
    -ScopeId 10.10.10.0 `
    -DnsServer 10.10.10.10 `
    -DnsDomain lab.local
Write-Host "Set DNS option to 10.10.10.10 / lab.local" -ForegroundColor Green

# Note: NOT setting router/gateway option — lab is air-gapped on purpose

Write-Host ""
Write-Host "=== Step 6: Restart DHCP service ===" -ForegroundColor Cyan
Restart-Service DHCPServer
Write-Host "DHCP service restarted" -ForegroundColor Green

Write-Host ""
Write-Host "=== Verification ===" -ForegroundColor Cyan
Write-Host "DHCP scopes:"
Get-DhcpServerv4Scope | Format-Table

Write-Host "DHCP bindings:"
Get-DhcpServerv4Binding | Format-Table

Write-Host "DHCP scope options for 10.10.10.0:"
Get-DhcpServerv4OptionValue -ScopeId 10.10.10.0 | Format-Table

Write-Host ""
Write-Host "=== Done. Win11 will now grab an IP automatically when it joins the lab subnet. ===" -ForegroundColor Green
