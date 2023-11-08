configuration ExecuteScript
{

    Param 
    (
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Parameter(Mandatory=$true)]
        [String]$DCvmName,

        [Parameter(Mandatory=$true)]
        [String]$CAvmName,
        
        [Parameter(Mandatory=$true)]
        [String]$CAName,
    
        [Parameter(Mandatory=$true)]
        [String]$CDPURL,
    
        [Parameter(Mandatory=$true)]
        [String]$WebenrollURL,

        [Parameter(Mandatory=$true)]
        [String]$demoCertDNSName

    )
    Import-DscResource -ModuleName PSDesiredStateConfiguration, PackageManagement
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost
    {
  
        PackageManagementSource PSGallery
        {
            Ensure              = "Present"
            Name                = "PSGallery"
            ProviderName        = "PowerShellGet"
            SourceLocation      = "https://www.powershellgallery.com/api/v2"
            InstallationPolicy  = "Trusted"
        }

        PackageManagement PSModuleADCSTemplate
        {
            Ensure               = "Present"
            Name                 = "ADCSTemplate"
            Source               = "PSGallery"
            DependsOn            = "[PackageManagementSource]PSGallery"
        }
    
        WindowsFeature ADPS
        {
            Name        = "RSAT-AD-PowerShell"
            Ensure      = "Present"
        }

        script 'ExecuteScript'
        {
            PsDscRunAsCredential = $DomainCreds
            GetScript       = { return @{result = 'result'} }
            TestScript      = { return $false }
            SetScript       = {

                # create a local folder named c:\temp\script and copy the "https://raw.githubusercontent.com/fabmas/certlc/main/.scripts/InstallEntRootCA.ps1" file into it
                $ScriptFolder="c:\temp\script"
                New-Item -Path $ScriptFolder -ItemType Directory -Force |Out-Null
                $ScriptName="InstallEntRootCA.ps1"
                $ScriptPath="$ScriptFolder\$ScriptName"
                $ScriptURL="https://raw.githubusercontent.com/fabmas/certlc/main/.scripts/InstallEntRootCA.ps1"
                Invoke-WebRequest -uri $ScriptURL -OutFile $ScriptPath

                # then run the following command to execute the script

                #Invoke-Expression "$ScriptPath -DCvmName DC01 -CAvmName CA01 -CAName DEMOCA -CDPURL http://ca01.demo.local -WebenrollURL http://ca01.demo.local -demoCertDNSName prova.democa.local"
                Invoke-Expression "$ScriptPath -DCvmName $($using:DCvmName) -CAvmName $($using:CAvmName) -CAName $($using:CAName) -CDPURL $($using:CDPURL) -WebenrollURL $($using:WebenrollURL) -demoCertDNSName $($using:demoCertDNSName)"

            }            
        }
    
    } 


}