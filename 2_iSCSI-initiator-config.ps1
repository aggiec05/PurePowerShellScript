#Configure iSCSI Initiator for Pure SAN
Clear-Variable Nics,TargetPortals -ErrorAction Ignore

$Nics = Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred -PolicyStore ActiveStore -PrefixOrigin Manual,DHCP
$TargetPortals = @("purect0.myntfb.org","purect1.myntfb.org")

New-IscsiTargetPortal –TargetPortalAddress $TargetPortals[0]

Get-IscsiTarget | Connect-IscsiTarget  -IsPersistent $True –IsMultipathEnabled $True –InitiatorPortalAddress $Nics[1].IPv4Address -TargetPortalAddress $TargetPortals[0]
Get-IscsiTarget | Connect-IscsiTarget  -IsPersistent $True –IsMultipathEnabled $True –InitiatorPortalAddress $Nics[1].IPv4Address -TargetPortalAddress $TargetPortals[1]