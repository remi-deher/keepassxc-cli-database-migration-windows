@echo off
:: Force le dossier de travail au dossier du script
cd /d "%~dp0"

echo Demarrage de l'assistant de migration...
echo.

:: Lance PowerShell en pointant vers le dossier lib
:: Notez le chemin "lib\Launcher.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "lib\Launcher.ps1"

:: Pause en cas d'erreur critique pour lire le message (si le launcher plante au démarrage)
if %errorlevel% neq 0 pause