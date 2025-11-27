function Start-SenderMode {
    param($kpPath)
    $form = New-Object System.Windows.Forms.Form; $form.Text="EMETTEUR"; $form.Size=New-Object System.Drawing.Size(650,900); $form.StartPosition="CenterScreen"
    
    # 1. SOURCE
    $grpSrc=New-Object System.Windows.Forms.GroupBox; $grpSrc.Text="1. SOURCE"; $grpSrc.Location=New-Object System.Drawing.Point(20,20); $grpSrc.Size=New-Object System.Drawing.Size(590,200); $form.Controls.Add($grpSrc)
    $script:txtSrcDB=Create-FilePicker $grpSrc 30 "Base .kdbx" $false; $script:txtSrcDB.Location=New-Object System.Drawing.Point(20,50)
    $l2=New-Object System.Windows.Forms.Label; $l2.Text="Mot de passe"; $l2.Location=New-Object System.Drawing.Point(20,90); $grpSrc.Controls.Add($l2)
    $script:tSrcP=New-Object System.Windows.Forms.TextBox; $script:tSrcP.UseSystemPasswordChar=$true; $script:tSrcP.Location=New-Object System.Drawing.Point(20,110); $script:tSrcP.Size=New-Object System.Drawing.Size(250,25); $grpSrc.Controls.Add($script:tSrcP)
    $script:tSrcK=Create-FilePicker $grpSrc 90 ("Cle (Opt)") $false; $script:tSrcK.Location=New-Object System.Drawing.Point(290,110); $script:tSrcK.Size=New-Object System.Drawing.Size(200,25)
    
    $script:cY1=New-Object System.Windows.Forms.CheckBox; $script:cY1.Text="Slot 1"; $script:cY1.Location=New-Object System.Drawing.Point(20,150); $script:cY1.Width=60; $grpSrc.Controls.Add($script:cY1)
    $script:cY2=New-Object System.Windows.Forms.CheckBox; $script:cY2.Text="Slot 2"; $script:cY2.Location=New-Object System.Drawing.Point(90,150); $script:cY2.Width=60; $grpSrc.Controls.Add($script:cY2)
    $lS=New-Object System.Windows.Forms.Label; $lS.Text="Serial YubiKey:"; $lS.Location=New-Object System.Drawing.Point(160,153); $lS.AutoSize=$true; $grpSrc.Controls.Add($lS)
    $script:tSrcS=New-Object System.Windows.Forms.TextBox; $script:tSrcS.Location=New-Object System.Drawing.Point(260,150); $script:tSrcS.Size=New-Object System.Drawing.Size(120,25); $grpSrc.Controls.Add($script:tSrcS)

    # 2. TRANSPORT
    $grpTr=New-Object System.Windows.Forms.GroupBox; $grpTr.Text="2. TRANSPORT"; $grpTr.Location=New-Object System.Drawing.Point(20,230); $grpTr.Size=New-Object System.Drawing.Size(590,180); $form.Controls.Add($grpTr)
    $lP=New-Object System.Windows.Forms.Label; $lP.Text="Mot de Passe Transport"; $lP.Location=New-Object System.Drawing.Point(20,30); $grpTr.Controls.Add($lP)
    $script:tTrP=New-Object System.Windows.Forms.TextBox; $script:tTrP.Location=New-Object System.Drawing.Point(20,50); $script:tTrP.Width=250; $script:tTrP.Text=(Generate-Password); $grpTr.Controls.Add($script:tTrP)
    
    $script:cTrK=New-Object System.Windows.Forms.CheckBox; $script:cTrK.Text="Generer Fichier Cle"; $script:cTrK.Location=New-Object System.Drawing.Point(20,90); $script:cTrK.Width=200; $grpTr.Controls.Add($script:cTrK)
    $script:cTrY=New-Object System.Windows.Forms.CheckBox; $script:cTrY.Text="YubiKey Requise (Meme Serial)"; $script:cTrY.Location=New-Object System.Drawing.Point(20,120); $script:cTrY.Width=300; $script:cTrY.ForeColor="Red"; $grpTr.Controls.Add($script:cTrY)

    # 3. DEST
    $grpDst=New-Object System.Windows.Forms.GroupBox; $grpDst.Text="3. DESTINATION"; $grpDst.Location=New-Object System.Drawing.Point(20,420); $grpDst.Size=New-Object System.Drawing.Size(590,160); $form.Controls.Add($grpDst)
    $script:tDstD=Create-FilePicker $grpDst 40 "Dossier Base" $true
    $script:tDstK=Create-FilePicker $grpDst 100 "Dossier Cle" $true

    $cDeb=New-Object System.Windows.Forms.CheckBox; $cDeb.Text="Debug"; $cDeb.Location=New-Object System.Drawing.Point(20,600); $form.Controls.Add($cDeb)
    $btn=New-Object System.Windows.Forms.Button; $btn.Text="GENERER"; $btn.Location=New-Object System.Drawing.Point(150,630); $btn.Size=New-Object System.Drawing.Size(350,50); $btn.BackColor="LightGreen"; $form.Controls.Add($btn)
    $log=New-Object System.Windows.Forms.TextBox; $log.Multiline=$true; $log.ScrollBars="Vertical"; $log.Location=New-Object System.Drawing.Point(20,700); $log.Size=New-Object System.Drawing.Size(590,140); $form.Controls.Add($log)

    $btn.Add_Click({
        # VALEURS UI
        $sDB=$script:txtSrcDB.Text; $sPwd=$script:tSrcP.Text; $sKey=$script:tSrcK.Text; $sSerial=$script:tSrcS.Text
        if (-not (Test-Path $sDB)) { [System.Windows.Forms.MessageBox]::Show("Base introuvable"); return }
        $useYubi = ($script:cY1.Checked -or $script:cY2.Checked)
        if ($useYubi -and -not $sSerial) { [System.Windows.Forms.MessageBox]::Show("Serial manquant"); return }

        $transPwd = $script:tTrP.Text
        if (-not $transPwd) { [System.Windows.Forms.MessageBox]::Show("Pwd vide"); return }

        $btn.Enabled=$false; $log.Text="Init..."
        
        # KILL PROCESS
        Get-Process "keepassxc*" -ErrorAction SilentlyContinue | Stop-Process -Force
        Start-Sleep -Seconds 1
        $cli=(Get-ChildItem $kpPath -Filter "keepassxc-cli.exe" -Recurse | Select-Object -First 1).FullName

        # ARGS YUBI
        $ykArg=""; if($script:cY1.Checked){$ykArg=" -y 1"}elseif($script:cY2.Checked){$ykArg=" -y 2"}
        if($ykArg){$ykArg+=":$sSerial"}

        # 1. TEST CONNEXION
        $log.Text+="`r`nTest connexion (Fenetre noire)..."
        $argsTest="ls `"$sDB`""
        if($sKey){$argsTest+=" -k `"$sKey`""}
        $argsTest+=$ykArg
        
        if($cDeb.Checked){Show-DebugWindow "TEST" "& `"$cli`" $argsTest"}
        
        # IMPORTANT : On utilise la version INTERACTIVE pour le test (YubiKey potentielle)
        $code = Run-KeePassCli-Interactive -exe $cli -arguments $argsTest -pwd $sPwd
        if($code -ne 0){$log.Text+="`r`nECHEC TEST ($code)"; $btn.Enabled=$true; return}

        # 2. PREP DOSSIERS
        $pack=Join-Path ([Environment]::GetFolderPath("Desktop")) "Pack_Keepass"; if(Test-Path $pack){Remove-Item $pack -Recurse -Force}; New-Item $pack -Type Directory|Out-Null
        Copy-Item "$kpPath\*" $pack -Recurse
        $cliPack=(Get-ChildItem $pack -Filter "keepassxc-cli.exe" -Recurse | Select-Object -First 1).FullName
        
        $dDb=if($script:tDstD.Text){$script:tDstD.Text}else{Join-Path $pack "database"}; if(!(Test-Path $dDb)){New-Item $dDb -Type Directory -Force|Out-Null}
        $dKy=if($script:tDstK.Text){$script:tDstK.Text}else{$pack}; if(!(Test-Path $dKy)){New-Item $dKy -Type Directory -Force|Out-Null}
        $fDb=Join-Path $dDb "Transfert.kdbx"

        # 3. EXPORT
        $log.Text+="`r`nExport..."
        $xml=Join-Path $pack "temp.xml"
        $ax="export `"$sDB`""
        if($sKey){$ax+=" -k `"$sKey`""}
        $ax+=$ykArg
        
        # IMPORTANT : Version INTERACTIVE + REDIRECTION pour l'export
        $code = Run-KeePassCli-Interactive -exe $cliPack -arguments $ax -pwd $sPwd -outputFile $xml
        if($code -ne 0 -or !(Test-Path $xml) -or (Get-Item $xml).Length -lt 50){
            $log.Text+="`r`nECHEC EXPORT"; $btn.Enabled=$true; return
        }

        # 4. IMPORT (SILENCIEUX)
        $log.Text+="`r`nImport..."
        $res=Run-KeePassCli-Silent -exe $cliPack -arguments "import -p `"$xml`" `"$fDb`"" -stdinPass $transPwd
        Remove-Item $xml -Force
        if($res.ExitCode -ne 0){$log.Text+="`r`nECHEC IMPORT"; $btn.Enabled=$true; return}

        # 5. SECU CIBLE
        $fk=$null; $fn="Trans.key"
        if($script:cTrK.Checked){$fk=Join-Path $dKy $fn; [System.IO.File]::WriteAllText($fk,(Generate-Password))}
        
        if($fk -or $script:cTrY.Checked){
            $log.Text+="`r`nSecurisation..."
            $ae="db-edit -p `"$fDb`""; if($fk){$ae+=" -k `"$fk`""}; if($script:cTrY.Checked){$ae+=$ykArg}
            
            # Interactif si YubiKey demandée, sinon Silencieux
            if($script:cTrY.Checked){Run-KeePassCli-Interactive -exe $cliPack -arguments $ae -pwd $transPwd}
            else{Run-KeePassCli-Silent -exe $cliPack -arguments $ae -stdinPass $transPwd}
        }

        # JSON
        $relDb=$fDb.Replace($pack,"").TrimStart("\"); $relKy=if($fk){$fk.Replace($pack,"").TrimStart("\")}else{$null}
        @{"DatabaseFile"=$relDb;"KeyFile"=$relKy;"YubiKey"=$script:cTrY.Checked}|ConvertTo-Json|Out-File (Join-Path $pack "info.json")
        
        [System.Windows.Forms.MessageBox]::Show("Termine!"); Invoke-Item $pack; $form.Close()
    })
    $form.Add_Shown({$form.Activate()}); [void]$form.ShowDialog()
}