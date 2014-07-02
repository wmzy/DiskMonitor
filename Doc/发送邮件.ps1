$objSMTPServer = "mail.yonyou.com" #SMTP服务器地址


$objMail = New-Object System.Net.Mail.MailMessage

 #邮件地址
$objMailFromAddress="Zhult1@yonyou.com"
$objMailtoAddress="1256573276@qq.com;Zhult1@yonyou.com"
$objMail.From = New-Object System.Net.Mail.MailAddress($objMailFromAddress)
$objMail.To.Add($objMailtoAddress)

#邮件内容,使用Get-Content获得HTML格式的邮件正文
$objMail.Subject = "Test";
$objMail.Body = '123';
$objMail.IsBodyHTML = $true;

#发送邮件
$objSMTP = New-Object System.Net.Mail.SmtpClient -argumentList $objSMTPServer;
$objSMTP.Credentials = New-Object System.Net.NetworkCredential("Zhult1@yonyou.com", "ufida2013%");
$objSMTP.Send($objMail);