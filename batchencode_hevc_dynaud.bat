@echo off
setlocal enabledelayedexpansion

REM ------------------------------------------------------------
REM   Usage: convert.bat "C:\Pfad\Zum\Verzeichnis"
REM ------------------------------------------------------------
if "%~1"=="" (
    echo Bitte Verzeichnis angeben.
    echo Beispiel: convert.bat "C:\Videos\ToConvert"
    pause
    exit /b 1
)

REM Eingabeverzeichnis aus Parameter
set "INPUT_DIR=%~1"

REM Ausgabeverzeichnis
set "OUTPUT_DIR=%INPUT_DIR%\converted_mkv"
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

REM Konfigurierbare Parameter
set "CRF=18"                       REM HEVC CRF (empfohlen 18–20)
set "PRESET=p4"                    REM NVENC-Preset (p1..p7)
set "AUDIO_BITRATE=192k"           REM AAC-Bitrate
set "DYNANORM=dynaudnorm=f=150:g=13"

echo.
echo Starte Konvertierung aller Video-Dateien in "%INPUT_DIR%"
echo Ausgabe nach "%OUTPUT_DIR%"
echo.

REM Liste der zu durchsuchenden Erweiterungen
set "EXTS=mp4 mkv avi mov flv webm wmv mpg mpeg"

for %%E in (%EXTS%) do (
  for %%F in ("%INPUT_DIR%\*.%%E") do (
    if exist "%%F" (
      set "FILENAME=%%~nF"
      echo Verarbeite "%%~nxF" ...

      ffmpeg -y ^
        -hwaccel cuda -hwaccel_output_format cuda -i "%%F" ^
        -filter_complex ^
          "[0:v]hwdownload,format=nv12,scale=1280:-2:flags=lanczos,hwupload_cuda[v]" ^
        -map "[v]" -map 0:a ^
        -c:v hevc_nvenc -rc vbr -cq %CRF% -tune hq -preset %PRESET% -rc-lookahead 32 ^
        -c:a aac -b:a %AUDIO_BITRATE% -ac 2 -filter:a "%DYNANORM%" ^
        "%OUTPUT_DIR%\!FILENAME!_hevc.mkv"

      echo.
    )
  )
)

echo Alle Dateien sind fertig konvertiert.
pause