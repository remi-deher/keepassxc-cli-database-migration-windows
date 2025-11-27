# --- SCRIPT DE DIAGNOSTIC KEEPASSXC (v2 - Non Bloquant) ---
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

# 1. Configuration
$kpDir = "$PWD\KeePassXC" 
if (-not (Test-Path "$kpDir\keepassxc-cli.exe")) {
    $kpDir = "C:\Program Files\KeePassXC" # Chemin par défaut
    if (-not (Test-Path "$kpDir\keepassxc-cli.exe")) {
        $kpDir = Read-Host "Dossier contenant keepassxc-cli.exe"
    }
}
$cli = "$kpDir\keepassxc-cli.exe"
if (-not (Test-Path $cli)) { Write-Host "Exécutable introuvable !" -F Red; pause; exit }

Write-Host "`n=== PARAMETRES ===" -F Cyan
$db = (Read-Host "Chemin de la base .kdbx").Trim('"').Trim("'")
$pwd = Read-Host "Mot de passe" -AsSecureString
$pwdClear = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwd))

$keyFile = (Read-Host "Chemin Fichier Clé (Entrée si aucun)").Trim('"').Trim("'")
$serial = (Read-Host "Serial YubiKey (ex: 18138709)").Trim()

function Test-Unlock {
    param($slot, $useKey, $desc)
    Write-Host "`n------------------------------------------------"
    Write-Host "TEST : $desc" -F Yellow
    
    $argsList = @("ls", "`"$db`"")
    if ($useKey -and $keyFile) { $argsList += "-k"; $argsList += "`"$keyFile`"" }
    
    if ($slot) {
        $yArg = "-y $slot"
        if ($serial) { $yArg += ":$serial" }
        $argsList += $yArg
    }

    $env:KEEPASSXC_PASSWORD = $pwdClear
    
    # On lance en mode visible pour que vous voyiez les erreurs ou les demandes de la YubiKey
    $p = Start-Process -FilePath $cli -ArgumentList $argsList -NoNewWindow -PassThru -Wait
    
    $env:KEEPASSXC_PASSWORD = $null

    if ($p.ExitCode -eq 0) {
        Write-Host "`n[SUCCES] COMBINAISON GAGNANTE !" -F Green -BackgroundColor Black
        return $true
    } else {
        Write-Host "`n[ECHEC] Code sortie : $($p.ExitCode)" -F Red
        return $false
    }
}

Write-Host "`n=== LANCEMENT DES TESTS ===" -F Cyan

# 1. Test YubiKey SLOT 1 (Le plus probable si Slot 2 échoue)
if ($serial) {
    if ($keyFile) { Test-Unlock 1 $true "YubiKey SLOT 1 + Mot de passe + Fichier Clé" }
    Test-Unlock 1 $false "YubiKey SLOT 1 + Mot de passe (Sans Fichier Clé)"
    
    # 2. Test YubiKey SLOT 2
    if ($keyFile) { Test-Unlock 2 $true "YubiKey SLOT 2 + Mot de passe + Fichier Clé" }
    Test-Unlock 2 $false "YubiKey SLOT 2 + Mot de passe (Sans Fichier Clé)"
}

Write-Host "`n--- FIN ---"
pause