function Start-ReceiverMode {
    param($kpPath)
    $form=New-Object System.Windows.Forms.Form; $form.Text="RECEPTEUR"; $form.Size=New-Object System.Drawing.Size(650,850); $form.StartPosition="CenterScreen"

    $grpIn=New-Object System.Windows.Forms.GroupBox; $grpIn.Text="1. RECEPTION DU PACK"; $grpIn.Location=New-Object System.Drawing.Point(20,20); $grpIn.Size=New-Object System.Drawing.Size(590,240); $form.Controls.Add($grpIn)
    
    $script:tKeyUI=$null; $script:cYubiUI=$null
    $auto={
        $d=$script:tDirUI.Text.Trim('"'); $j=Join-Path $d "info.json"
        if(Test-Path $j){ try{
            $o=Get-Content $j -Raw|ConvertFrom-Json
            if($o.KeyFile){$f=Join-Path $d $o.KeyFile; if(Test-Path $f){$script:tKeyUI.Text=$f}}
            $script:cYubiUI.Checked = ([bool]$o.YubiKey)
            $script:cYubiUI.Enabled = $true
            if ($o.YubiSerial) { $tInSer.Text = $o.YubiSerial }
            [System.Windows.Forms.MessageBox]::Show("Configuration détectée !", "Info")
        }catch{}}
    }
    
    $script:tDirUI=Create-FilePicker $grpIn 30 "Dossier Pack" $true $false $auto
    $lP=New-Object System.Windows.Forms.Label; $lP.Text="Mot de Passe TRANSPORT"; $lP.Location=New-Object System.Drawing.Point(20,90); $grpIn.Controls.Add($lP)
    $tInPwd=New-Object System.Windows.Forms.TextBox; $tInPwd.Location=New-Object System.Drawing.Point(20,110); $tInPwd.Size=New-Object System.Drawing.Size(250,25); $grpIn.Controls.Add($tInPwd)
    $script:tKeyUI=Create-FilePicker $grpIn 100 "Fichier Clé (Si applicable)" $false
    $script:cYubiUI=New-Object System.Windows.Forms.CheckBox; $script:cYubiUI.Text="YubiKey Requise"; $script:cYubiUI.Location=New-Object System.Drawing.Point(20,160); $script:cYubiUI.Width=300; $grpIn.Controls.Add($script:cYubiUI)
    $lS=New-Object System.Windows.Forms.Label; $lS.Text="Serial:"; $lS.Location=New-Object System.Drawing.Point(320,163); $grpIn.Controls.Add($lS)
    $tInSer=New-Object System.Windows.Forms.TextBox; $tInSer.Location=New-Object System.Drawing.Point(370,160); $tInSer.Width=100; $grpIn.Controls.Add($tInSer)

    $grpOut=New-Object System.Windows.Forms.GroupBox; $grpOut.Text="2. INSTALLATION FINALE"; $grpOut.Location=New-Object System.Drawing.Point(20,280); $grpOut.Size=New-Object System.Drawing.Size(590,220); $form.Controls.Add($grpOut)
    $lN=New-Object System.Windows.Forms.Label; $lN.Text="NOUVEAU Mot de Passe (Perso)"; $lN.Location=New-Object System.Drawing.Point(20,30); $lN.Width=300; $grpOut.Controls.Add($lN)
    $tNewPwd=New-Object System.Windows.Forms.TextBox; $tNewPwd.Location=New-Object System.Drawing.Point(20,50); $tNewPwd.Size=New-Object System.Drawing.Size(250,25); $grpOut.Controls.Add($tNewPwd)
    $cNewKey=New-Object System.Windows.Forms.CheckBox; $cNewKey.Text="Générer Fichier Clé perso"; $cNewKey.Location=New-Object System.Drawing.Point(20,90); $cNewKey.Width=300; $cNewKey.Checked=$true; $grpOut.Controls.Add($cNewKey)
    $cNewYubi=New-Object System.Windows.Forms.CheckBox; $cNewYubi.Text="Configurer MA YubiKey (Slot 2)"; $cNewYubi.Location=New-Object System.Drawing.Point(20,130); $cNewYubi.Width=250; $grpOut.Controls.Add($cNewYubi)
    
    $detectedLocal = Get-YubiKeySerial
    $tOutSer=New-Object System.Windows.Forms.TextBox; $tOutSer.Location=New-Object System.Drawing.Point(350,130); $tOutSer.Width=100; $grpOut.Controls.Add($tOutSer)
    if($detectedLocal) { $tOutSer.Text = $detectedLocal }

    $tDest=Create-FilePicker $form 520 "Dossier Install" $true; $tDest.Text=([Environment]::GetFolderPath("Desktop"))+"\KeePassXC_Final"
    $btn=New-Object System.Windows.Forms.Button; $btn.Text="LANCER"; $btn.Location=New-Object System.Drawing.Point(150,600); $btn.Size=New-Object System.Drawing.Size(350,50); $btn.BackColor="LightBlue"; $form.Controls.Add($btn)
    $log=New-Object System.Windows.Forms.TextBox; $log.Multiline=$true; $log.ScrollBars="Vertical"; $log.Location=New-Object System.Drawing.Point(20,670); $log.Size=New-Object System.Drawing.Size(590,120); $form.Controls.Add($log)

    $btn.Add_Click({
        $dir=$script:tDirUI.Text.Trim('"'); $fin=$tDest.Text.Trim('"'); $pT=$tInPwd.Text; $pF=$tNewPwd.Text
        if(![System.IO.Directory]::Exists($dir)){[System.Windows.Forms.MessageBox]::Show("Dossier invalide");return}
        $db=$null; $j=Join-Path $dir "info.json"; if(Test-Path $j){try{$o=Get-Content $j -Raw|ConvertFrom-Json; if($o.DatabaseFile){$f=Join-Path $dir $o.DatabaseFile; if(Test-Path $f){$db=Get-Item $f}}}catch{}}
        if(!$db){$db=Get-ChildItem $dir -Filter "*.kdbx" -Recurse|Select -First 1}; if(!$db){return}

        $btn.Enabled=$false; $log.Text="Préparation..."
        if(!(Test-Path $fin)){New-Item $fin -Type Directory -Force|Out-Null}
        Copy-Item "$dir\*" $fin -Recurse -Force
        $cli=(Get-ChildItem $fin -Filter "keepassxc-cli.exe" -Recurse | Select-Object -First 1).FullName
        $xml=Join-Path $fin "temp_install.xml"

        # 1. DECHIFFREMENT
        $log.AppendText("`r`nDéchiffrement...")
        $ykArg=""; if($script:cYubiUI.Checked){$ykArg=" -y 1"; if($tInSer.Text){$ykArg+=":$($tInSer.Text.Trim())"}}
        
        $argsExp = 'export "{0}"' -f $db.FullName
        if($script:tKeyUI.Text){ $argsExp += ' -k "{0}"' -f $script:tKeyUI.Text.Trim('"') }
        if($ykArg){ $argsExp += $ykArg }
        
        # ICI AUSSI : On force STDIN pour le déchiffrement
        $res = Run-Cli-Safe -exe $cli -argsLine $argsExp -pwdToUnlock $null -stdinInput $pT -outFile $xml -logBox $log
        if ($res.ExitCode -ne 0 -or !(Test-Path $xml) -or (Get-Item $xml).Length -lt 50) { 
            $log.Text+="`r`n[ECHEC DECHIFFREMENT] Code: $($res.ExitCode)`n$($res.Error)"; $btn.Enabled=$true; return 
        }

        # 2. CREATION FINALE
        $log.AppendText("`r`nCréation finale...")
        $fDb=Join-Path $fin "MaBase.kdbx"; if(Test-Path $fDb){Remove-Item $fDb -Force}
        
        $argsImp = 'import "{0}" "{1}"' -f $xml, $fDb
        if($cNewKey.Checked){ 
            $k=Join-Path $fin "MaCle.key"; [System.IO.File]::WriteAllText($k,(Generate-Password))
            $argsImp += ' -k "{0}"' -f $k
        }
        if($cNewYubi.Checked){ 
            $argsImp += " -y 2"; if($tOutSer.Text){$argsImp += ":$($tOutSer.Text.Trim())"}
        }

        if($cNewYubi.Checked){[System.Windows.Forms.MessageBox]::Show("TOUCHEZ VOTRE YUBIKEY quand demandé.", "Action")}

        $pwdToInject = if($pF){ "$pF`n$pF" } else { "`n" }
        $resImp = Run-Cli-Safe -exe $cli -argsLine $argsImp -stdinInput $pwdToInject -showWindow $cNewYubi.Checked -logBox $log
        
        Remove-Item $xml -Force
        if ($resImp.ExitCode -ne 0) { 
            $log.Text+="`r`n[ECHEC IMPORT] Code: $($resImp.ExitCode)`n$($resImp.Error)"; $btn.Enabled=$true; return 
        }

        [System.Windows.Forms.MessageBox]::Show("Installation Terminée !"); Invoke-Item $fin; $form.Close()
    })
    $form.Add_Shown({$form.Activate()}); [void]$form.ShowDialog()
}