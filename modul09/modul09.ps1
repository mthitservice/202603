

# ==========================
# Hilfsfunktionen
# ==========================
function Test-IsPS7 {
    return $PSVersionTable.PSVersion.Major -ge 7
}

function New-SafeDirectory {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

# ==========================
# 1) Snapshot: SMB-Shares + NTFS-ACLs
# ==========================
function Export-AclSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$HomeRoot,
        [Parameter(Mandatory)][string]$OutputPath,
        [string[]]$Servers,
        [switch]$IncludeShareInfo,
        [int]$Parallelism = 8,
        [switch]$Recurse,           # falls du tiefer als Top-Level-Userordner gehen willst
        [string]$Filter = '*'       # z.B. nur bestimmte Benutzerordner
    )

    Write-Host "[INFO] Exportiere Snapshot nach: $OutputPath" -ForegroundColor Cyan
    New-SafeDirectory -Path $OutputPath

    # --- 1a) SMB-Share-Infos (optional) ---
    if ($IncludeShareInfo -and $Servers) {
        $shareFile = Join-Path $OutputPath 'shares.csv'
        $shareAccFile = Join-Path $OutputPath 'sharePermissions.csv'
        $allShares = New-Object System.Collections.Generic.List[object]
        $allSharePerms = New-Object System.Collections.Generic.List[object]

        foreach ($srv in $Servers) {
            try {
                Write-Host "[INFO] Hole Shares von $srv ..." -ForegroundColor Yellow
                
                # Fuer localhost keine CimSession verwenden
                $isLocal = ($srv -eq 'localhost') -or ($srv -eq $env:COMPUTERNAME) -or ($srv -eq '.')
                if ($isLocal) {
                    $shares = Get-SmbShare -ErrorAction Stop | Where-Object { $_.Path -like "$HomeRoot*" }
                } else {
                    $shares = Get-SmbShare -CimSession $srv -ErrorAction Stop | Where-Object { $_.Path -like "$HomeRoot*" }
                }
                
                Write-Host "[INFO] Gefundene Shares: $($shares.Count)" -ForegroundColor Cyan
                
                foreach ($s in $shares) {
                    $allShares.Add([pscustomobject]@{
                        Server      = $srv
                        Name        = $s.Name
                        Path        = $s.Path
                        Description = $s.Description
                        ScopeName   = $s.ScopeName
                        ShareType   = $s.ShareType
                    })
                    try {
                        if ($isLocal) {
                            $acc = Get-SmbShareAccess -Name $s.Name -ErrorAction Stop
                        } else {
                            $acc = Get-SmbShareAccess -CimSession $srv -Name $s.Name -ErrorAction Stop
                        }
                        foreach ($a in $acc) {
                            $allSharePerms.Add([pscustomobject]@{
                                Server      = $srv
                                Share       = $s.Name
                                Account     = $a.AccountName
                                Access      = $a.AccessRight
                                Type        = $a.AccessControlType
                                IsInherited = $a.Inherited
                            })
                        }
                    } catch {
                        Write-Warning ("Fehler beim Abfragen ShareAccess {0}@{1} - {2}" -f $s.Name, $srv, $_)
                    }
                }
            } catch {
                Write-Warning ("Fehler beim Abfragen von Shares auf {0} - {1}" -f $srv, $_)
            }
        }

        $allShares | Export-Csv -Path $shareFile -NoTypeInformation -Encoding UTF8
        $allSharePerms | Export-Csv -Path $shareAccFile -NoTypeInformation -Encoding UTF8
        Write-Host "[OK] Share-Infos: $shareFile, $shareAccFile" -ForegroundColor Green
    }

    # --- 1b) NTFS-ACLs für Benutzerordner im HomeRoot ---
    if (-not (Test-Path -LiteralPath $HomeRoot)) {
        throw "HomeRoot existiert nicht: $HomeRoot"
    }

    $level = if ($Recurse) { -1 } else { 0 }
    $userDirs = Get-ChildItem -LiteralPath $HomeRoot -Directory -Filter $Filter -ErrorAction Stop

    # Folder-Level (Owner + SDDL) sammeln
    $folderOut = if (Test-IsPS7) {
        $userDirs | ForEach-Object -Parallel {
            $p = $_.FullName
            try {
                $acl = Get-Acl -LiteralPath $p
                [pscustomobject]@{
                    Path  = $p
                    Name  = $_.Name
                    Owner = $acl.Owner
                    Sddl  = $acl.Sddl
                }
            } catch {
                [pscustomobject]@{
                    Path  = $p
                    Name  = $_.Name
                    Owner = $null
                    Sddl  = $null
                    Error = $_.Exception.Message
                }
            }
        } -ThrottleLimit $Parallelism
    } else {
        $jobs = foreach ($d in $userDirs) {
            Start-Job -ScriptBlock {
                param($dirPath, $dirName)
                try {
                    $acl = Get-Acl -LiteralPath $dirPath
                    [pscustomobject]@{
                        Path  = $dirPath
                        Name  = $dirName
                        Owner = $acl.Owner
                        Sddl  = $acl.Sddl
                    }
                } catch {
                    [pscustomobject]@{
                        Path  = $dirPath
                        Name  = $dirName
                        Owner = $null
                        Sddl  = $null
                        Error = $_.Exception.Message
                    }
                }
            } -ArgumentList $d.FullName, $d.Name
        }
        Receive-Job -Job $jobs -Wait -AutoRemoveJob
    }

    $folderCsv = Join-Path $OutputPath 'folders.csv'
    $folderJson = Join-Path $OutputPath 'folders.json'
    $folderOut | Export-Csv -Path $folderCsv -NoTypeInformation -Encoding UTF8
    $folderOut | ConvertTo-Json -Depth 5 | Out-File -FilePath $folderJson -Encoding UTF8

    # ACE-Level (jede Zugriffsregel als Zeile)
    $aceOut = if (Test-IsPS7) {
        $userDirs | ForEach-Object -Parallel {
            $p = $_.FullName
            try {
                $acl = Get-Acl -LiteralPath $p
                foreach ($rule in $acl.Access) {
                    [pscustomobject]@{
                        Path          = $p
                        Name          = $_.Name
                        Identity      = $rule.IdentityReference.Value
                        Rights        = $rule.FileSystemRights
                        Type          = $rule.AccessControlType
                        IsInherited   = $rule.IsInherited
                        Inheritance   = $rule.InheritanceFlags
                        Propagation   = $rule.PropagationFlags
                    }
                }
            } catch {
                [pscustomobject]@{
                    Path          = $p
                    Name          = $_.Name
                    Identity      = $null
                    Rights        = $null
                    Type          = 'Error'
                    IsInherited   = $null
                    Inheritance   = $null
                    Propagation   = $null
                    Error         = $_.Exception.Message
                }
            }
        } -ThrottleLimit $Parallelism
    } else {
        $jobs2 = foreach ($d in $userDirs) {
            Start-Job -ScriptBlock {
                param($dirPath, $dirName)
                try {
                    $acl = Get-Acl -LiteralPath $dirPath
                    $out = @()
                    foreach ($rule in $acl.Access) {
                        $out += [pscustomobject]@{
                            Path          = $dirPath
                            Name          = $dirName
                            Identity      = $rule.IdentityReference.Value
                            Rights        = $rule.FileSystemRights
                            Type          = $rule.AccessControlType
                            IsInherited   = $rule.IsInherited
                            Inheritance   = $rule.InheritanceFlags
                            Propagation   = $rule.PropagationFlags
                        }
                    }
                    $out
                } catch {
                    [pscustomobject]@{
                        Path          = $dirPath
                        Name          = $dirName
                        Identity      = $null
                        Rights        = $null
                        Type          = 'Error'
                        IsInherited   = $null
                        Inheritance   = $null
                        Propagation   = $null
                        Error         = $_.Exception.Message
                    }
                }
            } -ArgumentList $d.FullName, $d.Name
        }
        Receive-Job -Job $jobs2 -Wait -AutoRemoveJob
    }

    $aceCsv = Join-Path $OutputPath 'acls.csv'
    $aceOut | Export-Csv -Path $aceCsv -NoTypeInformation -Encoding UTF8

    Write-Host "[OK] NTFS-ACL Snapshot: $folderCsv, $folderJson, $aceCsv" -ForegroundColor Green

    # --- Zusammenfassung erstellen ---
    $summaryFile = Join-Path $OutputPath 'summary.txt'
    $summary = [System.Text.StringBuilder]::new()
    
    [void]$summary.AppendLine("=" * 60)
    [void]$summary.AppendLine("ACL SNAPSHOT - ZUSAMMENFASSUNG")
    [void]$summary.AppendLine("=" * 60)
    [void]$summary.AppendLine("")
    [void]$summary.AppendLine("Erstellt am:    $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')")
    [void]$summary.AppendLine("HomeRoot:       $HomeRoot")
    [void]$summary.AppendLine("Output:         $OutputPath")
    [void]$summary.AppendLine("")
    
    # Ordner-Statistik
    [void]$summary.AppendLine("-" * 60)
    [void]$summary.AppendLine("ORDNER-STATISTIK")
    [void]$summary.AppendLine("-" * 60)
    [void]$summary.AppendLine("Anzahl Ordner:  $($folderOut.Count)")
    [void]$summary.AppendLine("")
    
    foreach ($f in $folderOut) {
        [void]$summary.AppendLine("  Ordner: $($f.Name)")
        [void]$summary.AppendLine("  Pfad:   $($f.Path)")
        [void]$summary.AppendLine("  Owner:  $($f.Owner)")
        [void]$summary.AppendLine("")
    }
    
    # ACL-Statistik
    [void]$summary.AppendLine("-" * 60)
    [void]$summary.AppendLine("NTFS-BERECHTIGUNGEN")
    [void]$summary.AppendLine("-" * 60)
    [void]$summary.AppendLine("Anzahl ACEs:    $($aceOut.Count)")
    [void]$summary.AppendLine("")
    
    $aceGrouped = $aceOut | Group-Object -Property Name
    foreach ($grp in $aceGrouped) {
        [void]$summary.AppendLine("  [$($grp.Name)]")
        foreach ($ace in $grp.Group) {
            $inherited = if ($ace.IsInherited) { "(vererbt)" } else { "(explizit)" }
            [void]$summary.AppendLine("    - $($ace.Identity): $($ace.Rights) [$($ace.Type)] $inherited")
        }
        [void]$summary.AppendLine("")
    }
    
    # Share-Statistik (wenn vorhanden)
    if ($IncludeShareInfo -and $allShares.Count -gt 0) {
        [void]$summary.AppendLine("-" * 60)
        [void]$summary.AppendLine("SMB-SHARES")
        [void]$summary.AppendLine("-" * 60)
        [void]$summary.AppendLine("Anzahl Shares:  $($allShares.Count)")
        [void]$summary.AppendLine("")
        
        foreach ($share in $allShares) {
            [void]$summary.AppendLine("  Share: \\$($share.Server)\$($share.Name)")
            [void]$summary.AppendLine("  Pfad:  $($share.Path)")
            
            $sharePerms = $allSharePerms | Where-Object { $_.Share -eq $share.Name }
            foreach ($perm in $sharePerms) {
                [void]$summary.AppendLine("    - $($perm.Account): $($perm.Access) [$($perm.Type)]")
            }
            [void]$summary.AppendLine("")
        }
    }
    
    # Exportierte Dateien
    [void]$summary.AppendLine("-" * 60)
    [void]$summary.AppendLine("EXPORTIERTE DATEIEN")
    [void]$summary.AppendLine("-" * 60)
    Get-ChildItem -Path $OutputPath -File | ForEach-Object {
        [void]$summary.AppendLine("  $($_.Name) ($([math]::Round($_.Length/1KB, 2)) KB)")
    }
    [void]$summary.AppendLine("")
    [void]$summary.AppendLine("=" * 60)
    
    $summary.ToString() | Out-File -FilePath $summaryFile -Encoding UTF8
    Write-Host "[OK] Zusammenfassung: $summaryFile" -ForegroundColor Green
}

Export-AclSnapshot -HomeRoot 'C:\Users\Michael.Lindner\source\repos\202603\modul09' `
    -OutputPath 'C:\Temp\AclSnapshot' `
    -Servers @('localhost') `
    -IncludeShareInfo `
    -Recurse `
    -Filter '*'    