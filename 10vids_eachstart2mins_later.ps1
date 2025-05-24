# Voraussetzung: FFmpeg muss im Systempfad sein
$inputFile = "fehler_vhs.MXF"

# Schritt 1: Gesamtdauer des Videos ermitteln
$durationLine = ffmpeg -i $inputFile 2>&1 | Select-String "Duration"
if (-not $durationLine) {
    Write-Error "Videolänge konnte nicht ermittelt werden."
    exit
}
# Extrahiere die Dauer (Format: 00:40:12.45)
$durationRaw = ($durationLine -split "Duration: ")[1] -split ", start" | Select-Object -First 1
$durationRaw = $durationRaw.Trim()

# Zerlege die Dauer in Stunden, Minuten und Sekunden (ohne Dezimalstellen)
$parts = $durationRaw -split ":"
$hours   = [int]$parts[0]
$minutes = [int]$parts[1]
$secondsPart = ($parts[2] -split "\.")[0]
$seconds = [int]$secondsPart
$durationSeconds = ($hours * 3600) + ($minutes * 60) + $seconds

Write-Output "Gesamtdauer: $durationSeconds Sekunden ($durationRaw)"

# Schritt 2: Für jeden Startoffset (in Minuten) wird das Tail- und Head-Segment getrennt codiert und anschließend zusammengefügt.
for ($i = 2; $i -le 20; $i += 2) {

    # Berechne Zeiten in Sekunden
    $startSeconds = $i * 60
    $tailDuration = $durationSeconds - $startSeconds   # Tail: vom Offset bis zum Ende
    $headDuration = $startSeconds                       # Head: vom Start bis zum Offset

    # Definiere temporäre Dateinamen
    $tempTail = "temp_tail_${i}.mkv"
    $tempHead = "temp_head_${i}.mkv"
    $listFile = "list_${i}.txt"
    $outputFile = "VHS_${i}.mkv"
    
    Write-Output "Erstelle temporäres Tail-Segment ($tailDuration Sekunden) ab $startSeconds Sekunden..."
    $cmdTail = "ffmpeg -hwaccel auto -hide_banner -y -i `"$inputFile`" -ss $startSeconds -t $tailDuration -c:v hevc_nvenc -rc constqp -qp 17 -an `"$tempTail`""
    Write-Output "Befehl: $cmdTail"
    Invoke-Expression $cmdTail

    Write-Output "Erstelle temporäres Head-Segment ($headDuration Sekunden) ab 0 Sekunden..."
    $cmdHead = "ffmpeg -hwaccel auto -hide_banner -y -i `"$inputFile`" -t $headDuration -c:v hevc_nvenc -rc constqp -qp 17 -an `"$tempHead`""
    Write-Output "Befehl: $cmdHead"
    Invoke-Expression $cmdHead

    # Erstelle eine Datei, die die zu concatierenden Dateien enthält
    $listContent = "file '$PWD\$tempTail'" + "`r`n" + "file '$PWD\$tempHead'"
    $listContent | Out-File -FilePath $listFile -Encoding ascii

    Write-Output "Füge Tail- und Head-Segment zusammen zum finalen Video $outputFile..."
    $cmdConcat = "ffmpeg -y -f concat -safe 0 -i `"$listFile`" -c copy `"$outputFile`""
    Write-Output "Befehl: $cmdConcat"
    Invoke-Expression $cmdConcat

    # Lösche temporäre Dateien
    Remove-Item $tempTail, $tempHead, $listFile -Force
    Write-Output "Fertiggestellt: $outputFile"
    Write-Output "-----------------------------"
}
