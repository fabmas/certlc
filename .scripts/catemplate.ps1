$ConfigContext = ([ADSI]"LDAP://RootDSE").ConfigurationNamingContext 
$ADSI = [ADSI]"LDAP://CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext" 

$NewTempl = $ADSI.Create("pKICertificateTemplate", "CN=WebServerShort") 
$NewTempl.put("distinguishedName","CN=WebServerShort,CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext") 
# and put other atributes that you need 

$NewTempl.put("flags","131649")
$NewTempl.put("displayName","Web Server Short")
$NewTempl.put("revision","100")
$NewTempl.put("pKIDefaultKeySpec","1")
$NewTempl.SetInfo()

$NewTempl.put("pKIMaxIssuingDepth","0")
$NewTempl.put("pKICriticalExtensions","2.5.29.15")
$NewTempl.put("pKIExtendedKeyUsage","1.3.6.1.5.5.7.3.1")
$NewTempl.put("pKIDefaultCSPs","2,Microsoft DH SChannel Cryptographic Provider, 1,Microsoft RSA SChannel Cryptographic Provider")
$NewTempl.put("msPKI-RA-Signature","0")
$NewTempl.put("msPKI-Enrollment-Flag","0")
$NewTempl.put("msPKI-Private-Key-Flag","16842768")
$NewTempl.put("msPKI-Certificate-Name-Flag","1")
$NewTempl.put("msPKI-Minimal-Key-Size","2048")
$NewTempl.put("msPKI-Template-Schema-Version","2")
$NewTempl.put("msPKI-Template-Minor-Revision","3")
$NewTempl.put("msPKI-Cert-Template-OID","1.3.6.1.4.1.311.21.8.11207383.5682649.4736405.11314699.16668964.185.5079113.15567478")
$NewTempl.put("msPKI-Certificate-Application-Policy","1.3.6.1.5.5.7.3.1")
$NewTempl.SetInfo()

$WSTempl = $ADSI.psbase.children | where {$_.displayName -match "Web Server"}

$NewTempl.put("pKIKeyUsage",$WSTempl.pKIKeyUsage)
$NewTempl.SetInfo()

$NewTempl.put("pKIExpirationPeriod","0 64 239 43 18 252 255 255")
$NewTempl.put("pKIOverlapPeriod","0 128 44 171 109 254 255 255")
$NewTempl.SetInfo()

$NewTempl | select *

###############

# $FabTempl = $ADSI.psbase.children | where {$_.displayName -match "FabioTemp"}
# $FabTempl | select *
# $fabTempl.pkiKeyUsage