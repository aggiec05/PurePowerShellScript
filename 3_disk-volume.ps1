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

# Set PURE SAN Disks Online, Initialize, and format


Clear-Variable PureSANs,PureSAN,CurrentDisk,TryLetter,AssignLetter -ErrorAction Ignore

$PureSANs = Get-Disk -FriendlyName "Pure*"

FOREACH ($PureSAN in $PureSANs) {
    $PureSAN | Select-Object OperationalStatus,FriendlyName | FT -AutoSize
    IF ($PureSAN.IsOffline) {
        $PureSAN | FL -Property *
        Write-Host "`nFound an offline Pure SAN drive`n"
        Set-Disk -Number $PureSAN.Number -IsOffline $False
        
        $CurrentDisk = Get-Disk -Number $PureSAN.Number
        If (!($CurrentDisk.IsOffline) -and $CurrentDisk.PartitionStyle -eq 'RAW') { 
            Initialize-Disk -Number $PureSAN.Number -PartitionStyle GPT
        }

        $CurrentDisk = Get-Disk -Number $PureSAN.Number
        If (!($CurrentDisk.IsOffline) -and $CurrentDisk.PartitionStyle -eq 'GPT') { 
            Initialize-Disk -Number $PureSAN.Number -PartitionStyle GPT
            #Loop through Get-PSDrive Letters ("Name") looking for next available letter

            # Loop counter ($TryLetter) is the ASCII value of the driver letter and should be set to one
            # lower the drive letter you would like to start looking from.
            # This because of the Pre-Increment (++$TryLetter).  I strongly recomend AGAINST change this
            # To a Post-Increment.

            # My Loop initializes at 74. That value is one less than my search which is Drive K: (75)]

            # ASCII "A" is 65 and "Z" is 90.  [You do the math for the letters in between]

            Clear-Variable TryLetter,AssignLetter -ErrorAction Ignore
            for($TryLetter=74;(Get-PSDrive($AssignLetter=[char]++$TryLetter)2>0 -ErrorAction Ignore ) ){
                #do nothing whilest looping through Drive Letters
            }
            IF ($TryLetter -gt 90 -or $TryLetter -le 67) {
                Write-Host "`n`nError finding next available Drive Letter!`n`n"
                $AssignLetter = $null
                Clear-Variable TryLetter
                exit 1
            }
            $Label = "PURE SAN disk "+$PureSAN.Number.ToString()
            Write-Host "Will Assign the Letter" $AssignLetter "to the Volume:" $Label
            New-Partition -DiskNumber $PureSAN.Number -DriveLetter $AssignLetter -UseMaximumSize -Confirm:$false
            Format-Volume -DriveLetter $AssignLetter -FileSystem NTFS -NewFileSystemLabel $Label -Confirm:$false 
        }
        $CurrentDisk = Get-Disk -Number $PureSAN.Number
        $CurrentDisk | Select-Object -Property Number,OperationalStatus,BusType,PartitionStyle,FriendlyName | FT -AutoSize -Property *
    }
}
Get-Disk  | Select-Object -Property Number,OperationalStatus,BusType,PartitionStyle,FriendlyName | FT -AutoSize -Property *