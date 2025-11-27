try { [Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding(65001) } catch {}
Write-Host "--- DIAGNOSTIC YUBIKEY ---" -ForegroundColor Cyan

# On cherche TOUT ce qui vient de Yubico (VID_1050), peu importe la classe
$devs = Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -like '*VID_1050*' }

if ($devs) {
    Write-Host "Périphériques Yubico trouvés :" -ForegroundColor Green
    foreach ($d in $devs) {
        Write-Host "--------------------------------"
        Write-Host "Nom       : $($d.FriendlyName)"
        Write-Host "Classe    : $($d.Class)"
        Write-Host "ID Brut   : $($d.InstanceId)"
        
        # Analyse du Serial
        $parts = $d.InstanceId.Split('\')
        $potentialSerial = $parts[-1]
        
        # Est-ce que la fin est composée uniquement de chiffres ?
        if ($potentialSerial -match '^\d+$') {
            Write-Host "-> SERIAL VISIBLE : $potentialSerial" -ForegroundColor Yellow
        } else {
            Write-Host "-> SERIAL MASQUÉ (ID générique Windows)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "AUCUN périphérique Yubico détecté." -ForegroundColor Red
}

Write-Host "`nAppuyez sur une touche..."
[void][System.Console]::ReadKey()