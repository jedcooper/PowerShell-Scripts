param(
    $Game
)

# Falls kein Spiel als Parameter übergeben wurde, verwende MainView.SelectedGames
if (-not $Game) {
    $Game = $PlayniteApi.MainView.SelectedGames
}

if (-not $Game) {
    $PlayniteApi.Dialogs.ShowMessage("Kein Spiel ausgewählt!", "Fehler")
    return
}

# Wenn mehrere Spiele ausgewählt sind, breche ab (genau 1 muss selektiert sein)
if ($Game -is [array]) {
    if ($Game.Count -ne 1) {
        $PlayniteApi.Dialogs.ShowMessage("Bitte markiere genau ein Spiel, nicht mehrere.", "Fehler")
        return
    } else {
        $Game = $Game[0]
    }
}

# Definiere den Zielpfad für die GameInfo-Dateien
$gameInfoPath = "C:\Users\patri\OneDrive\Projekte\Twitch\GameInfo"

# Schreibe Spielinfos in Dateien
$Game > (Join-Path $gameInfoPath "PN_Game.txt")
Set-Content -Path (Join-Path $gameInfoPath "PN_Game.Name.txt") -Value $Game.Name -Encoding UTF8
Set-Content -Path (Join-Path $gameInfoPath "PN_Game.Platforms.txt") -Value $Game.Platforms -Encoding UTF8
Set-Content -Path (Join-Path $gameInfoPath "PN_Game.ReleaseYear.txt") -Value $Game.ReleaseYear -Encoding UTF8

# Basis-Pfad, in dem die Cover-/Plattform-Bilder liegen – hier statisch, da Playnite portable ist.
$baseFilesPath = "F:\PlaynitePortable\Playnite\library\files"

# Bestimme den Pfad, der verwendet werden soll:
# Falls ein CoverImage vorhanden ist, diesen nehmen,
# ansonsten versuchen, aus der ersten zugeordneten Plattform zuerst das Hintergrundbild, alternativ das Coverbild zu verwenden.
if (-not [string]::IsNullOrEmpty($Game.CoverImage)) {
    # Entferne führende Backslashes, falls vorhanden
    $coverImageFile = $Game.CoverImage.TrimStart("\")
    $coverImagePath = Join-Path $baseFilesPath $coverImageFile
}
else {
    # Kein CoverImage – verwende das Bild der zugeordneten Plattform
    if ($Game.PlatformIds -and $Game.PlatformIds.Count -gt 0) {
        $platform = $PlayniteApi.Database.Platforms | Where-Object { $_.Id -eq $Game.PlatformIds[0] }
        if ($platform) {
            $platformImage = $null
            # Versuch zuerst, das Hintergrundbild der Plattform zu nutzen
            if (-not [string]::IsNullOrEmpty($platform.Background)) {
                $platformImage = $platform.Background.TrimStart("\")
            }
            # Falls kein Hintergrundbild vorhanden ist, nutze alternativ das Plattform Coverbild
            elseif (-not [string]::IsNullOrEmpty($platform.Cover)) {
                $platformImage = $platform.Cover.TrimStart("\")
            }
            # Falls weder Cover noch Hintergrund der Plattform vorhanden verwende das Icon
            elseif (-not [string]::IsNullOrEmpty($platform.Icon)) {
                $platformImage = $platform.Icon.TrimStart("\")
            }
            if ($platformImage) {
                $coverImagePath = Join-Path $baseFilesPath $platformImage
            }
        }
    }
}

# Falls weder ein gültiger Cover- noch eine Plattform-Bilddatei ermittelt werden konnte, breche ab
if (-not $coverImagePath) {
    $PlayniteApi.Dialogs.ShowMessage("Kein Cover-, Hintergrund- oder Plattform-Coverbild gefunden!", "Fehler")
    return
}

# Kopiere das ermittelte Bild in den Zielordner
Copy-Item -Path $coverImagePath -Destination (Join-Path $gameInfoPath "PN_Game.CoverImage.jpg")

# Text aus der ReleaseYear-Datei an PN_Game.Platforms.txt anhängen
$quelleDatei = Join-Path $gameInfoPath "PN_Game.ReleaseYear.txt"
$zielDatei   = Join-Path $gameInfoPath "PN_Game.Platforms.txt"

if (Test-Path $quelleDatei -PathType Leaf) {
    $inhalt = Get-Content $quelleDatei -Raw | Out-String
    $inhalt = $inhalt -replace "`r`n", " " -replace "`n", " " -replace "`r", " "
    $inhalt = $inhalt.Trim()
    if ($inhalt) {
        Add-Content -Path $zielDatei -Value $inhalt
        Write-Output "Text erfolgreich angehängt"
    }
    else {
        Write-Output "Quelle-Datei enthält keinen Text"
    }
}
else {
    Write-Output "Quelle-Datei existiert nicht"
}

$PlayniteApi.Dialogs.ShowMessage("Infos übertragen für Spiel: $($Game.Name)", "Skript Info")