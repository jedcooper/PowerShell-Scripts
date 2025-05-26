param(
    $Game
)

# Falls kein Spiel als Parameter übergeben wurde, verwende MainView.SelectedGame
if (-not $Game) {
    $Game = $PlayniteApi.MainView.SelectedGames
}

if (-not $Game) {
    $PlayniteApi.Dialogs.ShowMessage("Kein Spiel ausgewählt!", "Fehler")
    return
}

# $PlayniteApi.Dialogs.ShowMessage("Aktuell ausgewähltes Spiel: $($Game.Name)", "Spiel Info")

$Game > C:\Users\patri\OneDrive\Projekte\Twitch\GameInfo\PN_Game.txt
Set-Content -Path "C:\Users\patri\OneDrive\Projekte\Twitch\GameInfo\PN_Game.Name.txt" -Value $Game.Name -Encoding UTF8 
Set-Content -Path "C:\Users\patri\OneDrive\Projekte\Twitch\GameInfo\PN_Game.Platforms.txt" -Value $Game.Platforms -Encoding UTF8
Set-Content -Path "C:\Users\patri\OneDrive\Projekte\Twitch\GameInfo\PN_Game.ReleaseYear.txt" -Value $Game.ReleaseYear -Encoding UTF8
Copy-Item -Path "F:\PlaynitePortable\Playnite\library\files\$($Game.CoverImage)" -Destination "C:\Users\patri\OneDrive\Projekte\Twitch\GameInfo\PN_Game.CoverImage.jpg"

$quelleDatei = "C:\Users\patri\OneDrive\Projekte\Twitch\GameInfo\PN_Game.ReleaseYear.txt"
$zielDatei = "C:\Users\patri\OneDrive\Projekte\Twitch\GameInfo\PN_Game.Platforms.txt"

if (Test-Path $quelleDatei -PathType Leaf) {
    $inhalt = Get-Content $quelleDatei -Raw | Out-String
    $inhalt = $inhalt -replace "`r`n", " " -replace "`n", " " -replace "`r", " "
    $inhalt = $inhalt.Trim()
    if ($inhalt) {
        # Text anhängen an die Zieldatei
        $anhang = "$inhalt"
        Add-Content -Path $zielDatei -Value $anhang
        Write-Output "Text erfolgreich angehängt"
    } else {
        Write-Output "Quelle-Datei enthält keinen Text"
    }
} else {
    Write-Output "Quelle-Datei existiert nicht"
}

$PlayniteApi.Dialogs.ShowMessage("Infos übertragen für Spiel: $($Game.Name)", "Skript Info")