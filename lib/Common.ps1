<#
.SYNOPSIS
    Bibliothèque de fonctions communes.
    Contient : Prepare-KeePassXC, Run-KeePassCli, UI Helpers
#>

# --- FORCE UTF-8 & VARIABLES CARACTERES ---
try { [Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding(65001) } catch {}
$script:E_AIGU = [char]0x00E9
$script:E_GRAVE = [char]0x00E8
$script:E_CIRC = [char]0x00EA
$script:A_GRAVE = [char]0x00E0

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
        if ($statusLabel) { $statusLabel.Text = "V$script:E_AIGU" + "rification..." }
        return $kpFolder 
    }

    if ($statusLabel) { $statusLabel.Text = "T$script:E_AIGU" + "l$script:E_AIGU" + "chargement (v2.7.9)..."; [System.Windows.Forms.Application]::DoEvents() }

    if (-not (Test-Path $kpZip)) {
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $proxy = [Net.WebRequest]::GetSystemWebProxy()
            $proxy.Credentials = [Net.CredentialCache]::DefaultCredentials
            [Net.WebRequest]::DefaultWebProxy = $proxy
            Invoke-WebRequest -Uri $url -OutFile $kpZip -ErrorAction Stop
        } catch {
            throw "ERREUR T$script:E_AIGU" + "LECHARGEMENT : $_`n`nVerifiez internet ou mettez le ZIP manuellement."
        }
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
    } catch {
        throw "Erreur extraction : $_"
    }
}

# Fonction Robuste pour CLI (Mode Interactif pour YubiKey via CMD)
function Run-KeePassCli-Interactive {
    param([string]$exe, [string]$arguments, [string]$pwd, [string]$outputFile=$null)
    
    $batFile = [System.IO.Path]::GetTempFileName() + ".bat"
    
    $cmdLine = "`"$exe`" $arguments"
    if ($outputFile) { $cmdLine += " > `"$outputFile`"" }
    
    # Création du BAT qui injecte le mot de passe et pause si erreur
    $batContent = @"
@echo off
set KEEPASSXC_PASSWORD=$pwd
echo.
echo ----------------------------------------------------
echo Commande en cours... 
echo SI UNE YUBIKEY EST REQUISE, TOUCHEZ-LA MAINTENANT !
echo ----------------------------------------------------
echo.
$cmdLine
if %errorlevel% neq 0 (
    echo.
    echo [ERREUR] La commande a echoue (Code %errorlevel%).
    echo Lisez le message ci-dessus.
    pause
    exit /b %errorlevel%
)
exit /b 0
"@
    [System.IO.File]::WriteAllText($batFile, $batContent, [System.Text.Encoding]::Default)

    # Lancement visible pour que l'utilisateur voit la demande YubiKey
    $p = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$batFile`"" -PassThru -Wait -WindowStyle Normal
    
    Remove-Item $batFile -Force -ErrorAction SilentlyContinue
    return $p.ExitCode
}

# Fonction Silencieuse (Pour les commandes simples sans YubiKey)
function Run-KeePassCli-Silent {
    param([string]$exe, [string]$arguments, [string]$stdinPass)
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $exe; $pinfo.Arguments = $arguments
    $pinfo.UseShellExecute = $false; $pinfo.CreateNoWindow = $true
    $pinfo.RedirectStandardInput = $true; $pinfo.RedirectStandardOutput = $true; $pinfo.RedirectStandardError = $true
    $pinfo.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $pinfo.EnvironmentVariables["KEEPASSXC_PASSWORD"] = $stdinPass

    $p = New-Object System.Diagnostics.Process; $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    if ($stdinPass) { $p.StandardInput.WriteLine($stdinPass); $p.StandardInput.Close() }
    $out = $p.StandardOutput.ReadToEnd(); $err = $p.StandardError.ReadToEnd(); $p.WaitForExit()
    return @{ ExitCode = $p.ExitCode; Output = $out; Error = $err }
}

# --- UI HELPERS ---

function Generate-Password { return -join ((33..126) | Get-Random -Count 20 | % {[char]$_}) }

function Create-FilePicker {
    param($form, $y, $labelTxt, $isFolder, $readOnly=$false, [scriptblock]$onConfirm=$null)
    $lbl=New-Object System.Windows.Forms.Label; $lbl.Text=$labelTxt; $lbl.Location=New-Object System.Drawing.Point(20,$y); $lbl.Size=New-Object System.Drawing.Size(540,20); $form.Controls.Add($lbl)
    $txt=New-Object System.Windows.Forms.TextBox; $txt.Location=New-Object System.Drawing.Point(20,($y+25)); $txt.Size=New-Object System.Drawing.Size(450,25); $txt.ReadOnly=$readOnly; $form.Controls.Add($txt)
    if(-not $readOnly){
        $btn=New-Object System.Windows.Forms.Button; $btn.Text="..."; $btn.Location=New-Object System.Drawing.Point(480,($y+24)); $btn.Size=New-Object System.Drawing.Size(80,27)
        # Closure pour capturer les variables correctement
        $act={$s=$null; if($isFolder){$d=New-Object System.Windows.Forms.FolderBrowserDialog;if($d.ShowDialog()-eq"OK"){$s=$d.SelectedPath}}else{$d=New-Object System.Windows.Forms.OpenFileDialog;if($d.ShowDialog()-eq"OK"){$s=$d.FileName}}; if($s){$txt.Text=$s; if($onConfirm){& $onConfirm}}}
        $btn.Add_Click($act.GetNewClosure()); $form.Controls.Add($btn)
    }
    return $txt
}

function Show-DebugWindow {
    param([string]$c, [string]$t)
    $f=New-Object System.Windows.Forms.Form; $f.Text="DEBUG - $c"; $f.Size=New-Object System.Drawing.Size(600,300); $f.StartPosition="CenterParent"
    $bx=New-Object System.Windows.Forms.TextBox; $bx.Multiline=$true; $bx.Text=$t; $bx.Location=New-Object System.Drawing.Point(10,10); $bx.Size=New-Object System.Drawing.Size(560,180); $f.Controls.Add($bx)
    $b=New-Object System.Windows.Forms.Button; $b.Text="Fermer"; $b.Location=New-Object System.Drawing.Point(250,210); $b.Add_Click({$f.Close()}); $f.Controls.Add($b); [void]$f.ShowDialog()
}