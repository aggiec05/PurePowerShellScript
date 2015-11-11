Clear-Host
#Enable MPIO feature 
Write-Host "`n`n"
IF ((Get-WindowsOptionalFeature –Online –FeatureName MultiPathIO).State -eq 'Disabled') {
    Write-Host "Installing Windows MPIO feature... "
    Enable-WindowsOptionalFeature –Online –FeatureName MultiPathIO
} ELSE {
    Write-Host "Windows MPIO feature already enabled"
}
Write-Host "`n`n"
# Enable automatic claiming of iSCSI devices for MPIO
Enable-MSDSMAutomaticClaim -BusType iSCSI
# Set the default load balance policy of all newly claimed devices to Round Robin 
     Set-MSDSMGlobalDefaultLoadBalancePolicy -Policy RR

#Set MPIO Product ID
New-MSDSMSupportedHW -ProductId FlashArray -VendorId PURE 
# Show MPIO hardware info
Get-MSDSMSupportedHW

#Set Microsoft iSCSI Initiator service startup type
IF ((Get-WmiObject -Class Win32_Service -Filter {Name = 'msiscsi'}).StartMode -ne 'Auto') {
    Write-host "Setting 'Microsoft iSCSI Initiator Service' (MSiSCSI) Startup type to 'Automatic'.`n"
    Set-Service -Name msiscsi -StartupType Automatic
} ELSE {
    Write-host "The 'Microsoft iSCSI Initiator Service' (MSiSCSI) Startup type is already set to 'Automatic'.`n"
}
Write-Host "`n`n"
#Start the Microsoft iSCSI Initiator service
Start-Service msiscsi
Write-Host "`n`n"
#Show the Microsoft iSCSI Initiator firewall rules
Get-NetFirewallServiceFilter -Service msiscsi | Get-NetFirewallRule | Select DisplayGroup,DisplayName,Enabled | ft -AutoSize
#Enable the Microsoft iSCSI Initiator firewall rules
Write-Host "`nEnabling the 'iSCSI Service' firewall rules...`n"
Get-NetFirewallServiceFilter -Service msiscsi | Enable-NetFirewallRule
Write-Host "`n"
#Show the Microsoft iSCSI Initiator firewall rules again
Get-NetFirewallServiceFilter -Service msiscsi | Get-NetFirewallRule | Select DisplayGroup,DisplayName,Enabled | ft -AutoSize
Write-Host "`n`n"
