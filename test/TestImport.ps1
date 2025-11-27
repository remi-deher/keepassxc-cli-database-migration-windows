<#
.SYNOPSIS
    Script de TEST D'IMPORTATION UNIQUEMENT.
    Permet de valider la création d'une nouvelle base à partir d'un XML.
#>

# Corrige les caractères "├®" dans la console
try { [Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding(65001) } catch {}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "TEST IMPORT (Correction Arguments & UTF-8)"
$form.Size = New-Object System.Drawing.Size(700, 700)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

# --- Fonctions Utilitaires ---
function Create-FilePicker {
    param($y, $labelTxt, $isFolder)
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $labelTxt; $lbl.Location = New-Object System.Drawing.Point(20, $y); $lbl.Size = New-Object System.Drawing.Size(640, 20)
    $form.Controls.Add($lbl)
    $txt = New-Object System.Windows.Forms.TextBox
    $txt.Location = New-Object System.Drawing.Point(20, ($y + 25)); $txt.Size = New-Object System.Drawing.Size(550, 25)
    $form.Controls.Add($txt)
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = "..."; $btn.Location = New-Object System.Drawing.Point(580, ($y + 24)); $btn.Size = New-Object System.Drawing.Size(80, 27)
    $btn.Tag = $txt
    $btn.Add_Click({
        $linked = $this.Tag
        if ($isFolder) { $d = New-Object System.Windows.Forms.FolderBrowserDialog; if ($d.ShowDialog() -eq "OK") { $linked.Text = $d.SelectedPath } }
        else { $d = New-Object System.Windows.Forms.OpenFileDialog; $d.Filter = "Fichiers XML (*.xml)|*.xml|Tous (*.*)|*.*"; if ($d.ShowDialog() -eq "OK") { $linked.Text = $d.FileName } }
    })
    $form.Controls.Add($btn)
    return $txt
}

# --- Fonction ULTIME d'exécution ---
function Run-KeePassCli-Hybrid {
    param([string]$exePath, [string]$arguments, [string]$password)
    
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $exePath
    $pinfo.Arguments = $arguments
    $pinfo.UseShellExecute = $false
    $pinfo.WorkingDirectory = Split-Path -Parent $exePath
    
    $pinfo.RedirectStandardInput = $true 
    $pinfo.RedirectStandardOutput = $true
    $pinfo.RedirectStandardError = $true
    $pinfo.CreateNoWindow = $true

    # 1. On définit la variable d'environnement (Méthode silencieuse)
    if (-not [string]::IsNullOrEmpty($password)) {
        if ($pinfo.EnvironmentVariables.ContainsKey("KEEPASSXC_PASSWORD")) {
            $pinfo.EnvironmentVariables["KEEPASSXC_PASSWORD"] = $password
        } else {
            $pinfo.EnvironmentVariables.Add("KEEPASSXC_PASSWORD", $password)
        }
    }

    $utf8 = [System.Text.Encoding]::UTF8
    try { if ($pinfo.GetType().GetProperty("StandardOutputEncoding")) { $pinfo.StandardOutputEncoding = $utf8 } } catch {}
    try { if ($pinfo.GetType().GetProperty("StandardErrorEncoding")) { $pinfo.StandardErrorEncoding = $utf8 } } catch {}

    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null

    # 2. On injecte AUSSI via Stdin (Ceinture + Bretelles)
    # IMPORTANT : Avec -p, KeePassXC VA demander le mot de passe interactivement.
    if (-not [string]::IsNullOrEmpty($password)) {
        # Saisie 1 : Mot de passe
        $p.StandardInput.WriteLine($password)
        Start-Sleep -Milliseconds 500
        
        # Saisie 2 : Confirmation (car -p le demande)
        $p.StandardInput.WriteLine($password)
    }
    # On ferme l'entrée immédiatement après
    $p.StandardInput.Close()

    $stdOutReader = New-Object System.IO.StreamReader($p.StandardOutput.BaseStream, $utf8)
    $content = $stdOutReader.ReadToEnd()
    $stdErrReader = New-Object System.IO.StreamReader($p.StandardError.BaseStream, $utf8)
    $err = $stdErrReader.ReadToEnd()
    $p.WaitForExit()

    return @{ ExitCode = $p.ExitCode; Error = $err; Output = $content }
}

# --- UI ---
$txtApp = Create-FilePicker 20 "1. Dossier KeePassXC (Contenant keepassxc-cli.exe)" $true
if ($PSScriptRoot -and (Test-Path "$PSScriptRoot\KeePassXC")) { $txtApp.Text = "$PSScriptRoot\KeePassXC" }

$txtXml = Create-FilePicker 90 "2. Fichier XML source (Celui exporté)" $false

$lblPass = New-Object System.Windows.Forms.Label
$lblPass.Text = "3. Nouveau Mot de Passe"; $lblPass.Location = New-Object System.Drawing.Point(20, 160); $lblPass.Size = New-Object System.Drawing.Size(640, 20)
$form.Controls.Add($lblPass)
$txtPass = New-Object System.Windows.Forms.TextBox
$txtPass.Location = New-Object System.Drawing.Point(20, 185); $txtPass.Size = New-Object System.Drawing.Size(550, 25); $txtPass.UseSystemPasswordChar = $false 
$form.Controls.Add($txtPass)

$btn = New-Object System.Windows.Forms.Button
$btn.Text = "TESTER L'IMPORTATION"; $btn.Location = New-Object System.Drawing.Point(200, 240); $btn.Size = New-Object System.Drawing.Size(300, 40); $btn.BackColor = "LightBlue"
$form.Controls.Add($btn)

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Multiline = $true; $txtLog.ScrollBars = "Vertical"; $txtLog.Location = New-Object System.Drawing.Point(20, 300); $txtLog.Size = New-Object System.Drawing.Size(640, 120); $txtLog.ReadOnly = $true
$form.Controls.Add($txtLog)

# --- Zone Commande Brute ---
$lblCmd = New-Object System.Windows.Forms.Label
$lblCmd.Text = "Commande Manuelle (Format Tableau - Anti ''Trop d'arguments'') :"; $lblCmd.Location = New-Object System.Drawing.Point(20, 440); $lblCmd.Size = New-Object System.Drawing.Size(640, 20)
$form.Controls.Add($lblCmd)

$txtCmdDebug = New-Object System.Windows.Forms.TextBox
$txtCmdDebug.Multiline = $true; $txtCmdDebug.Location = New-Object System.Drawing.Point(20, 465); $txtCmdDebug.Size = New-Object System.Drawing.Size(640, 80); $txtCmdDebug.ReadOnly = $true
$form.Controls.Add($txtCmdDebug)

$btnCopy = New-Object System.Windows.Forms.Button
$btnCopy.Text = "COPIER LA COMMANDE"; $btnCopy.Location = New-Object System.Drawing.Point(200, 560); $btnCopy.Size = New-Object System.Drawing.Size(300, 30); $btnCopy.BackColor = "LightGray"
$btnCopy.Add_Click({
    if (-not [string]::IsNullOrWhiteSpace($txtCmdDebug.Text)) {
        [System.Windows.Forms.Clipboard]::SetText($txtCmdDebug.Text)
        [System.Windows.Forms.MessageBox]::Show("Commande copiée !", "Info")
    }
})
$form.Controls.Add($btnCopy)

# --- ACTION ---
$btn.Add_Click({
    $appDir = $txtApp.Text; $xmlFile = $txtXml.Text; $newPwd = $txtPass.Text
    if (-not (Test-Path $appDir) -or -not (Test-Path $xmlFile)) { [System.Windows.Forms.MessageBox]::Show("Chemins invalides.", "Erreur"); return }
    if ([string]::IsNullOrWhiteSpace($newPwd)) { [System.Windows.Forms.MessageBox]::Show("Mot de passe requis.", "Erreur"); return }

    $btn.Enabled = $false
    $txtLog.Text = "Démarrage Test Import..."
    [System.Windows.Forms.Application]::DoEvents()

    $cliExe = Get-ChildItem -Path $appDir -Filter "keepassxc-cli.exe" -Recurse | Select-Object -First 1
    if (-not $cliExe) { $txtLog.Text += "`r`nErreur: keepassxc-cli.exe introuvable."; return }

    $newDbFile = Join-Path (Split-Path $xmlFile) "TEST_IMPORT_RESULT.kdbx"
    if (Test-Path $newDbFile) { Remove-Item $newDbFile -Force }

    $txtLog.Text += "`r`nCible : $newDbFile"
    [System.Windows.Forms.Application]::DoEvents()

    # AJOUT DU FLAG -p POUR FORCER LA DEMANDE DE MOT DE PASSE
    $argsString = "import -p `"$xmlFile`" `"$newDbFile`""
    
    # Mise à jour de la commande manuelle pour refléter le changement
    # Note: En manuel console, l'user tape le mot de passe, donc on ne l'injecte pas via EnvVar pour l'affichage
    $manualCmd = "& `"$($cliExe.FullName)`" import -p `"$xmlFile`" `"$newDbFile`""
    $txtCmdDebug.Text = $manualCmd

    # Appel Hybride
    $res = Run-KeePassCli-Hybrid -exePath $cliExe.FullName -arguments $argsString -password $newPwd

    if ($res.ExitCode -eq 0) {
        $txtLog.Text += "`r`nSUCCÈS !"
        if (Test-Path $newDbFile) {
            [System.Windows.Forms.MessageBox]::Show("Import réussi !", "Succès")
            $guiExe = Get-ChildItem -Path $appDir -Filter "keepassxc.exe" -Recurse | Select-Object -First 1
            if ($guiExe) { Start-Process $guiExe.FullName "`"$newDbFile`"" }
        }
    } else {
        $txtLog.Text += "`r`nÉCHEC. Code : $($res.ExitCode)"
        $txtLog.Text += "`r`nErreur : $($res.Error)"
        [System.Windows.Forms.MessageBox]::Show("L'import a échoué.", "Echec")
    }
    $btn.Enabled = $true
})

$form.Add_Shown({$form.Activate()})
[void] $form.ShowDialog()