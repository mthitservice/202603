# Variablen

$a = 1
$b = 'Zwei'
$c = Get-Service WSearch
$d = 87654321123

$a.GetType()
$b.GetType()
$c.GetType()
$d.GetType()

$b.ToLower()

[int64]$e = 7
$e.GetType()
"TEst"
[byte]$e = 244
$e.GetType()

$f = Get-Date
$f 
$f.GetType()
$f.ToLongDateString()
$f.ToFileTimeUtc()
$f.ToString("dd.MM.yyyy HH:mm zzz")

$newTime = $f.AddDays(10)
$newTime 

###### Array ######
$array1 = 1, 2, 3, 4, 5
$array1.GetType()
$array2 = "ith-srv01", "ith-srv02", "ith-srv03"
$array2.GetType()   
$array1.Count
$array2.Count
$array1[2]
$array2[2]

$newArray = @()
$newArray.GetType()
$newArray.GetLength()
$newArray.Add("Test1")
$newArray.Add("Test2")

$newArray.Count

$newArray

$newArray2 = New-Object System.Collections.ArrayList
$newArray2.GetType()
$newArray2.Add("TestA") 
$newArray2.Add("TestB") 
$newArray2 += "TestC"
$newArray2.Count
$newArray2
$newArray3 = New-Object System.Collections.Queue
$newArray3.GetType()
$newArray3.Enqueue("Eintrag1")
$newArray3.Enqueue("Eintrag2")

$newArray3.Count
$newArray3.Dequeue()
$newArray3.Count
$newArray3.Peek()
$newArray3.Count    
$newArray3 

#hash tables
$hash['Server01'] = 5

$serverlist = @{"Server01" = "192.168.115.1"; "Server02" = "192.168.115.2" }
$serverlist.GetType()
$serverlist.Add("Server03", "192.168.115.3")

$serverlist
$serverlist["Server02"]


$liste = [System.Collections.ArrayList]::new()
$liste.Add(1)
$liste.Add(2)
$liste.AddRange(3..10)
$liste.Count
$liste

$liste | ForEach-Object {

    $_ * 2
    
}
# Speichern von Objekten über Standartausgabe in eine Textdatei
## Get-Service >> text.txt

##### Arbeiten mit Dateien und Ordnern #####
#  Schreiben
"Zeile 1" , "Zeile 2" | Set-Content -Path text2.txt -Encoding UTF8

# Zeile hinzufügen
"Zeile 3" | Add-Content -Path text2.txt -Encoding UTF8

# Lesen
$daten = Get-Content -Path text2.txt -Encoding UTF8 
$daten

$daten2 = get-content -Path .\*.txt -Raw

# Typisierte Daten erzeugen
$person = @(
    [PSCustomObject]@{
        Vorname  = "Max"
        Nachname = "Mustermann"
        Alter    = 29
        Beruf    = "IT-Administrator"
    }, [PSCustomObject]@{
        Vorname  = "Sabine"
        Nachname = "Musterfrau"
        Alter    = 30
        Beruf    = "IT-Administrator"
    })
$person.GetType()
$person 
$person | Export-Csv -Path personen.csv -NoTypeInformation -Encoding UTF8
# Lesen von csv
$personen2 = Import-Csv -Path personen.csv -Encoding UTF8
$personen2  | Where-Object { $PSItem.Alter -gt 29 }

# Semistrukturierte Daten 

$person1 = @(
    [PSCustomObject]@{
        Vorname  = "Max"
        Nachname = "Mustermann"
        Alter    = 29
        Beruf    = "IT-Administrator"
        Location = @{
            Stadt = "Musterstadt"
            PLZ   = "12345"
        }
    }, [PSCustomObject]@{
        Vorname  = "Sabine"
        Nachname = "Musterfrau"
        Alter    = 30
        Beruf    = "IT-Administrator"
        Location = @{
            Stadt = "Musterstadt1"
            PLZ   = "123451"
        }
    })

$person1 | ConvertTo-Json -Depth 3 | Set-Content -Path personen.json -Encoding UTF8

# Json  einlesen
$personenJson = Get-Content -Path personen.json -Raw -Encoding UTF8 
$personenObj = $personenJson | ConvertFrom-Json
$personenObj[0].Location.Stadt  

# XML
$personenObj | Export-Clixml -Path personen.xml
#xml einlesen
$personenXml = Import-Clixml -Path personen.xml
$personenXml    


$personenXml | ConvertTo-Html | Set-Content -Path personen.html -Encoding UTF8

