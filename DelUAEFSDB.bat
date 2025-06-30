@echo off
set "startpfad=I:\"

echo Lösche Dateien mit dem Namen "_UAEFSDB.___" unter %startpfad% ...
for /r "%startpfad%" %%f in (_UAEFSDB.___) do (
    echo Lösche: "%%f"
    del /f /q "%%f"
)

echo Vorgang abgeschlossen.
pause