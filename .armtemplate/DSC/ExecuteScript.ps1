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
        [String]$CAName,
    
        [Parameter(Mandatory=$true)]
        [String]$CDPURL,
    
        [Parameter(Mandatory=$true)]
        [String]$WebenrollURL,

        [Parameter(Mandatory=$true)]
        [String]$demoCertDNSName
    )

    Import-DscResource -ModuleName xActiveDirectory, PSDesiredStateConfiguration, PackageManagement
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
    
        
        PackageManagement PSModuleActiveDirectory
        {
            Ensure               = "Present"
            Name                 = "ActiveDirectory"
            Source               = "PSGallery"
            DependsOn            = "[PackageManagementSource]PSGallery"
        }
    
    
        WindowsFeature 'RSAT-AD-PowerShell'
        {
            Name                 = 'RSAT-AD-PowerShell'
            Ensure               = 'Present'
            IncludeAllSubFeature = $true 
        }
    
        WindowsFeature 'ADCS-Cert-Authority'
        {
            Name                 = 'ADCS-Cert-Authority'
            Ensure               = 'Present'
            IncludeAllSubFeature = $true 
        }
    
        WindowsFeature 'ADCS-Enroll-Web-Pol'
        {
            Name                 = 'ADCS-Enroll-Web-Pol'
            Ensure               = 'Present'
            IncludeAllSubFeature = $true 
        }
    
        WindowsFeature 'ADCS-Enroll-Web-Svc'
        {
            Name                 = 'ADCS-Enroll-Web-Svc'
            Ensure               = 'Present'
            IncludeAllSubFeature = $true 
        }
    
        script 'ExecuteScript'
        {
            DependsOn            = "[PackageManagement]PSModuleADCSTemplate"
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
                Start-Process -FilePath "powershell.exe " -ArgumentList "-File $ScriptPath $CAName $CDPURL $WebenrollURL $demoCertDNSName" -Verbose

                #Invoke-Command -ComputerName $env:COMPUTERNAME -FilePath $ScriptPath -Credential $SecureCreds -ArgumentList $CAName,$CDPURL,$WebenrollURL,$demoCertDNSName -Verbose

            
            }            
        }
    
    } #//CHIUSURA NODE LOCALHOST


}