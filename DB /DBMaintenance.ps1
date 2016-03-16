Import-Module PureStoragePowerShellSDK

$TargetSQLServer = 'MySQLMachineName'
$TargetSQLSession = New-PSSession -ComputerName $TargetSQLServer

Import-Module SQLPS -PSSession $TargetSQLSession -DisableNameChecking

Write-Host "Database recovery begins now" -ForegroundColor Red

# Offline the database
Write-Host "Offlining the database..." -ForegroundColor Red
Invoke-Command -Session $TargetSQLSession -ScriptBlock { Invoke-Sqlcmd -ServerInstance . -Database master -Query "ALTER DATABASE MyDatabase SET OFFLINE WITH ROLLBACK IMMEDIATE" }

# Offline the volume
Write-Host "Offlining the volume..." -ForegroundColor Red
Invoke-Command -Session $TargetSQLSession -ScriptBlock { Get-Disk | ? { $_.SerialNumber -eq 'E33DF4A38D50A72500012265' } | Set-Disk -IsOffline $True }

# Connect to the FlashArray's REST API, get a session going
# THIS IS A SAMPLE SCRIPT WE USE FOR DEMOS! _PLEASE_ do not save your password in cleartext here.
# Use NTFS secured, encrypted files or whatever else -- never cleartext!
Write-Host "Establishing a session to the Pure Storage FlashArray..." -ForegroundColor Red
$FlashArray = New-PfaArray –EndPoint MyArrayName -UserName MyUsername -Password (ConvertTo-SecureString -AsPlainText "MyPassword" -Force) -IgnoreCertificateError

Write-Host "Obtaining the most recent snapshot for the protection group..." -ForegroundColor Red
$MostRecentSnapshots = Get-PfaProtectionGroupSnapshots -Array $FlashArray -Name 'MyArrayName:MyProtectionGroupName' | Sort-Object created -Descending | Select -Property name -First 2

# Perform the SQL volume overwrite
Write-Host "Overwriting the SQL database volume with a copy of the most recent snapshot..." -ForegroundColor Red
New-PfaVolume -Array $FlashArray -VolumeName TargetSQLServer-data-volume -Source ($MostRecentSnapshot + '.MyProduction-data-volume') -Overwrite

# Online the volume
Write-Host "Onlining the volume..." -ForegroundColor Red
Invoke-Command -Session $TargetSQLSession -ScriptBlock { Get-Disk | ? { $_.SerialNumber -eq '423F93C2ECF544580001103B' } | Set-Disk -IsOffline $False }

# Online the database
Write-Host "Onlining the database..." -ForegroundColor Red
Invoke-Command -Session $TargetSQLSession -ScriptBlock { Invoke-Sqlcmd -ServerInstance . -Database master -Query "ALTER DATABASE My_SQL_Database SET ONLINE WITH ROLLBACK IMMEDIATE" }

Write-Host "Database recovery ended." -ForegroundColor Red

# Clean up
Remove-PSSession $TargetVMSession
Write-Host "All done." -ForegroundColor Red
