@echo off
setlocal EnableDelayedExpansion

rem === Konfiguration: Pfade anpassen =========================
set "DIR1=E:\TESTDIR1"
set "DIR2=E:\TESTDIR2"
set "DIFFROOT=E:\DIFFERENCES"
set "STAGING=%TEMP%\DiffStaging"
rem ============================================================

rem 1) Nur die UA-Dateien löschen
del /S /Q "%DIR1%\_UAEFSDB.___"
del /S /Q "%DIR2%\_UAEFSDB.___"

rem 2) Staging-Ordner neu anlegen
if exist "%STAGING%" rd /S /Q "%STAGING%"
md "%STAGING%"

rem 3) Aus DIR2: Nur die Dateien verschieben, die in DIR1 **wirklich** gelöscht wurden
for /R "%DIR2%" %%F in (*) do (
  set "full=%%~fF"
  rem relativen Pfad berechnen (ohne Laufwerk und Basispfad)
  set "rel=!full:%DIR2%\=!"
  rem Existenz in DIR1 prüfen – nur verschieben, wenn **nicht** vorhanden
  if not exist "%DIR1%\!rel!" (
    md "%STAGING%\Dir2\!rel!\.." 2>nul
    echo [STAGE] %%~fF
    move /Y "%%~fF" "%STAGING%\Dir2\!rel!" >nul
  )
)

rem 4) Aus DIR1: Nur die Dateien verschieben, die in DIR2 **wirklich** gelöscht wurden
for /R "%DIR1%" %%F in (*) do (
  set "full=%%~fF"
  set "rel=!full:%DIR1%\=!"
  if not exist "%DIR2%\!rel!" (
    md "%STAGING%\Dir1\!rel!\.." 2>nul
    echo [STAGE] %%~fF
    move /Y "%%~fF" "%STAGING%\Dir1\!rel!" >nul
  )
)

rem 5) Zeitstempel (yyyyMMdd_HHmmss)
for /F %%T in (
  'powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"'
) do set "TS=%%T"

rem 6) Differences-Ordner & ZIP-Datei definieren
md "%DIFFROOT%" 2>nul
set "ZIP=%DIFFROOT%\Differences_%TS%.zip"

rem 7) Staging in ZIP packen
powershell -NoProfile -Command ^
  "Compress-Archive -Path '%STAGING%\*' -DestinationPath '%ZIP%' -Force"

rem 8) Staging löschen
rd /S /Q "%STAGING%"

echo.
echo Archiv erstellt: %ZIP%
echo.

rem 9) Erst jetzt: Bidirektionaler Sync (nur neue/fehlende Dateien)
echo *** Sync %DIR1% -> %DIR2% ***
robocopy "%DIR1%" "%DIR2%" /E /XO /R:1 /W:1 /MT:8

echo.
echo *** Sync %DIR2% -> %DIR1% ***
robocopy "%DIR2%" "%DIR1%" /E /XO /R:1 /W:1 /MT:8

echo.
echo *** Fertig. ***
endlocal