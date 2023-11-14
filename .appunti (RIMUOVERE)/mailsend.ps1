#Get Date
$MailDate = Get-Date -format "MM-dd-yyyy"
 
#Configuration Variables for E-mail
$SmtpServer = "localhost" #or IP Address such as "10.125.150.250"
$EmailFrom = "Certificate LifeCycle Automation <clc@demo.com>"
$EmailTo = "user1@demo.com" # da sostituire con recipient sul tage del certificato
$EmailSubject = "Updated Certificate: " + $CertName
#HTML Template
$EmailBody = @"
<table style="width: 68%" style="border-collapse: collapse; border: 1px solid #008080;">
 <tr>
    <td colspan="2" bgcolor="#008080" style="color: #FFFFFF; font-size: large; height: 35px;">
        Certificate LifeCycle Automation - Certificate Update Notification Maildate
    </td>
 </tr>
 <tr style="border-bottom-style: solid; border-bottom-width: 1px; padding-bottom: 1px">
    <td style="width: 201px; height: 35px">  Name of Updated Certificate</td>
    <td style="text-align: center; height: 35px; width: 233px;">
    <b>CertName</b></td>
 </tr>
  <tr style="height: 39px; border: 1px solid #008080">
  <td style="width: 201px; height: 39px">  New Expiration Time</td>
 <td style="text-align: center; height: 39px; width: 233px;">
  <b>NewExpTime</b></td>
 </tr>
</table>
"@
 


$EmailBody= $EmailBody.Replace("CertName",$CertName)
$EmailBody= $EmailBody.Replace("NewExpTime",$newexptime)
$EmailBody= $EmailBody.Replace("Maildate",$Maildate)
  
#Send E-mail from PowerShell script
Send-MailMessage -To $EmailTo -From $EmailFrom -Subject $EmailSubject -Body $EmailBody -BodyAsHtml -SmtpServer $SmtpServer


