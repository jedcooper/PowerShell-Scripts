# Voraussetzung: FFmpeg ist im Systempfad
$inputFile = "fehler_vhs.MXF"

# Schritt 1: Gesamtdauer des Videos ermitteln
$durationLine = ffmpeg -i $inputFile 2>&1 | Select-String "Duration"
if (-not $durationLine) {
    Write-Error "Videolänge konnte nicht ermittelt werden."
    exit
}
# Extrahiere die Dauer (Format: 00:40:12.45) aus der Zeile
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

# Schritt 2: Für jeden Startoffset ein zirkuläres Video (ohne Audio) erstellen
for ($i = 2; $i -le 20; $i += 2) {
    $startSeconds = $i * 60
    # Dauer des Tail-Segments (vom Offset bis Ende)
    $tailDuration = $durationSeconds - $startSeconds
    # Dauer des Head-Segments (vom Anfang bis Offset)
    $headDuration = $startSeconds

    # FFmpeg filter_complex zum Extrahieren und Concatenieren der Segmente (nur Video)
    $filter = "[0:v]trim=start=${startSeconds}:duration=${tailDuration},setpts=PTS-STARTPTS[v1];" +
              "[0:v]trim=start=0:duration=${headDuration},setpts=PTS-STARTPTS[v2];" +
              "[v1][v2]concat=n=2:v=1:a=0[outv]"

    $outputFile = "VHS_$i.mkv"
    
    # Der FFmpeg-Befehl: Hier wird NVENC im constqp-Modus mit QP 18 verwendet.
    $command = "ffmpeg -hwaccel auto -hide_banner -y -i `"$inputFile`" -filter_complex `"$filter`" -map `"[outv]`" -c:v hevc_nvenc -qp 17 `"$outputFile`""
    
    Write-Output "Erstelle $outputFile mit Startoffset $i Minute(n)..."
    Write-Output "Befehl: $command"
    Invoke-Expression $command
}