<#
.SYNOPSIS
    Bibliothèque de fonctions communes.
    Contient : Prepare-KeePassXC, Run-Cli-Safe, Get-YubiKeySerial, UI Helpers
#>

# --- CONFIGURATION ---
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
$OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

# --- GESTION KEEPASSXC ---
function Prepare-KeePassXC {
    param([string]$DestinationPath, [System.Windows.Forms.Label]$statusLabel)

    if ([string]::IsNullOrEmpty($DestinationPath)) { $DestinationPath = $PWD.Path }
    $kpFolder = Join-Path $DestinationPath "KeePassXC"
    $kpZip    = Join-Path $DestinationPath "KeePassXC-2.7.9-Win64.zip"
    $url      = "https://github.com/keepassxreboot/keepassxc/releases/download/2.7.9/KeePassXC-2.7.9-Win64.zip"
    
    if (Test-Path "$kpFolder\keepassxc-cli.exe") { 
        if ($statusLabel) { $statusLabel.Text = "Vérification..." }
        return $kpFolder 
    }

    if ($statusLabel) { $statusLabel.Text = "Téléchargement (v2.7.9)..."; [System.Windows.Forms.Application]::DoEvents() }
    if (-not (Test-Path $kpZip)) {
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $url -OutFile $kpZip -ErrorAction Stop
        } catch { throw "ERREUR TELECHARGEMENT : $_" }
    }

    if ($statusLabel) { $statusLabel.Text = "Extraction..."; [System.Windows.Forms.Application]::DoEvents() }
    try {
        $tempExtract = Join-Path $DestinationPath "KP_TEMP"
        if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force }
        [System.IO.Compression.ZipFile]::ExtractToDirectory($kpZip, $tempExtract)
        $subFolder = Get-ChildItem -Path $tempExtract -Directory | Select-Object -First 1
        Move-Item -Path $subFolder.FullName -Destination $kpFolder -Force
        Remove-Item $tempExtract -Recurse -Force
        return $kpFolder
    } catch { throw "Erreur extraction : $_" }
}

# --- DETECTION YUBIKEY ---
function Get-YubiKeySerial {
    try {
        $dev = Get-PnpDevice -PresentOnly -Class USB -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -match 'USB\\VID_1050&PID_.*\\\d+$' } | Select-Object -First 1
        if ($dev) { return $dev.InstanceId.Split('\')[-1] }
    } catch {}

    $paths = @("C:\Program Files\Yubico\YubiKey Manager\ykman.exe", "C:\Program Files (x86)\Yubico\YubiKey Manager\ykman.exe", "$env:LOCALAPPDATA\Programs\Yubico\YubiKey Manager\ykman.exe")
    foreach ($path in $paths) {
        if (Test-Path $path) {
            try {
                $pInfo = New-Object System.Diagnostics.ProcessStartInfo; $pInfo.FileName = $path; $pInfo.Arguments = "list --serials"; $pInfo.RedirectStandardOutput = $true; $pInfo.UseShellExecute = $false; $pInfo.CreateNoWindow = $true
                $p = [System.Diagnostics.Process]::Start($pInfo); $p.WaitForExit()
                $out = $p.StandardOutput.ReadToEnd()
                if ($out -match "\d+") { return $out.Trim().Split("`n")[0].Trim() }
            } catch {}
        }
    }
    return $null
}

# --- FONCTION EXECUTION SECURISEE (VERSION STDIN FORCE) ---
function Run-Cli-Safe {
    param(
        [string]$exe,
        [string]$argsLine,
        [string]$pwdToUnlock,   # Si défini -> Env Var (ne pas utiliser si ça bug)
        [string]$stdinInput,    # Si défini -> Injecté via Pipe (Comme clavier)
        [string]$outFile,
        [bool]$showWindow = $false,
        [System.Windows.Forms.TextBox]$logBox = $null
    )
    
    # LOG
    if ($logBox) {
        $msg = "`r`n--- EXECUTION ---"
        $msg += "`r`nCMD : $exe $argsLine"
        if ($stdinInput) { $msg += "`r`nSTDIN : [DONNEES INJECTEES]" }
        $logBox.AppendText($msg)
        [System.Windows.Forms.Application]::DoEvents()
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exe
    $psi.Arguments = $argsLine
    $psi.UseShellExecute = $false
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    
    # Force UTF-8 pour éviter les bugs d'encodage de mot de passe
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8
    # Note: StandardInputEncoding n'est pas toujours dispo en PS 5.1, on gère via le StreamWriter

    $psi.CreateNoWindow = (-not $showWindow)

    # Env Var (Optionnel)
    if (-not [string]::IsNullOrEmpty($pwdToUnlock)) { $env:KEEPASSXC_PASSWORD = $pwdToUnlock }

    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $psi
    $p.Start() | Out-Null

    # Injection STDIN (C'est ici qu'on "tape" le mot de passe)
    if (-not [string]::IsNullOrEmpty($stdinInput)) {
        # On utilise un StreamWriter qui force l'UTF8
        $writer = New-Object System.IO.StreamWriter($p.StandardInput.BaseStream, [System.Text.Encoding]::UTF8)
        $writer.AutoFlush = $true
        
        $lines = $stdinInput -split "`n"
        foreach ($line in $lines) {
            $writer.WriteLine($line)
            Start-Sleep -Milliseconds 100 # Pause pour laisser KeePassXC respirer
        }
        $writer.Close()
    } else {
        $p.StandardInput.Close()
    }

    $stdOut = $p.StandardOutput.ReadToEnd()
    $stdErr = $p.StandardError.ReadToEnd()
    $p.WaitForExit()

    $env:KEEPASSXC_PASSWORD = $null

    if ($outFile -and $p.ExitCode -eq 0) {
        if (-not [string]::IsNullOrEmpty($stdOut)) {
            [System.IO.File]::WriteAllText($outFile, $stdOut, [System.Text.Encoding]::UTF8)
        }
    }

    return @{ ExitCode = $p.ExitCode; Output = $stdOut; Error = $stdErr }
}

# --- UI HELPERS ---
function Generate-Password { return -join ((33..126) | Get-Random -Count 20 | % {[char]$_}) }

function Create-FilePicker {
    param($form, $y, $labelTxt, $isFolder, $readOnly=$false, [scriptblock]$onConfirm=$null)
    $lbl=New-Object System.Windows.Forms.Label; $lbl.Text=$labelTxt; $lbl.Location=New-Object System.Drawing.Point(20,$y); $lbl.Size=New-Object System.Drawing.Size(540,20); $form.Controls.Add($lbl)
    $txt=New-Object System.Windows.Forms.TextBox; $txt.Location=New-Object System.Drawing.Point(20,($y+25)); $txt.Size=New-Object System.Drawing.Size(450,25); $txt.ReadOnly=$readOnly; $form.Controls.Add($txt)
    if(-not $readOnly){
        $btn=New-Object System.Windows.Forms.Button; $btn.Text="..."; $btn.Location=New-Object System.Drawing.Point(480,($y+24)); $btn.Size=New-Object System.Drawing.Size(80,27)
        $act={$s=$null; if($isFolder){$d=New-Object System.Windows.Forms.FolderBrowserDialog;if($d.ShowDialog()-eq"OK"){$s=$d.SelectedPath}}else{$d=New-Object System.Windows.Forms.OpenFileDialog;if($d.ShowDialog()-eq"OK"){$s=$d.FileName}}; if($s){$txt.Text=$s; if($onConfirm){& $onConfirm}}}
        $btn.Add_Click($act.GetNewClosure()); $form.Controls.Add($btn)
    }
    return $txt
}