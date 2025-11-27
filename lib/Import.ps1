function Start-ReceiverMode {
    param($kpPath)
    $form=New-Object System.Windows.Forms.Form; $form.Text="RECEPTEUR"; $form.Size=New-Object System.Drawing.Size(650,750); $form.StartPosition="CenterScreen"
    $grpIn=New-Object System.Windows.Forms.GroupBox; $grpIn.Text="RECEPTION"; $grpIn.Location=New-Object System.Drawing.Point(20,20); $grpIn.Size=New-Object System.Drawing.Size(590,250); $form.Controls.Add($grpIn)
    
    $script:tKeyUI=$null; $script:cYubiUI=$null
    $auto={
        $d=$script:tDirUI.Text; $j=Join-Path $d "info.json"
        if(Test-Path $j){ try{
            $o=Get-Content $j -Raw|ConvertFrom-Json
            if($o.KeyFile){$f=Join-Path $d $o.KeyFile; if(Test-Path $f){$script:tKeyUI.Text=$f}}
            $script:cYubiUI.Checked=([bool]$o.YubiKey); [System.Windows.Forms.MessageBox]::Show("Config detectee!")
        }catch{}}
    }
    $script:tDirUI=Create-FilePicker $grpIn 30 "Dossier Pack" $true $false $auto
    $lP=New-Object System.Windows.Forms.Label; $lP.Text="Pwd"; $lP.Location=New-Object System.Drawing.Point(20,90); $grpIn.Controls.Add($lP)
    $tInPwd=New-Object System.Windows.Forms.TextBox; $tInPwd.Location=New-Object System.Drawing.Point(20,110); $tInPwd.Size=New-Object System.Drawing.Size(200,25); $grpIn.Controls.Add($tInPwd)
    $script:tKeyUI=Create-FilePicker $grpIn 100 "Fichier Cle" $false
    $script:cYubiUI=New-Object System.Windows.Forms.CheckBox; $script:cYubiUI.Text="YubiKey Requise"; $script:cYubiUI.Location=New-Object System.Drawing.Point(20,150); $script:cYubiUI.Width=200; $grpIn.Controls.Add($script:cYubiUI)
    $lS=New-Object System.Windows.Forms.Label; $lS.Text="Serial:"; $lS.Location=New-Object System.Drawing.Point(250,153); $grpIn.Controls.Add($lS)
    $tInSer=New-Object System.Windows.Forms.TextBox; $tInSer.Location=New-Object System.Drawing.Point(300,150); $grpIn.Controls.Add($tInSer)

    $grpOut=New-Object System.Windows.Forms.GroupBox; $grpOut.Text="FINAL"; $grpOut.Location=New-Object System.Drawing.Point(20,280); $grpOut.Size=New-Object System.Drawing.Size(590,200); $form.Controls.Add($grpOut)
    $lN=New-Object System.Windows.Forms.Label; $lN.Text="Nouveau Pwd"; $lN.Location=New-Object System.Drawing.Point(20,30); $grpOut.Controls.Add($lN)
    $tNewPwd=New-Object System.Windows.Forms.TextBox; $tNewPwd.Location=New-Object System.Drawing.Point(20,50); $tNewPwd.Size=New-Object System.Drawing.Size(200,25); $grpOut.Controls.Add($tNewPwd)
    $cNewKey=New-Object System.Windows.Forms.CheckBox; $cNewKey.Text="Creer Cle"; $cNewKey.Location=New-Object System.Drawing.Point(20,90); $cNewKey.Checked=$true; $grpOut.Controls.Add($cNewKey)
    $cNewYubi=New-Object System.Windows.Forms.CheckBox; $cNewYubi.Text="Config Yubi (Slot 2)"; $cNewYubi.Location=New-Object System.Drawing.Point(20,120); $cNewYubi.Width=200; $grpOut.Controls.Add($cNewYubi)
    $lS2=New-Object System.Windows.Forms.Label; $lS2.Text="Serial:"; $lS2.Location=New-Object System.Drawing.Point(250,123); $grpOut.Controls.Add($lS2)
    $tOutSer=New-Object System.Windows.Forms.TextBox; $tOutSer.Location=New-Object System.Drawing.Point(300,120); $grpOut.Controls.Add($tOutSer)

    $tDest=Create-FilePicker $form 500 "Installation" $true; $tDest.Text=([Environment]::GetFolderPath("Desktop"))+"\KeePassXC_Final"
    $btn=New-Object System.Windows.Forms.Button; $btn.Text="INSTALLER"; $btn.Location=New-Object System.Drawing.Point(150,560); $btn.Size=300; $btn.BackColor="LightBlue"; $form.Controls.Add($btn)

    $btn.Add_Click({
        $dir=$script:tDirUI.Text; $fin=$tDest.Text; $pT=$tInPwd.Text; $pF=$tNewPwd.Text
        if(![System.IO.Directory]::Exists($dir)){[System.Windows.Forms.MessageBox]::Show("Dossier invalide");return}
        
        $db=$null; $j=Join-Path $dir "info.json"
        if(Test-Path $j){try{$o=Get-Content $j -Raw|ConvertFrom-Json; if($o.DatabaseFile){$f=Join-Path $dir $o.DatabaseFile; if(Test-Path $f){$db=Get-Item $f}}}catch{}}
        if(!$db){$db=Get-ChildItem $dir -Filter "*.kdbx" -Recurse|Select -First 1}
        if(!$db){[System.Windows.Forms.MessageBox]::Show("Pas de kdbx");return}

        $btn.Enabled=$false; if(!(Test-Path $fin)){New-Item $fin -Type Directory|Out-Null}
        Copy-Item "$kpPath\*" $fin -Recurse -Force
        $cli=(Get-ChildItem $fin -Filter "keepassxc-cli.exe" -Recurse).FullName
        $xml=Join-Path $fin "temp.xml"

        # DECHIFFREMENT (INTERACTIF si Yubi)
        $ykArg=""; if($script:cYubiUI.Checked){$ykArg=" -y 1"; if($tInSer.Text){$ykArg+=":$($tInSer.Text)"}}
        $argsExp="export `"$($db.FullName)`""
        if($script:tKeyUI.Text){$argsExp+=" -k `"$($script:tKeyUI.Text)`""}
        $argsExp+=$ykArg

        $code = Run-KeePassCli-Interactive -exe $cli -arguments $argsExp -pwd $pT -outputFile $xml
        if($code -ne 0){[System.Windows.Forms.MessageBox]::Show("Echec Dechiffrement"); $btn.Enabled=$true; return}

        # IMPORT (SILENCIEUX)
        $fDb=Join-Path $fin "MaBase.kdbx"
        Run-KeePassCli-Silent -exe $cli -arguments "import -p `"$xml`" `"$fDb`"" -stdinPass $pF
        Remove-Item $xml -Force
        
        # SECU FINALE (HYBRIDE)
        $aEd="db-edit -p `"$fDb`""
        if($cNewKey.Checked){$k=Join-Path $fin "MaCle.key"; [System.IO.File]::WriteAllText($k,(Generate-Password)); $aEd+=" -k `"$k`""}
        if($cNewYubi.Checked){$aEd+=" -y 2"; if($tOutSer.Text){$aEd+=":$($tOutSer.Text)"}}
        
        if($cNewKey.Checked){Run-KeePassCli-Silent -exe $cli -arguments $aEd -stdinPass $pF}
        elseif($cNewYubi.Checked){Run-KeePassCli-Interactive -exe $cli -arguments $aEd -pwd $pF}

        [System.Windows.Forms.MessageBox]::Show("Termine!"); Invoke-Item $fin; $form.Close()
    })
    $form.Add_Shown({$form.Activate()}); [void]$form.ShowDialog()
}