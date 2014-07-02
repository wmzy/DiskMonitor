$iniPath = 'E:\DiskMonitorConfig.xml'; # 配置文件目录
$doc = New-Object system.xml.xmldocument;
$doc.Load($iniPath);
$servers = $doc.GetElementsByTagName("server");

$messageForMail = '';

foreach ($server in $servers)
{
    # 读取配置文件
    $sName = $server.SelectSingleNode("sName").InnerText;
    $userName = $server.SelectSingleNode("userName").InnerText;
    $password = $server.SelectSingleNode("password").InnerText;
    $minFreeSize = $server.SelectSingleNode("minFreeSize").InnerText;
    $minFreePer = $server.SelectSingleNode("minFreePer").InnerText;
    $operation = $server.SelectSingleNode("operation").InnerText;

    # 读取远程服务器C盘信息
    $cred=New-Object System.Management.Automation.PSCredential($userName, (ConvertTo-SecureString $password -AsPlainText -Force));
    $Device = Get-WmiObject -Class Win32_LogicalDisk -ComputerName $sName -Credential $cred -Namespace root/cimv2 -filter "DeviceID = 'C:' ";

    # 判断C盘是否已满
    $minFreeSize = [System.Convert]::ToInt64($server.SelectSingleNode("minFreeSize").InnerText);
    $minFreePer = [System.Convert]::ToDouble($server.SelectSingleNode("minFreePer").InnerText);
    $FreePer = $Device.FreeSpace / $Device.Size;
    if (($Device.FreeSpace -le $minFreeSize) -or ($FreePer -le $minFreePer))
    {
        if ($operation.ToLower().Contains("sendmail"))
        {
            $messageForMail += "<tr><td>" + $sName + "</td><td>" + $Device.Size + "</td><td>" + $Device.FreeSpace + "</td><td>" + $FreePer + "</td></tr>";
        }
        
        if ($operation.ToLower().Contains("delfile"))
        {
            net use \\$sName $password /user:$userName;
            $clearDir = $server.SelectNodes("clearDir");
            foreach ($dir in $clearDir)
            {
                Remove-Item ("\\$sName\" + ($dir.InnerText) + "\*") -Force;
            }
            net use \\$sName /del;
        }
    }
}

# 发送邮件
if (-not [System.string]::IsNullOrEmpty($messageForMail))
{
    $mailServer = $doc.SelectSingleNode("//mail/mailServer").InnerText;
    $from = $doc.SelectSingleNode("//mail/from").InnerText;
    $password = $doc.SelectSingleNode("//mail/password").InnerText;
    $toList = $doc.SelectNodes("//mail/toList/to");
    $ccList = $doc.SelectNodes("//mail/ccList/cc");

    $mail = New-Object System.Net.Mail.MailMessage;
    $mail.IsBodyHTML = $true;
    $mail.from = $from;
    $mail.Subject = "ufsdpweb 磁盘已满通知";
    $mail.Body = "<table border=`"1`"><tr><th>服务器</th><th>C盘总容量</th><th>C盘空闲容量</th><th>C盘空闲率</th></tr>" + $messageForMail + "</table>";
    foreach($to in $toList)
    {
        $mail.To.Add((New-Object System.Net.Mail.MailAddress($to.InnerText)));
    }
    foreach($cc in $ccList)
    {
        $mail.CC.Add((New-Object System.Net.Mail.MailAddress($cc.InnerText)));
    }
    $mServer = New-Object System.Net.Mail.SmtpClient -argumentList $mailServer;
    
    $mServer.Credentials = New-Object System.Net.NetworkCredential($from, $password);
    $mServer.Send($mail);
}