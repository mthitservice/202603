# Sorting Objects
Get-Process

Get-Process | Sort-Object -Property  ID

Get-Service | Sort-Object -Property  Status

Get-Service | Sort-Object -Property  Status -Descending

Get-EventLog -LogName Security -Newest 10 
### Filter
Get-SmbShare | where Name -like 'Ad*'

Get-PhysicalDisk | Where-Object -FilterScript { $PSItem.HealthStatus -eq 'Healthy' } | Select-Object -Property FriendlyName, OperationalStatus

get-verb | where { $_.Verb -like 'c*' } | fw

# Measure-Object    
Get-Service | Measure-Object
Get-Process | Measure-Object -Property VM -Sum -Average 
# Calculate Property
get-Process | Select-Object Name, @{Name = "MemoryMB"; Expression = { $_.WS / 1MB } } 
