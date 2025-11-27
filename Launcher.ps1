<#
.SYNOPSIS
    Point d'entrée principal. Charge les libs et affiche le menu.
#>

# --- CHARGEMENT DES MODULES ---
$LibDir = Join-Path $PSScriptRoot "lib"

try {
    # 1. Charger les fonctions communes (Variables globales, CLI, Utils)
    . "$LibDir\Common.ps1"
    
    # 2. Charger les logiques métiers
    . "$LibDir\Export.ps1"
    . "$LibDir\Import.ps1"
} catch {
    [System.Windows.Forms.MessageBox]::Show("Erreur critique lors du chargement des fichiers 'lib' :`n$_", "Erreur Fatale")
    exit
}

# --- INTERFACE GRAPHIQUE ---
$launcher = New-Object System.Windows.Forms.Form
$launcher.Text = "Migration KeePassXC - v5.0"
$launcher.Size = New-Object System.Drawing.Size(450, 450)
$launcher.StartPosition = "CenterScreen"
$launcher.FormBorderStyle = "FixedDialog"
$launcher.MaximizeBox = $false

# Titre
$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "Assistant de Migration"
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$lblTitle.Location = New-Object System.Drawing.Point(20, 20)
$lblTitle.AutoSize = $true
$launcher.Controls.Add($lblTitle)

# Boutons
$btnInit = New-Object System.Windows.Forms.Button
$btnInit.Text = "1. VERIFIER / INSTALLER KEEPASSXC"
$btnInit.Location = New-Object System.Drawing.Point(50, 70)
$btnInit.Size = New-Object System.Drawing.Size(330, 50)
$btnInit.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$launcher.Controls.Add($btnInit)

$btnSend = New-Object System.Windows.Forms.Button
$btnSend.Text = "2. MODE EMETTEUR"
$btnSend.Location = New-Object System.Drawing.Point(50, 140)
$btnSend.Size = New-Object System.Drawing.Size(330, 70)
$btnSend.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$btnSend.Enabled = $false # Désactivé tant que Init pas fait
$launcher.Controls.Add($btnSend)

$btnRecv = New-Object System.Windows.Forms.Button
$btnRecv.Text = "3. MODE RECEPTEUR"
$btnRecv.Location = New-Object System.Drawing.Point(50, 230)
$btnRecv.Size = New-Object System.Drawing.Size(330, 70)
$btnRecv.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$btnRecv.Enabled = $false
$launcher.Controls.Add($btnRecv)

# Status
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "En attente d'initialisation..."
$lblStatus.Location = New-Object System.Drawing.Point(50, 320)
$lblStatus.AutoSize = $true
$lblStatus.ForeColor = "DimGray"
$launcher.Controls.Add($lblStatus)

# Variable globale pour stocker le chemin détecté
$script:kpGlobalPath = ""

# --- ACTIONS ---

$btnInit.Add_Click({
    try {
        $lblStatus.ForeColor = "Black"
        $script:kpGlobalPath = Prepare-KeePassXC -DestinationPath $PSScriptRoot -statusLabel $lblStatus
        
        # Si succès
        $lblStatus.Text = "PR$script:E_CIRC" + "T ! KeePassXC d$script:E_AIGU" + "tect$script:E_AIGU."
        $lblStatus.ForeColor = "Green"
        $btnSend.Enabled = $true
        $btnRecv.Enabled = $true
        $btnInit.Visible = $false # On cache le bouton init pour éviter de refaire
    } catch {
        $lblStatus.Text = "ERREUR : $_"
        $lblStatus.ForeColor = "Red"
        [System.Windows.Forms.MessageBox]::Show($_, "Erreur Init")
    }
})

$btnSend.Add_Click({ 
    $launcher.Hide()
    Start-SenderMode -kpPath $script:kpGlobalPath
    $launcher.Close() 
})

$btnRecv.Add_Click({ 
    $launcher.Hide()
    Start-ReceiverMode -kpPath $script:kpGlobalPath
    $launcher.Close() 
})

[void]$launcher.ShowDialog()