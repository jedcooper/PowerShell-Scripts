# Lade die Windows Forms Assembly für den FolderBrowserDialog
Add-Type -AssemblyName System.Windows.Forms

# Lade die Playnite SDK Assembly – passe ggf. den Pfad an deine Installation an.
Add-Type -Path "C:\Users\patri\AppData\Local\Playnite\Playnite.SDK.dll"

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

# Alle .iso-Dateien im ausgewählten Ordner auflisten (nur im Stammordner; -Recurse hinzufügen, falls benötigt)
$isoFiles = Get-ChildItem -Path $gamesFolder -Filter *.iso

if ($isoFiles.Count -eq 0) {
    $PlayniteApi.Dialogs.ShowMessage("Keine .iso-Dateien in $gamesFolder gefunden.", "ISO Import")
    exit
}

# Für jede gefundene .iso-Datei wird ein neues Spiel in Playnite hinzugefügt
foreach ($iso in $isoFiles) {
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

    # Hole die Liste der Platformen aus der Datenbank und suche case-insensitive nach "Sony PlayStation 3"
    $sonyPlatform = $PlayniteApi.Database.Platforms | Where-Object { $_.Name -match "(?i)^Sony PlayStation 3$" }
    if ($sonyPlatform) {
        # Stelle sicher, dass die PlatformIds-Collection als ObservableCollection<Guid> initialisiert ist
        if (-not $newGame.PlatformIds) {
            $newGame.PlatformIds = New-Object "System.Collections.ObjectModel.ObservableCollection[System.Guid]"
        }
        # Füge die gefundene Platform-ID hinzu
        $newGame.PlatformIds.Add($sonyPlatform.Id)
    }
    
    # Füge die ISO als ROM hinzu, indem ein GameRom-Objekt erstellt und der Roms-Collection hinzugefügt wird.
    if (-not $newGame.Roms) {
        $newGame.Roms = New-Object "System.Collections.ObjectModel.ObservableCollection[Playnite.SDK.Models.GameRom]"
    }
    $rom = New-Object "Playnite.SDK.Models.GameRom" -ArgumentList "ISO", $iso.FullName
    $newGame.Roms.Add($rom)
    
    # Initialisiere die GameActions als ObservableCollection
    $newGame.GameActions = New-Object "System.Collections.ObjectModel.ObservableCollection[Playnite.SDK.Models.GameAction]"

    # Erstelle eine Spielaktion (über den parameterlosen Konstruktor) und setze anschließend deren Eigenschaften
    $action = New-Object "Playnite.SDK.Models.GameAction"
    $action.Name = "Spiel starten"
    $action.Path = $iso.FullName
    $action.Type = [Playnite.SDK.Models.GameActionType]::File

    # Füge die Aktion dem Spiel hinzu
    $newGame.GameActions.Add($action)

    # Füge das Spiel der Playnite-Datenbank hinzu
    $PlayniteApi.Database.Games.Add($newGame)

    Write-Host "Spiel '$gameName' importiert." -ForegroundColor Cyan
}

$PlayniteApi.Dialogs.ShowMessage("Massenimport abgeschlossen.", "ISO Import")
