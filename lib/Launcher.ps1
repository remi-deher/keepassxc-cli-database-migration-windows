# --- CONFIGURATION CHEMINS ---
$LibDir = $PSScriptRoot
$ProjectRoot = Split-Path $LibDir -Parent

try {
    . "$LibDir\Common.ps1"
    . "$LibDir\Services.ps1"
    . "$LibDir\Export.ps1"
    . "$LibDir\Import.ps1"
} catch { [System.Windows.Forms.MessageBox]::Show("Erreur chargement modules : $_"); exit }

$launcher = New-Object System.Windows.Forms.Form
$launcher.Text = "Migration KeePassXC - v6.2"; $launcher.Size = New-Object System.Drawing.Size(450, 450)
$launcher.StartPosition = "CenterScreen"; $launcher.FormBorderStyle = "FixedDialog"

$lblTitle = New-Object System.Windows.Forms.Label; $lblTitle.Text = "Assistant de Migration"; $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold); $lblTitle.Location = New-Object System.Drawing.Point(20, 20); $lblTitle.AutoSize = $true; $launcher.Controls.Add($lblTitle)

$btnInit = New-Object System.Windows.Forms.Button; $btnInit.Text = "1. VERIFIER / INSTALLER KEEPASSXC"; $btnInit.Location = New-Object System.Drawing.Point(50, 70); $btnInit.Size = New-Object System.Drawing.Size(330, 50); $launcher.Controls.Add($btnInit)
$btnSend = New-Object System.Windows.Forms.Button; $btnSend.Text = "2. MODE EMETTEUR"; $btnSend.Location = New-Object System.Drawing.Point(50, 140); $btnSend.Size = New-Object System.Drawing.Size(330, 70); $btnSend.Enabled = $false; $launcher.Controls.Add($btnSend)
$btnRecv = New-Object System.Windows.Forms.Button; $btnRecv.Text = "3. MODE RECEPTEUR"; $btnRecv.Location = New-Object System.Drawing.Point(50, 230); $btnRecv.Size = New-Object System.Drawing.Size(330, 70); $btnRecv.Enabled = $false; $launcher.Controls.Add($btnRecv)
$lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Text = "En attente..."; $lblStatus.Location = New-Object System.Drawing.Point(50, 320); $lblStatus.AutoSize = $true; $launcher.Controls.Add($lblStatus)

$script:kpGlobalPath = ""

$btnInit.Add_Click({
    try {
        $script:kpGlobalPath = Prepare-KeePassXC -DestinationPath $ProjectRoot -statusLabel $lblStatus
        $lblStatus.Text = "PRET !"; $lblStatus.ForeColor = "Green"
        $btnSend.Enabled = $true; $btnRecv.Enabled = $true; $btnInit.Visible = $false
    } catch { $lblStatus.Text = "ERREUR : $_"; $lblStatus.ForeColor = "Red" }
})

$btnSend.Add_Click({ $launcher.Hide(); Start-SenderMode -kpPath $script:kpGlobalPath; $launcher.Close() })
$btnRecv.Add_Click({ $launcher.Hide(); Start-ReceiverMode -kpPath $script:kpGlobalPath; $launcher.Close() })

[void]$launcher.ShowDialog()