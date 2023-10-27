Configuration InstallEntRootCA
{
    param
    (
        [Parameter(Mandatory=$true)]
        [String]$CAName,

        [Parameter(Mandatory=$true)]
        [String]$CDPURL,

        [Parameter(Mandatory=$true)]
        [String]$WebenrollURL
    )

    Node localhost
    {
        # Normalize URL to FQDN
        if ($CDPURL -like "http://*" -or $CDPURL -like "https://*")
        {
            $CDPURL = $CDPURL.Split('/')[2]
        }

        if ($WebenrollURL -like "http://*" -or $WebenrollURL -like "https://*")
        {
            $WebenrollURL = $WebenrollURL.Split('/')[2]
        }

        # Checks
        if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
        {
            Write-Verbose 'Script can only run elevated' -Verbose
        }

        $CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $WindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($CurrentUser)
        if (!($WindowsPrincipal.IsInRole('Enterprise Admins')))
        {
            Write-Verbose 'Script can only run with Enterprise Administrator privileges' -Verbose
        }

        # Install required roles and features
        WindowsFeature ADCS-Cert-Authority
        {
            Ensure = "Present"
            Name = "ADCS-Cert-Authority"
            IncludeAllSubFeature = $true
        }

        WindowsFeature ADCS-Enroll-Web-Pol
        {
            Ensure = "Present"
            Name = "ADCS-Enroll-Web-Pol"
            IncludeAllSubFeature = $true
        }

        WindowsFeature ADCS-Enroll-Web-Svc
        {
            Ensure = "Present"
            Name = "ADCS-Enroll-Web-Svc"
            IncludeAllSubFeature = $true
        }

        # Install Enterprise Root CA
        Script InstallRootCA
        {
            GetScript = {
                return @{
                    Result = (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Services\CertSvc\Configuration\$CAName")
                }
            }

            SetScript = {
                if ($Script:Result.Result -eq $false)
                {
                    # Generate a configuration file for the CA
                    File CAConfigFile
                    {
                        DestinationPath = "C:\Windows\capolicy.inf"
                        Contents = "[Version]`nSignature=`"$Windows NT$`"`n`n[PolicyStatementExtension]`nPolicies=InternalUseOnly`n[InternalUseOnly]`nOID=2.5.29.32.0`nNotice=`"This CA is used for a DSC demo environment`"`n`n[Certsrv_Server]`nLoadDefaultTemplates=0`nAlternateSignatureAlgorithm=1`n`n[Extensions]`n2.5.29.15 = AwIBBg==`nCritical = 2.5.29.15"
                        Ensure = "Present"
                    }

                    # Install the CA
                    Script InstallCA
                    {
                        GetScript = { return $null }
                        SetScript = {
                            Install-AdcsCertificationAuthority -CACommonName $using:CAName `
                                -CAType EnterpriseRootCA `
                                -CADistinguishedNameSuffix 'O=DSCCompany,C=NL' `
                                -HashAlgorithmName sha256 `
                                -ValidityPeriod Years `
                                -ValidityPeriodUnits 10 `
                                -CryptoProviderName 'RSA#Microsoft Software Key Storage Provider' `
                                -KeyLength 4096 `
                                -Force

                            # Set CA registry values
                            Invoke-Expression "certutil -setreg CA\AuditFilter 127"
                            Invoke-Expression "certutil -setreg CA\ValidityPeriodUnits 4"
                            Invoke-Expression "certutil -setreg CA\ValidityPeriod `"Years`""
                        }
                    }
                }
            }
        }

        # Configure CA settings and prepare AIA / CDP
        Script ConfigureCASettings
        {
            GetScript = { return $null }
            SetScript = {
                # Create CDP directory
                if (!(Test-Path "C:\CDP"))
                {
                    New-Item -Path "C:\CDP" -ItemType Directory
                }

                # Copy certificate files to CDP
                Copy-Item -Path "C:\Windows\System32\CertSrv\CertEnroll\*.crt" -Destination "C:\CDP\$CAName.crt" -Force

                # Remove existing AIA and CDP
                Get-CAAuthorityInformationAccess | Remove-CAAuthorityInformationAccess -Force
                Get-CACrlDistributionPoint | Remove-CACrlDistributionPoint -Force

                # Add AIA and CDP entries
                Add-CAAuthorityInformationAccess -Uri "http://$using:CDPURL/$CAName.crt" -AddToCertificateAia -Force
                Add-CACrlDistributionPoint -Uri "C:\CDP\<CAName><CRLNameSuffix><DeltaCRLAllowed>.crl" -PublishToServer -PublishDeltaToServer -Force
                Add-CACrlDistributionPoint -Uri "http://$using:CDPURL/<CAName><CRLNameSuffix><DeltaCRLAllowed>.crl" -AddToCertificateCdp -AddToFreshestCrl -Force
            }
        }

        # Create CDP / AIA web site
        Script CreateCDPWebsite
        {
            GetScript = { return $null }
            SetScript = {
                Import-Module 'C:\Windows\system32\WindowsPowerShell\v1.0\Modules\WebAdministration\WebAdministration.psd1'
                New-Website -Name "CDP" -HostHeader $using:CDPURL -Port 80 -IPAddress "*" -Force
                Set-ItemProperty 'IIS:\Sites\CDP' -Name physicalpath -Value "C:\CDP"
                Set-WebConfigurationProperty -PSPath 'IIS:\Sites\CDP' -Filter /system.webServer/directoryBrowse  -Name enabled -Value $true
                Set-WebConfigurationProperty -PSPath 'IIS:\Sites\CDP' -Filter /system.webServer/security/requestfiltering  -Name allowDoubleEscaping -Value $true
                attrib +h "C:\CDP\web.config"
            }
        }

        # Restart CA service and publish CRL
        Service RestartCertSvc
        {
            Name = "CertSvc"
            State = "Running"
            StartupType = "Automatic"
            Ensure = "Present"
        }

        Script PublishCRL
        {
            GetScript = { return $null }
            SetScript = {
                Start-Sleep -Seconds 5
                Invoke-Expression "certutil -CRL"
            }
        }

        # Add webserver template
        Script AddWebServerTemplate
        {
            GetScript = { return $null }
            SetScript = {
                Invoke-Command -ComputerName ($env:LOGONSERVER).Trim("\") -ScriptBlock {
                    $DN = (Get-ADDomain).DistinguishedName
                    $WebTemplate = "CN=WebServer,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,$DN"
                    DSACLS $WebTemplate /G "Authenticated Users:CA;Enroll"
                }
                Invoke-Expression "certutil -setcatemplates +WebServer"
            }
        }

        # Request web server certificate
        Script RequestWebServerCertificate
        {
            GetScript = { return $null }
            SetScript = {
                $cert = Get-Certificate -Template "webserver" -DnsName $using:webenrollURL -SubjectName "CN=$using:webenrollURL" -CertStoreLocation "cert:\LocalMachine\My"
            }
        }

        # Install enrollment web services
        Script InstallEnrollmentServices
        {
            GetScript = { return $null }
            SetScript = {
                Install-AdcsEnrollmentPolicyWebService -AuthenticationType "UserName" -SSLCertThumbprint $using:cert.Certificate.Thumbprint -Force
                Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site/ADPolicyProvider_CEP_UsernamePassword'  -filter "appSettings/add[@key='FriendlyName']" -name "value" -value "DSC CA" -Force
                Install-AdcsEnrollmentWebService -AuthenticationType "UserName" -SSLCertThumbprint $using:cert.Certificate.Thumbprint -Force
            }
        }

        # Modify Enrollment Server URL in AD
        Script ModifyEnrollmentServerURL
        {
            GetScript = { return $null }
            SetScript = {
                $DN = (Get-ADDomain).DistinguishedName
                $CAEnrollmentServiceDN = "CN=$using:CAName,CN=Enrollment Services,CN=Public Key Services,CN=Services,CN=Configuration,$DN"
                Set-ADObject $CAEnrollmentServiceDN -Replace @{'msPKI-Enrollment-Servers'="1`n4`n0`nhttps://$using:webenrollURL/$using:CAName_CES_UsernamePassword/service.svc/CES`n0"}
            }
        }
    }
}

# Run the configuration
InstallEntRootCA -CAName "YourCAName" -CDPURL "YourCDPURL" -WebenrollURL "YourWebenrollURL"
