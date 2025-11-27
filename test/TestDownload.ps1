<#
.SYNOPSIS
    Script de TEST pour le module de TÉLÉCHARGEMENT.
    Valide la récupération, l'extraction et la structure de KeePassXC Portable.
#>

# --- FORCE UTF-8 ---
try { [Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding(65001) } catch {}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

# --- FONCTION À TESTER (Cœur du système) ---
function Prepare-KeePassXC {
    param([string]$DestinationPath, [System.Windows.Forms.TextBox]$logBox)

    $kpFolder = Join-Path $DestinationPath "KeePassXC"
    $kpZip   = Join-Path $DestinationPath "KeePassXC-2.7.9-Win64.zip"
    # Lien en dur vers la version certifiée
    $url     = "https://github.com/keepassxreboot/keepassxc/releases/download/2.7.9/KeePassXC-2.7.9-Win64.zip"
    
    # 1. Vérification si déjà installé
    if (Test-Path "$kpFolder\keepassxc-cli.exe") {
        $logBox.Text += "`r`n[INFO] Dossier KeePassXC d$([char]0x00E9)j$([char]0x00E0) pr$([char]0x00E9)sent."
        $logBox.Text += "`r`n   -> Chemin : $kpFolder"
        return $kpFolder
    }

    $logBox.Text += "`r`n[INIT] KeePassXC non trouv$([char]0x00E9). Recherche du ZIP local..."
    [System.Windows.Forms.Application]::DoEvents()

    # 2. Vérification ZIP local (Fallback) ou Téléchargement
    if (-not (Test-Path $kpZip)) {
        $logBox.Text += "`r`n[TELECHARGEMENT] R$([char]0x00E9)cup$([char]0x00E9)ration de la v2.7.9 depuis GitHub..."
        [System.Windows.Forms.Application]::DoEvents()
        
        try {
            # Force TLS 1.2 pour GitHub (indispensable sur certains Windows)
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $url -OutFile $kpZip -ErrorAction Stop
            $logBox.Text += " OK."
        } catch {
            throw "Impossible de t$([char]0x00E9)l$([char]0x00E9)charger KeePassXC. Erreur : $_"
        }
    } else {
        $logBox.Text += " ZIP trouv$([char]0x00E9) localement (Fallback activ$([char]0x00E9))."
    }

    # 3. Extraction
    $logBox.Text += "`r`n[EXTRACTION] D$([char]0x00E9)compression en cours..."
    [System.Windows.Forms.Application]::DoEvents()
    
    try {
        $tempExtract = Join-Path $DestinationPath "KP_TEMP"
        if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force }
        
        [System.IO.Compression.ZipFile]::ExtractToDirectory($kpZip, $tempExtract)
        
        # Le zip contient souvent un sous-dossier, on le remonte pour avoir test/KeePassXC/keepassxc.exe
        $subFolder = Get-ChildItem -Path $tempExtract -Directory | Select-Object -First 1
        Move-Item -Path $subFolder.FullName -Destination $kpFolder -Force
        
        Remove-Item $tempExtract -Recurse -Force
        $logBox.Text += " Termin$([char]0x00E9)e."
        return $kpFolder
    } catch {
        throw "Erreur lors de l'extraction : $_"
    }
}

# --- INTERFACE DE TEST ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "TEST UNITAIRE - Téléchargement KeePassXC"
$form.Size = New-Object System.Drawing.Size(600, 500)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

$lblInfo = New-Object System.Windows.Forms.Label
$lblInfo.Text = "Ce script va tenter de télécharger et extraire KeePassXC dans ce dossier.`nS'il existe déjà, il le détectera."
$lblInfo.Location = New-Object System.Drawing.Point(20, 20)
$lblInfo.Size = New-Object System.Drawing.Size(540, 40)
$form.Controls.Add($lblInfo)

$btn = New-Object System.Windows.Forms.Button
$btn.Text = "LANCER LE TEST"; $btn.Location = New-Object System.Drawing.Point(150, 70); $btn.Size = New-Object System.Drawing.Size(300, 40); $btn.BackColor = "LightGreen"
$form.Controls.Add($btn)

$btnReset = New-Object System.Windows.Forms.Button
$btnReset.Text = "SUPPRIMER (Pour re-tester)"; $btnReset.Location = New-Object System.Drawing.Point(150, 120); $btnReset.Size = New-Object System.Drawing.Size(300, 30); $btnReset.BackColor = "LightSalmon"
$form.Controls.Add($btnReset)

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Multiline = $true; $txtLog.ScrollBars = "Vertical"; $txtLog.Location = New-Object System.Drawing.Point(20, 170); $txtLog.Size = New-Object System.Drawing.Size(540, 260); $txtLog.ReadOnly = $true
$form.Controls.Add($txtLog)

# --- ACTIONS ---

# Bouton Test
$btn.Add_Click({
    $btn.Enabled = $false; $btnReset.Enabled = $false
    $txtLog.Text = "D$([char]0x00E9)marrage du test..."
    
    try {
        # On lance la fonction dans le dossier courant du script
        $resultPath = Prepare-KeePassXC -DestinationPath $PSScriptRoot -logBox $txtLog
        
        $txtLog.Text += "`r`n`r`n[SUCC$([char]0x00C8)S] KeePassXC est pr$([char]0x00EA)t !"
        
        # Validation ultime : on vérifie que l'exe est bien là
        if (Test-Path "$resultPath\keepassxc-cli.exe") {
            $txtLog.Text += "`r`nValidation : keepassxc-cli.exe trouv$([char]0x00E9)."
            [System.Windows.Forms.MessageBox]::Show("Le module fonctionne parfaitement !", "Succès")
        } else {
            $txtLog.Text += "`r`n[BIZARRE] Le dossier est l$([char]0x00E0) mais pas l'ex$([char]0x00E9)cutable ?"
        }

    } catch {
        $txtLog.Text += "`r`n`r`n[ERREUR] $_"
        [System.Windows.Forms.MessageBox]::Show("Le test a échoué.", "Erreur", "OK", "Error")
    }
    $btn.Enabled = $true; $btnReset.Enabled = $true
})

# Bouton Reset (Nettoyage pour tester le téléchargement réel)
$btnReset.Add_Click({
    $kp = Join-Path $PSScriptRoot "KeePassXC"
    $zip = Join-Path $PSScriptRoot "KeePassXC-2.7.9-Win64.zip"
    
    if (Test-Path $kp) { Remove-Item $kp -Recurse -Force; $txtLog.Text += "`r`nDossier supprim$([char]0x00E9)." }
    if (Test-Path $zip) { Remove-Item $zip -Force; $txtLog.Text += "`r`nZIP supprim$([char]0x00E9)." }
    
    [System.Windows.Forms.MessageBox]::Show("Environnement nettoyé.`nVous pouvez relancer le test pour voir le téléchargement.", "Reset")
})

$form.Add_Shown({$form.Activate()})
[void] $form.ShowDialog()
