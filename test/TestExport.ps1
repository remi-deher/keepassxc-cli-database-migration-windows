<#
.SYNOPSIS
    Script de TEST D'EXPORTATION UNIQUEMENT.
    Permet de valider que le déverrouillage (Pwd + KeyFile + YubiKey) fonctionne.
#>
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Caractères pour affichage propre
$E_AIGU = [char]0x00E9
$E_GRAVE = [char]0x00E8

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "TEST EXPORT UNIQUEMENT"
$form.Size = New-Object System.Drawing.Size(600, 600)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

# --- Fonctions Utilitaires ---
function Create-FilePicker {
    param($y, $labelTxt, $isFolder)
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $labelTxt; $lbl.Location = New-Object System.Drawing.Point(20, $y); $lbl.Size = New-Object System.Drawing.Size(540, 20)
    $form.Controls.Add($lbl)
    $txt = New-Object System.Windows.Forms.TextBox
    $txt.Location = New-Object System.Drawing.Point(20, ($y + 25)); $txt.Size = New-Object System.Drawing.Size(450, 25)
    $form.Controls.Add($txt)
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = "..."; $btn.Location = New-Object System.Drawing.Point(480, ($y + 24)); $btn.Size = New-Object System.Drawing.Size(80, 27)
    $btn.Tag = $txt
    $btn.Add_Click({
        $linked = $this.Tag
        if ($isFolder) { $d = New-Object System.Windows.Forms.FolderBrowserDialog; if ($d.ShowDialog() -eq "OK") { $linked.Text = $d.SelectedPath } }
        else { $d = New-Object System.Windows.Forms.OpenFileDialog; if ($d.ShowDialog() -eq "OK") { $linked.Text = $d.FileName } }
    })
    $form.Controls.Add($btn)
    return $txt
}

function Run-KeePassCli-Secure {
    param([string]$exePath, [string]$arguments, [string]$password, [string]$outputFile)
    
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $exePath
    $pinfo.Arguments = $arguments
    $pinfo.UseShellExecute = $false
    $pinfo.WorkingDirectory = Split-Path -Parent $exePath
    $pinfo.RedirectStandardInput = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.RedirectStandardError = $true
    $pinfo.CreateNoWindow = $true

    # On utilise UTF-8
    $utf8 = [System.Text.Encoding]::UTF8
    try { if ($pinfo.GetType().GetProperty("StandardOutputEncoding")) { $pinfo.StandardOutputEncoding = $utf8 } } catch {}
    try { if ($pinfo.GetType().GetProperty("StandardErrorEncoding")) { $pinfo.StandardErrorEncoding = $utf8 } } catch {}

    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null

    # Injection STDIN (Méthode Clavier) pour l'export
    if (-not [string]::IsNullOrEmpty($password)) {
        $p.StandardInput.WriteLine($password)
        Start-Sleep -Milliseconds 200
    }
    $p.StandardInput.Close()

    $stdOutReader = New-Object System.IO.StreamReader($p.StandardOutput.BaseStream, $utf8)
    $content = $stdOutReader.ReadToEnd()
    $stdErrReader = New-Object System.IO.StreamReader($p.StandardError.BaseStream, $utf8)
    $err = $stdErrReader.ReadToEnd()
    $p.WaitForExit()

    if ($outputFile) { [System.IO.File]::WriteAllText($outputFile, $content, $utf8) }
    return @{ ExitCode = $p.ExitCode; Error = $err }
}

# --- UI ---
$txtSource = Create-FilePicker 20 "1. Dossier KeePassXC Portable (Source)" $true
if ($PSScriptRoot -and (Test-Path "$PSScriptRoot\KeePassXC")) { $txtSource.Text = "$PSScriptRoot\KeePassXC" }

$txtKey = Create-FilePicker 90 "2. Fichier Cl$E_AIGU (.key/.keyx)" $false

$grpYubi = New-Object System.Windows.Forms.GroupBox
$grpYubi.Text = "3. YubiKey Slot"; $grpYubi.Location = New-Object System.Drawing.Point(20, 160); $grpYubi.Size = New-Object System.Drawing.Size(540, 50)
$rb1 = New-Object System.Windows.Forms.RadioButton; $rb1.Text = "Slot 1"; $rb1.Location = New-Object System.Drawing.Point(20, 20); $rb1.Checked = $true; $grpYubi.Controls.Add($rb1)
$rb2 = New-Object System.Windows.Forms.RadioButton; $rb2.Text = "Slot 2"; $rb2.Location = New-Object System.Drawing.Point(150, 20); $grpYubi.Controls.Add($rb2)
$form.Controls.Add($grpYubi)

$lblPass = New-Object System.Windows.Forms.Label
$lblPass.Text = "4. Mot de Passe ACTUEL"; $lblPass.Location = New-Object System.Drawing.Point(20, 230); $lblPass.Size = New-Object System.Drawing.Size(540, 20)
$form.Controls.Add($lblPass)
$txtPass = New-Object System.Windows.Forms.TextBox
$txtPass.Location = New-Object System.Drawing.Point(20, 255); $txtPass.Size = New-Object System.Drawing.Size(450, 25); $txtPass.UseSystemPasswordChar = $true
$form.Controls.Add($txtPass)

$txtDest = Create-FilePicker 300 "5. Dossier de TEST (O$E_GRAVE le fichier XML sera cr$E_AIGU$E_AIGU)" $true
$desktop = [Environment]::GetFolderPath("Desktop")
$txtDest.Text = "$desktop\Test_Export_Keepass"

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Multiline = $true; $txtLog.ScrollBars = "Vertical"; $txtLog.Location = New-Object System.Drawing.Point(20, 420); $txtLog.Size = New-Object System.Drawing.Size(540, 120); $txtLog.ReadOnly = $true
$form.Controls.Add($txtLog)

$btn = New-Object System.Windows.Forms.Button
$btn.Text = "TESTER L'EXPORTATION XML"; $btn.Location = New-Object System.Drawing.Point(150, 370); $btn.Size = New-Object System.Drawing.Size(300, 40); $btn.BackColor = "LightGreen"
$form.Controls.Add($btn)

# --- ACTION ---
$btn.Add_Click({
    $src = $txtSource.Text; $key = $txtKey.Text; $dst = $txtDest.Text; $pwd = $txtPass.Text
    if (-not (Test-Path $src) -or -not (Test-Path $key)) { [System.Windows.Forms.MessageBox]::Show("Vérifiez les chemins.", "Erreur"); return }
    
    $btn.Enabled = $false
    $txtLog.Text = "Préparation du test..."
    [System.Windows.Forms.Application]::DoEvents()

    if (-not (Test-Path $dst)) { New-Item -ItemType Directory -Force -Path $dst | Out-Null }

    # Copie minimale pour le test
    $txtLog.Text += "`r`nCopie des fichiers de l'application vers le dossier de test..."
    Copy-Item -Path "$src\*" -Destination $dst -Recurse -Force

    $cliExe = Get-ChildItem -Path $dst -Filter "keepassxc-cli.exe" -Recurse | Select-Object -First 1
    $dbFile = Get-ChildItem -Path $dst -Filter "*.kdbx" -Recurse | Select-Object -First 1

    if (-not $cliExe -or -not $dbFile) { $txtLog.Text += "`r`nERREUR: Exécutable ou DB non trouvés."; return }

    $slot = if ($rb2.Checked) { 2 } else { 1 }
    $xmlOut = Join-Path $dst "export_test_result.xml"

    $txtLog.Text += "`r`nLancement de l'export... Tenez-vous prêt à toucher la YubiKey !"
    [System.Windows.Forms.Application]::DoEvents()

    $args = "export -k `"$key`" -y $slot `"$($dbFile.FullName)`""
    
    # Appel CLI
    $res = Run-KeePassCli-Secure -exePath $cliExe.FullName -arguments $args -password $pwd -outputFile $xmlOut

    if ($res.ExitCode -eq 0) {
        $txtLog.Text += "`r`nSUCCÈS ! Code de sortie 0."
        if (Test-Path $xmlOut) {
            $size = (Get-Item $xmlOut).Length
            $txtLog.Text += "`r`nFichier XML généré : $xmlOut"
            $txtLog.Text += "`r`nTaille du fichier : $size octets"
            if ($size -gt 0) {
                [System.Windows.Forms.MessageBox]::Show("Export réussi !`nLe fichier XML contient des données ($size octets).", "Succès")
                Invoke-Item $dst # Ouvre le dossier pour vérifier
            } else {
                [System.Windows.Forms.MessageBox]::Show("Export réussi MAIS le fichier est vide (0 octets).`nProblème de déchiffrement silencieux ?", "Attention", "OK", "Warning")
            }
        }
    } else {
        $txtLog.Text += "`r`nÉCHEC. Code de sortie : $($res.ExitCode)"
        $txtLog.Text += "`r`nErreur : $($res.Error)"
        [System.Windows.Forms.MessageBox]::Show("L'export a échoué. Regardez les logs.", "Echec", "OK", "Error")
    }
    $btn.Enabled = $true
})

$form.Add_Shown({$form.Activate()})
[void] $form.ShowDialog()