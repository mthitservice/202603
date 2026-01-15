# Alle Provider Anzeigen
Get-PSProvider  
# Alle Laufwerke Anzeigen
Get-PSDrive
# Neues PSDrive erstellen
New-PSDrive  -Name WinDir -Root c:\windows -PSProvider  FileSystem
# Ordner in Windir anlegen
new-item windir:\ith -ItemType Directory  

Set-Location HKLM:\SOFTWARE
new-item windir:\ith -ItemType Directory
New-ItemProperty  -Path HKLM:\software\ITH\ -name Demo -Value Test -PropertyType string