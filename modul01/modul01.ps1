# Powershell Modul01

# Zeige alle Commands mit *net*
Get-Command *net*
# Zeigt alle CMDlet mit *net* an
Get-Help *net* -Category Cmdlet
# Anzeige der Hilfedateien im Kontext
get-help about*
get-help about_aliases
Get-Help about_eventlogs -ShowWindow
#######################################
# Aliase erstellen
#  Zeigt alle  Dateien an (Wenn Provider auf Files zeigt)
dir
# Dir ruft get-ChildItem auf
Get-ChildItem
# Aliasumleit von dir anzeigen
Get-Alias dir
# Alias erstellen
New-Alias list get-childitem
# Alias probieren
list
# Alias anzeigen
Get-Alias list
# Alias für get-childitem anzeigen
get-alias  -Definition get-childitem
##### Module
Get-Module

#  Modulaufruf über CMDLET
Get-aduser -filter *

Get-Module -ListAvailable

Import-Module Microsoft.Graph   

$cert = (Get-ChildItem "Cert:\CurrentUser\MY" -CodeSigningCert)[1]
Set-AuthenticodeSignature -FilePath .\modul01.ps1 -Certificate $cert
