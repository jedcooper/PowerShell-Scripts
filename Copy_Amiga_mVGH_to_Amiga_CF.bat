rem Quelle und Ziel anpassen
set "SRC=J:\Retro\ROMs\Commodore\Amiga\mVGH"
set "DST=I:\mVGH"

rem Wenn alles gut aussieht -> echtes Kopieren
robocopy "%SRC%" "%DST%" /E /XD Manual Tools /R:2 /W:5 /COPY:DAT /DCOPY:DA
pause
