Param 
(
    [Parameter(Mandatory=$true)]
    [String]$DomainAdminName,
 
    [Parameter(Mandatory=$true)]
    [String]$DomainAdminPWD,

    [Parameter(Mandatory=$true)]
    [String]$CAName,
 
    [Parameter(Mandatory=$true)]
    [String]$CDPURL,
 
    [Parameter(Mandatory=$true)]
    [String]$WebenrollURL,

    [Parameter(Mandatory=$true)]
    [String]$demoCertDNSName
 
 )

$SecureString = ConvertTo-SecureString -AsPlainText $DomainAdminPWD -Force
$SecureCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $DomainAdminName,$SecureString 


# create a local folder named c:\temp\script and copy the "https://raw.githubusercontent.com/fabmas/certlc/main/.scripts/InstallEntRootCA.ps1" file into it
$ScriptFolder="c:\temp\script"
New-Item -Path $ScriptFolder -ItemType Directory -Force |Out-Null
$ScriptName="InstallEntRootCA.ps1"
$ScriptPath="$ScriptFolder\$ScriptName"
$ScriptURL="https://raw.githubusercontent.com/fabmas/certlc/main/.scripts/InstallEntRootCA.ps1"
#Invoke-WebRequest -uri $ScriptURL -OutFile $ScriptPath

# then run the following command to execute the script
# Invoke-Command -FilePath $ScriptPath -ComputerName $env:COMPUTERNAME -Credential $SecureCreds -Authentication Negotiate -EnableNetworkAccess -ArgumentList $CAName,$CDPURL,$WebenrollURL,$demoCertDNSName -Verbose

Start-Process -FilePath "powershell.exe " -Credential $SecureCreds -ArgumentList "-File $ScriptPath $CAName $CDPURL $WebenrollURL $demoCertDNSName" -Verbose

