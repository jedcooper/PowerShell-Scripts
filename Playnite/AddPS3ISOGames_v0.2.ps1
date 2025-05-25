# Lade die Windows Forms Assembly für den FolderBrowserDialog
Add-Type -AssemblyName System.Windows.Forms

# Lade die Playnite SDK Assembly – passe ggf. den Pfad an deine Installation an.
Add-Type -Path "Playnite.SDK.dll"

# Ordnerauswahl mittels FolderBrowserDialog
$folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
$folderBrowser.Description = "Wählen Sie den Ordner aus, in dem Ihre .iso-Spiele liegen:"
$result = $folderBrowser.ShowDialog()

if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
    $PlayniteApi.Dialogs.ShowMessage("Kein Ordner ausgewählt. Skript wird beendet.", "ISO Import")
    exit
}

# Der ausgewählte Pfad wird als Installationsverzeichnis verwendet
$gamesFolder = $folderBrowser.SelectedPath
$PlayniteApi.Dialogs.ShowMessage("Ausgewählter Ordner: $gamesFolder", "ISO Import")

# Alle .iso-Dateien im ausgewählten Ordner auflisten (nur im Stammordner; ggf. -Recurse hinzufügen)
$isoFiles = Get-ChildItem -Path $gamesFolder -Filter *.iso

if ($isoFiles.Count -eq 0) {
    $PlayniteApi.Dialogs.ShowMessage("Keine .iso-Dateien in $gamesFolder gefunden.", "ISO Import")
    exit
}

# Hole einmalig die Sony PlayStation 3-Plattform aus der Datenbank (case-insensitive)
$sonyPlatform = $PlayniteApi.Database.Platforms | Where-Object { $_.Name -match "(?i)^Sony PlayStation 3$" }
if (-not $sonyPlatform) {
    Write-Host "Plattform 'Sony PlayStation 3' wurde nicht gefunden. Es erfolgt keine plattformspezifische Duplikatsprüfung." -ForegroundColor Yellow
}

# Erstelle ein HashSet, um schnell zu prüfen, ob ein ROM-Pfad schon existiert (nur für Sony PS3-Spiele)
if ($sonyPlatform) {
    $existingRomPaths = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($game in ($PlayniteApi.Database.Games | Where-Object { $_.PlatformIds -and ($_.PlatformIds -contains $sonyPlatform.Id) })) {
        if ($game.Roms) {
            foreach ($rom in $game.Roms) {
                [void]$existingRomPaths.Add($rom.Path)
            }
        }
    }
}

# Für jede gefundene .iso-Datei wird ein neues Spiel in Playnite hinzugefügt,
# sofern noch kein Spiel (auf derselben Plattform) denselben ROM-Pfad besitzt.
foreach ($iso in $isoFiles) {
    # Falls Sony-PS3-Plattform vorhanden, prüfen, ob der ROM-Pfad schon existiert.
    if ($sonyPlatform -and $existingRomPaths.Contains($iso.FullName)) {
        Write-Host "ROM '$($iso.FullName)' ist bereits vorhanden (auf Sony PlayStation 3). Überspringe Import." -ForegroundColor Yellow
        continue
    }

    # Der ursprüngliche Spielname ist der Dateiname ohne die Endung .iso
    $rawGameName = [System.IO.Path]::GetFileNameWithoutExtension($iso.Name)
    
    # Mit Regex werden alle Inhalte in Klammern entfernt, z. B. (Europe), (USA), (En,Fr,De,...) etc.
    $gameName = [regex]::Replace($rawGameName, "\([^)]*\)", "").Trim()
    
    # Erstelle ein neues Spielobjekt und setze den bereinigten Namen
    $newGame = New-Object "Playnite.SDK.Models.Game"
    $newGame.Name = $gameName
    
    # Setze das Installationsverzeichnis – dieses erscheint im Tab "Installation"
    $newGame.InstallDirectory = $gamesFolder

    # Setze den Status, dass das Spiel installiert ist
    $newGame.IsInstalled = $true

    # Falls die Sony-Plattform vorhanden ist, füge die ID hinzu.
    if ($sonyPlatform) {
        if (-not $newGame.PlatformIds) {
            $newGame.PlatformIds = New-Object "System.Collections.ObjectModel.ObservableCollection[System.Guid]"
        }
        $newGame.PlatformIds.Add($sonyPlatform.Id)
    }
    
    # Füge die ISO als ROM hinzu
    if (-not $newGame.Roms) {
        $newGame.Roms = New-Object "System.Collections.ObjectModel.ObservableCollection[Playnite.SDK.Models.GameRom]"
    }
    $rom = New-Object "Playnite.SDK.Models.GameRom" -ArgumentList "ISO", $iso.FullName
    $newGame.Roms.Add($rom)
    
    # Füge eine Spielaktion hinzu ("Spiel starten")
    $newGame.GameActions = New-Object "System.Collections.ObjectModel.ObservableCollection[Playnite.SDK.Models.GameAction]"
    $action = New-Object "Playnite.SDK.Models.GameAction"
    $action.Name = "Spiel starten"
    $action.Path = $iso.FullName
    $action.Type = [Playnite.SDK.Models.GameActionType]::File
    $newGame.GameActions.Add($action)

    # Füge das Spiel der Datenbank hinzu
    $PlayniteApi.Database.Games.Add($newGame)

    Write-Host "Spiel '$gameName' importiert." -ForegroundColor Cyan

    # Aktualisiere das HashSet, damit nachträgliche Duplikate auch erkannt werden
    if ($sonyPlatform) {
        [void]$existingRomPaths.Add($iso.FullName)
    }
}

$PlayniteApi.Dialogs.ShowMessage("Massenimport abgeschlossen.", "ISO Import")
