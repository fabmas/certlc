

Install-Module -name JWTDetails


$token = "INSERT BEARER TOKEN HERE"
$t = Get-JWTDetails -Token $token
$t
$t.timetoexpiry


