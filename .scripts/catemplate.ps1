Add-WindowsFeature RSAT-AD-PowerShell
Import-Module ActiveDirectory
 
Install-Module ADCSTemplate -Force
Import-Module ADCSTemplate

$Fab = '{
    "name":  "FabTemp",
    "displayName":  "FabTemp",
    "objectClass":  "pKICertificateTemplate",
    "flags":  131649,
    "revision":  100,
    "msPKI-Cert-Template-OID":  "1.3.6.1.4.1.311.21.8.11207383.5682649.4736405.11314699.16668964.185.929592.5001862",
    "msPKI-Certificate-Application-Policy":  [
                                                 "1.3.6.1.5.5.7.3.1"
                                             ],
    "msPKI-Certificate-Name-Flag":  1,
    "msPKI-Enrollment-Flag":  0,
    "msPKI-Minimal-Key-Size":  2048,
    "msPKI-Private-Key-Flag":  16842768,
    "msPKI-RA-Signature":  0,
    "msPKI-Template-Minor-Revision":  3,
    "msPKI-Template-Schema-Version":  2,
    "pKICriticalExtensions":  [
                                  "2.5.29.15"
                              ],
    "pKIDefaultCSPs":  [
                           "2,Microsoft DH SChannel Cryptographic Provider",
                           "1,Microsoft RSA SChannel Cryptographic Provider"
                       ],
    "pKIDefaultKeySpec":  1,
    "pKIExpirationPeriod":  [
                                0,
                                64,
                                239,
                                43,
                                18,
                                252,
                                255,
                                255
                            ],
    "pKIExtendedKeyUsage":  [
                                "1.3.6.1.5.5.7.3.1"
                            ],
    "pKIKeyUsage":  [
                        160,
                        0
                    ],
    "pKIMaxIssuingDepth":  0,
    "pKIOverlapPeriod":  [
                             0,
                             128,
                             44,
                             171,
                             109,
                             254,
                             255,
                             255
                         ]
}'


#$Fab= Export-ADCSTemplate -DisplayName FabTemp
$WebServerShort = New-ADCSTemplate -DisplayName "Web Server Short" -JSON $Fab -Identity "$((Get-ADDomain).NetBIOSName)\$($env:computername)$" 

#$Validity = New-TimeSpan -Seconds $([System.BitConverter]::ToInt64($Fab.pKIExpirationPeriod, 0) * -.0000001)
#$Validity.Add($(New-TimeSpan -Days 5))
#$NewExpirationPeriod = [System.BitConverter]::GetBytes($($Validity.TotalSeconds * -10000000))