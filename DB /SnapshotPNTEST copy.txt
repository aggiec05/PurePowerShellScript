$Creds = Get-Credential
$FlashArray = New-PfaArray -EndPoint 192.168.100.170 -Credentials $Creds -IgnoreCertificateError
Get-PfaControllers -Array $FlashArray 
$Controllers = Get-PfaControllers –Array $FlashArray
$Controllers
New-PfaProtectionGroupSnapshot -Array $FlashArray -Protectiongroupname 'PNTEST' -Suffix 'BeforeLoadBuild'