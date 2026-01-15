# WMI
get-wmiobject  -Class win32_Service -ComputerName localhost | Get-Member

Get-CimClass -ClassName Win32_Service | Get-Member

Get-CimClass -ClassName Win32_Service | Select-Object -ExpandProperty CimClassMethods | Sort-Object -Property Name


Invoke-CimMethod -ComputerName localhost -ClassName win32_operatingsystem -MethodName Reboot 

mspaint.exe

Get-CimInstance  -ClassName Win32_Process -Filter "Name = 'mspaint.exe'" | Invoke-CimMethod -MehodName Terminate   

# CIM Session

$s = New-CimSession -ComputerName  localhost 

Get-CimInstance -className Win32_LogicalDisk -Filter 'DriveType=3' -CimSession $s
Get-CimInstance -CimSession $s -Query "SELECT * FROM Win32_LogicalDisk WHERE DriveType=3"
Get-CimInstance -CimSession $s -Query "SELECT * FROM Win32_NetworkAdapter"
# Sitzungen schließen
$s | Remove-CimSession