#Configure iSCSI Initiator for Pure SAN
Clear-Host

Clear-Variable Nics,TargetPortals -ErrorAction Ignore

$Nics = Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred -PolicyStore ActiveStore -PrefixOrigin Manual,DHCP
$TargetPortals = @("purect0.myntfb.org","purect1.myntfb.org")

New-IscsiTargetPortal –TargetPortalAddress $TargetPortals[0]
New-IscsiTargetPortal –TargetPortalAddress $TargetPortals[1]

Get-IscsiTarget | Connect-IscsiTarget  -IsPersistent $True –IsMultipathEnabled $True –InitiatorPortalAddress $Nics[1].IPv4Address -TargetPortalAddress $TargetPortals[0]
Get-IscsiTarget | Connect-IscsiTarget  -IsPersistent $True –IsMultipathEnabled $True –InitiatorPortalAddress $Nics[1].IPv4Address -TargetPortalAddress $TargetPortals[1]


Start-Sleep -Seconds 10

Get-Disk | Where-Object { $_.FriendlyName -like "PURE*" } | FT -AutoSize -Property Number,IsReadOnly,OperationalStatus,BusType,PartitionStyle,BusType,FriendlyName

$discs = Get-Disk | Where-Object { $_.FriendlyName -like "PURE*" -and $_.PartitionStyle -eq "raw" }

ForEach ($disc in $discs) {
    $label = "Pure SAN disk "+$disc.Number

    Clear-Variable TryLetter,AssignLetter -ErrorAction Ignore
    for($TryLetter=74;(Get-PSDrive($AssignLetter=[char]++$TryLetter)2>0 -ErrorAction Ignore ) ){
        #do nothing whilest looping through Drive Letters
    }

    IF ($TryLetter -gt 90 -or $TryLetter -le 67) {
        Write-Host "`n`nError finding next available Drive Letter!`n`n"
        $AssignLetter = $null
        Clear-Variable TryLetter,AssignLetter
        exit 1
    }

    Get-Disk -Number $disc.Number |
    Where-Object { $_.FriendlyName -like "PURE*" -and $_.PartitionStyle -eq "raw" } |
    Initialize-Disk -PartitionStyle GPT -PassThru |
    New-Partition -UseMaximumSize |
    Format-Volume -FileSystem NTFS -NewFileSystemLabel $label -Confirm:$false
    #Start-Sleep 2

    Get-Partition -DiskNumber $disc.Number -PartitionNumber 2 |
    Set-Partition -NewDriveLetter $AssignLetter
    #Start-Sleep 2
}

Get-Disk | Where-Object { $_.FriendlyName -like "PURE*" } | FT -AutoSize -Property Number,IsReadOnly,OperationalStatus,BusType,PartitionStyle,BusType,FriendlyName

Write-Host "### Pure SAN Mount Drives ###"
Get-Disk | Where-Object { $_.FriendlyName -like "PURE*" } | Get-Partition | where Type -EQ 'Basic' | 
FT -AutoSize -Property DriveLetter,Size,Type
