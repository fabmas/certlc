Param 
(
    [Parameter(Mandatory=$true)]
    [String]$DomainAdminName,
 
    [Parameter(Mandatory=$true)]
    [String]$DomainAdminPWD
 
 )

$SecureString = ConvertTo-SecureString -AsPlainText $DomainAdminPWD -Force
$SecureCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $DomainAdminName,$SecureString 

Invoke-Command -FilePath ".\hello.ps1" -ComputerName localhost -Credential $SecureCreds

