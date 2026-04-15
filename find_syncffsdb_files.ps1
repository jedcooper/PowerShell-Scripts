# find_and_recycle.ps1
# Findet rekursiv alle sync.ffs_db (inkl. versteckt/System) auf allen FS-Laufwerken 
# außer D:, J: und K: und verschiebt sie in den Papierkorb.

Add-Type -AssemblyName Microsoft.VisualBasic

# Laufwerke, die ausgelassen werden sollen
$exclude = @('D','J','K')

# Alle Dateisystem-Laufwerke ohne D, J, K
$drives = Get-PSDrive -PSProvider FileSystem |
          Where-Object { $exclude -notcontains $_.Name }

foreach ($drv in $drives) {
    $root = $drv.Root
    Write-Host "Durchsuche $root ..." -ForegroundColor Cyan

    # Alle Dateien sync.ffs_db finden (versteckt/System) und jede einzeln verarbeiten
    Get-ChildItem -Path $root `
                  -Filter 'sync.ffs_db' `
                  -Recurse `
                  -Force `
                  -ErrorAction SilentlyContinue |
    Where-Object { -not $_.PSIsContainer } |
    ForEach-Object {
        $full = $_.FullName

        # In den Papierkorb verschieben
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(
            $full,
            [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs,
            [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin
        )

        Write-Host "Verschoben: $full" -ForegroundColor Green

        # Falls du stattdessen permanent löschen willst, aktiviere folgende Zeile:
        # Remove-Item $full -Force -ErrorAction SilentlyContinue
    }
}