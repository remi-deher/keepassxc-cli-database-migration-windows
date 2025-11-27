$LibDir = $PSScriptRoot
if (Test-Path "$LibDir\Services.ps1") { . "$LibDir\Services.ps1" } else { Write-Error "Services.ps1 manquant !" }
if (Test-Path "$LibDir\Common.ps1")   { . "$LibDir\Common.ps1" }

function Start-ReceiverMode {
    param($kpPath)
    $form=New-Object System.Windows.Forms.Form; $form.Text="RECEPTEUR"; $form.Size=New-Object System.Drawing.Size(650,850); $form.StartPosition="CenterScreen"

    $grpIn=New-Object System.Windows.Forms.GroupBox; $grpIn.Text="1. RECEPTION DU PACK"; $grpIn.Location=New-Object System.Drawing.Point(20,20); $grpIn.Size=New-Object System.Drawing.Size(590,200); $form.Controls.Add($grpIn)
    $script:tKeyUI=$null
    $auto={
        $d=$script:tDirUI.Text.Trim('"'); $j=Join-Path $d "info.json"
        if(Test-Path $j){ try{
            $o=Get-Content $j -Raw|ConvertFrom-Json
            if($o.KeyFile){$f=Join-Path $d $o.KeyFile; if(Test-Path $f){$script:tKeyUI.Text=$f}}
            [System.Windows.Forms.MessageBox]::Show("Config détectée.")
        }catch{}}
    }
    $script:tDirUI=Create-FilePicker $grpIn 30 "Dossier Pack" $true $false $auto
    $lP=New-Object System.Windows.Forms.Label; $lP.Text="Mot de Passe TRANSPORT"; $lP.Location=New-Object System.Drawing.Point(20,90); $grpIn.Controls.Add($lP)
    $tInPwd=New-Object System.Windows.Forms.TextBox; $tInPwd.Location=New-Object System.Drawing.Point(20,110); $tInPwd.Size=New-Object System.Drawing.Size(250,25); $grpIn.Controls.Add($tInPwd)
    $script:tKeyUI=Create-FilePicker $grpIn 100 "Fichier Clé" $false

    $grpOut=New-Object System.Windows.Forms.GroupBox; $grpOut.Text="2. INSTALLATION FINALE"; $grpOut.Location=New-Object System.Drawing.Point(20,240); $grpOut.Size=New-Object System.Drawing.Size(590,250); $form.Controls.Add($grpOut)
    $lN=New-Object System.Windows.Forms.Label; $lN.Text="Votre NOUVEAU Mot de Passe"; $lN.Location=New-Object System.Drawing.Point(20,30); $lN.Width=300; $grpOut.Controls.Add($lN)
    $tNewPwd=New-Object System.Windows.Forms.TextBox; $tNewPwd.Location=New-Object System.Drawing.Point(20,50); $tNewPwd.Size=New-Object System.Drawing.Size(250,25); $grpOut.Controls.Add($tNewPwd)
    $cNewKey=New-Object System.Windows.Forms.CheckBox; $cNewKey.Text="Générer mon Fichier Clé personnel"; $cNewKey.Location=New-Object System.Drawing.Point(20,90); $cNewKey.Width=300; $cNewKey.Checked=$true; $grpOut.Controls.Add($cNewKey)
    
    $cNewYubi=New-Object System.Windows.Forms.CheckBox; $cNewYubi.Text="Ajouter ma YubiKey (Via Interface)"; $cNewYubi.Location=New-Object System.Drawing.Point(20,130); $cNewYubi.Width=400; $grpOut.Controls.Add($cNewYubi)
    $lYubiInfo=New-Object System.Windows.Forms.Label; $lYubiInfo.Text="Si coché, KeePassXC s'ouvrira à la fin pour que vous ajoutiez la clé."; $lYubiInfo.Location=New-Object System.Drawing.Point(40,155); $lYubiInfo.Size=New-Object System.Drawing.Size(500,20); $lYubiInfo.ForeColor="Blue"; $grpOut.Controls.Add($lYubiInfo)

    $tDest=Create-FilePicker $form 500 "Dossier Install" $true; $tDest.Text=([Environment]::GetFolderPath("Desktop"))+"\KeePassXC_Final"
    $btn=New-Object System.Windows.Forms.Button; $btn.Text="INSTALLER"; $btn.Location=New-Object System.Drawing.Point(150,580); $btn.Size=300,50; $btn.BackColor="LightBlue"; $form.Controls.Add($btn)
    $log=New-Object System.Windows.Forms.TextBox; $log.Multiline=$true; $log.ScrollBars="Vertical"; $log.Location=New-Object System.Drawing.Point(20,650); $log.Size=590,120; $form.Controls.Add($log)

    $btn.Add_Click({
        $dir=$script:tDirUI.Text.Trim('"'); $fin=$tDest.Text.Trim('"'); $pT=$tInPwd.Text; $pF=$tNewPwd.Text
        if(![System.IO.Directory]::Exists($dir)){[System.Windows.Forms.MessageBox]::Show("Dossier invalide");return}
        $db=$null; $j=Join-Path $dir "info.json"; if(Test-Path $j){try{$o=Get-Content $j -Raw|ConvertFrom-Json; if($o.DatabaseFile){$f=Join-Path $dir $o.DatabaseFile; if(Test-Path $f){$db=Get-Item $f}}}catch{}}
        if(!$db){$db=Get-ChildItem $dir -Filter "*.kdbx" -Recurse|Select -First 1}; if(!$db){return}

        $btn.Enabled=$false; $log.Text="Préparation..."
        if(!(Test-Path $fin)){New-Item $fin -Type Directory -Force|Out-Null}
        Copy-Item "$dir\*" $fin -Recurse -Force
        $cli=(Get-ChildItem $fin -Filter "keepassxc-cli.exe" -Recurse | Select-Object -First 1).FullName
        $gui=(Get-ChildItem $fin -Filter "keepassxc.exe" -Recurse | Select-Object -First 1).FullName
        $xml=Join-Path $fin "temp_install.xml"

        # 1. DECHIFFREMENT
        $res = KP-Export-XML -cli $cli -dbIn $db.FullName -keyIn $script:tKeyUI.Text.Trim('"') -slot $null -serial $null -pwd $pT -xmlOut $xml -logBox $log
        if ($res.ExitCode -ne 0) { $log.Text+="`r`n[ERREUR] Mot de passe de transport incorrect."; $btn.Enabled=$true; return }

        # 2. CREATION FINALE
        $fDb=Join-Path $fin "MaBase.kdbx"; if(Test-Path $fDb){Remove-Item $fDb -Force}
        
        $fkFinal=$null
        if ($cNewKey.Checked) {
            $fkFinal = Join-Path $fin "MaCle.key"
            [System.IO.File]::WriteAllText($fkFinal, (Generate-Password))
        }
        
        $res = KP-Create-DB -cli $cli -xmlIn $xml -dbOut $fDb -keyOut $fkFinal -pwdNew $pF -logBox $log
        Remove-Item $xml -Force
        if ($res.ExitCode -ne 0) { $log.Text+="`r`n[ERREUR] Création échouée."; $btn.Enabled=$true; return }

        # 3. YUBIKEY GUI
        if ($cNewYubi.Checked) {
            [System.Windows.Forms.MessageBox]::Show("Base installée.`n`nKeePassXC va s'ouvrir pour ajouter la YubiKey.`nAllez dans : Base de données > Sécurité.")
            $argGui = "`"$fDb`""
            if ($fkFinal) { $argGui += " --keyfile `"$fkFinal`"" }
            Start-Process -FilePath $gui -ArgumentList $argGui
        } else {
            [System.Windows.Forms.MessageBox]::Show("Installation terminée !"); Invoke-Item $fin
        }
        $form.Close()
    })
    $form.Add_Shown({$form.Activate()}); [void]$form.ShowDialog()
}