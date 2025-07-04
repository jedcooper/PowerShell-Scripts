# 1) Pfad, wohin die neue Textdatei geschrieben wird
$outFile = "C:\Users\patri\OneDrive\Projekte\Twitch\Texte\StartscrollerRetro.txt"

# 2) Statischer Text VOR der Logon-Zeile (Hier-String, kann auch mehrere Zeilen enthalten)
$textBefore = @"                                                                                     
                                                                          
"@

# 3) Statischer Text NACH der Logon-Zeile
$textAfter = @"
 - BIOS ok. 384k RAM ok. Video present.   ***   IBM VT220 Terminal ready... Looks like a stream is starting...   *** STREAM STARTING - no ETA yet ***        twitch.tv/marquisor        youtube.com/marquisor        blog.marquisor.de                  bzzrzt.... ..... bzzZZzzt ...                        EOF  
"@

# 4) Dynamisch: Datum heute minus 40 Jahre und aktuelle Uhrzeit
$datum   = (Get-Date).AddYears(-40).ToString('dd.MM.yyyy')
$uhrzeit = (Get-Date).ToString('HH:mm')

# 5) Zusammenbauen
#    Wenn textBefore leer ist, entfällt automatisch der Vorspann.
$output = "$textBefore" + "Logon: $datum - $uhrzeit" + "$textAfter"

# 6) Datei schreiben (UTF8 ohne BOM)
Set-Content -Path $outFile -Value $output -Encoding UTF8

Write-Host "→ Neue Datei erstellt: $outFile"