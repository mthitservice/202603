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

# Beispielaufruf
Random-Password 
