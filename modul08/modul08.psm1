#  Modul:Modul08

# private functions

function Write-VerboseHeader    {
    param([string]$Message)
    Write-Verbose ("Modul08:=== {0} ===" -f $Message)
    
}
<# 
.SYNOPSIS
    Generiert ein zufälliges Passwort basierend auf den angegebenen Parametern.
.DESCRIPTION
    Diese Funktion erstellt ein zufälliges Passwort mit einer Mindest- und Höchstlänge.
    Optional können Sonderzeichen in das Passwort aufgenommen werden.
.PARAMETER minChar
    Die minimale Länge des generierten Passworts. Standardwert ist 3.   

    .EXAMPLE
    Random-Password -minChar 5 -maxChar 12 -specialChar $true
    .Notes  
     Autor: M L
        Datum: 2026

#> 
function Random-Password {
    param(  
    [Parameter(Mandatory=$true,HelpMessage="Länge des Passworts")]        
        [int]$minChar= 3,
    [Parameter(Mandatory=$false)]        
        [int]$maxChar =10, #maxchar ist optional Anzahl der Zeichen
    [Parameter(Mandatory=$false)]        
        [bool]$specialChar =$true  ## Sonderzeichen verwenden
    )
    Write-Verbose "Aufruf $minChar $maxChar"
    #E
        $lowerChars="abcdefghijklmnopqrstuvwxyz"
        $upperChars="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        $numberChars="0123456789"
        $specialChars="!@#$%^&*()"


        #V
        $charSet= $lowerChars + $upperChars + $numberChars

        if ($specialChar) {
            $charSet += $specialChars
        }

        $password  = -join((1..$maxChar) | ForEach-Object { ($charSet).ToCharArray() | Get-Random -Count 1 })

        Write-Host "Minimale Länge: $minChar Maximale Länge: $maxChar Sonderzeichen: $specialChar"
#A
        return $password # Rückgabe
 
    }

    ### Öffentliche Funktionen ###
<#
    .SYNOPSIS
        Gibt eine Begrüßung zurück.
    .DESCRIPTION
        Diese Funktion generiert eine Begrüßungsnachricht basierend auf dem angegebenen Namen
#>
    function  Get-Greetings{
        [CmdletBinding()]
        param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        [switch]$WithTimeofDay
         )
        Write-VerboseHeader "Get-Greetings aufgerufen"

        if($WithTimeofDay){
            $hour=(Get-Date).Hour
            $prefix=switch($hour){
                {$_ -lt 12} {"Guten Morgen"}
                {$_ -lt 18} {"Guten Tag"}
                default {"Guten Abend"}
            }   

            return "{0}, {1}!" -f $prefix,$Name
        }
        else{
            return "Hallo, {0}!" -f $Name
        }

    }

    function New-SpecialUser{
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true)]
            [string]$Username,
            [Parameter(Mandatory=$false)]
            [int]$MinPassLength=8,
            [Parameter(Mandatory=$false)]
            [int]$MaxPassLength=12,
            [Parameter(Mandatory=$false)]
            [bool]$IncludeSpecialChars=$true
        )
        Write-VerboseHeader "New-SpecialUser aufgerufen"

        $password= Random-Password -minChar $MinPassLength -maxChar $MaxPassLength -specialChar $IncludeSpecialChars

        # Simuliere das Erstellen eines Benutzers
        Write-Host "Benutzer '$Username' wurde erstellt mit dem Passwort: $password"

        return @{
            Username = $Username
            Password = $password
        }
    }

# Modulinitialisierung
Export-ModuleMember -Function Get-Greetings, New-SpecialUser

Write-VerboseHeader "Modul08 initialisiert"

