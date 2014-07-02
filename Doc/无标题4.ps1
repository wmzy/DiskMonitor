$iniPath = 'E:\DiskMonitorConfig.xml';
$doc = New-Object system.xml.xmldocument;
$doc.Load($iniPath);
$servers = $doc.GetElementsByTagName("server");

$messageForMail = '';

foreach ($server in $servers)
{
    # 读取配置文件
    $sName = $server.SelectNodes("sName").InnerText;
    $userName = $server.SelectNodes("userName").InnerText;
    $password = $server.SelectNodes("password").InnerText;
    $minFreeSize = $server.SelectNodes("minFreeSize").InnerText;
    $minFreePer = $server.SelectNodes("minFreePer").InnerText;
    $operation = $server.SelectNodes("operation").InnerText;

    # 读取远程服务器C盘信息
    $cred=New-Object System.Management.Automation.PSCredential($userName, (ConvertTo-SecureString $password -AsPlainText -Force));
    $Device = Get-WmiObject -Class Win32_LogicalDisk -ComputerName $sName -Credential $cred -Namespace root/cimv2 -filter "DeviceID = 'C:' ";

    # 判断C盘是否已满
    $minFreeSize = [System.Convert]::ToInt64($server.SelectNodes("minFreeSize").InnerText);
    $minFreePer = [System.Convert]::ToDouble($server.SelectNodes("minFreePer").InnerText);
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
                Get-Item \\$sName($dir.InnerText);
            }
            net use \\$sName $password /user:$userName /del;
        }
    }
}