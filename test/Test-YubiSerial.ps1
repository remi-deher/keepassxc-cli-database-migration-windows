# --- Script de Test Autonome pour YubiKey ---
# Force l'encodage pour les accents
try { [Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding(65001) } catch {}

Write-Host "--- TEST DE DETECTION YUBIKEY ---" -ForegroundColor Cyan
Write-Host "Recherche en cours..."

# Fonction de détection (La même que celle intégrée dans votre projet)
function Get-YubiKeySerial {
    try {
        # VID_1050 = Yubico
        # On cherche un périphérique USB actif correspondant à Yubico
        $yubiDevice = Get-PnpDevice -PresentOnly -Class USB -ErrorAction SilentlyContinue | 
                      Where-Object { $_.InstanceId -match 'USB\\VID_1050&PID_.*\\\d+$' } | 
                      Select-Object -First 1
        
        if ($yubiDevice) {
            # L'InstanceId ressemble à : USB\VID_1050&PID_0407\12345678
            # Le serial est la dernière partie
            return $yubiDevice.InstanceId.Split('\')[-1]
        }
    } catch {
        Write-Warning "Erreur lors de l'exécution de la commande WMI/PnP."
        Write-Warning $_
    }
    return $null
}

# Exécution du test
$serial = Get-YubiKeySerial

if ($serial) {
    Write-Host "`n[SUCCES] YubiKey détectée !" -ForegroundColor Green
    Write-Host "Numéro de Série : $serial" -ForegroundColor Yellow
} else {
    Write-Host "`n[ECHEC] Aucune YubiKey détectée." -ForegroundColor Red
    Write-Host "Vérifiez que :"
    Write-Host "1. La clé est bien branchée."
    Write-Host "2. Ce n'est pas une 'Security Key' bleue (qui n'a pas de serial lisible)."
    Write-Host "3. Vous n'êtes pas sur une machine virtuelle qui bloque l'USB."
}

Write-Host "`nAppuyez sur une touche pour quitter..."
[void][System.Console]::ReadKey()