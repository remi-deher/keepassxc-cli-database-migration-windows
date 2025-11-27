@echo off
:: Force le dossier de travail au dossier du script
cd /d "%~dp0"

echo Démarrage de l'assistant de migration...
echo.

:: Lance PowerShell sans restrictions
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "Launcher.ps1"

:: Pause en cas d'erreur critique pour lire le message
if %errorlevel% neq 0 pause