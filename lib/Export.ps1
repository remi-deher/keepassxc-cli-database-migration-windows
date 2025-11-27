function Start-SenderMode {
    param($kpPath)
    $form = New-Object System.Windows.Forms.Form; $form.Text="EMETTEUR - Migration"; $form.Size=New-Object System.Drawing.Size(650,950); $form.StartPosition="CenterScreen"
    
    # 1. SOURCE
    $grpSrc=New-Object System.Windows.Forms.GroupBox; $grpSrc.Text="1. SOURCE"; $grpSrc.Location=New-Object System.Drawing.Point(20,20); $grpSrc.Size=New-Object System.Drawing.Size(590,190); $form.Controls.Add($grpSrc)
    $script:txtSrcDB=Create-FilePicker $grpSrc 30 "Base .kdbx" $false
    
    $l2=New-Object System.Windows.Forms.Label; $l2.Text="Mot de passe Actuel"; $l2.Location=New-Object System.Drawing.Point(20,90); $grpSrc.Controls.Add($l2)
    $script:tSrcP=New-Object System.Windows.Forms.TextBox; $script:tSrcP.UseSystemPasswordChar=$true; $script:tSrcP.Location=New-Object System.Drawing.Point(20,110); $script:tSrcP.Size=New-Object System.Drawing.Size(250,25); $grpSrc.Controls.Add($script:tSrcP)
    
    $script:tSrcK=Create-FilePicker $grpSrc 90 ("Fichier Cle Actuel (Opt)") $false; $script:tSrcK.Location=New-Object System.Drawing.Point(290,110); $script:tSrcK.Size=New-Object System.Drawing.Size(200,25)
    
    $script:cY1=New-Object System.Windows.Forms.CheckBox; $script:cY1.Text="Slot 1"; $script:cY1.Location=New-Object System.Drawing.Point(20,150); $script:cY1.Width=60; $grpSrc.Controls.Add($script:cY1)
    $script:cY2=New-Object System.Windows.Forms.CheckBox; $script:cY2.Text="Slot 2"; $script:cY2.Location=New-Object System.Drawing.Point(90,150); $script:cY2.Width=60; $grpSrc.Controls.Add($script:cY2)
    
    $lS=New-Object System.Windows.Forms.Label; $lS.Text="Serial:"; $lS.Location=New-Object System.Drawing.Point(160,153); $lS.AutoSize=$true; $grpSrc.Controls.Add($lS)
    $detectedSerial = Get-YubiKeySerial
    $script:tSrcS=New-Object System.Windows.Forms.TextBox; $script:tSrcS.Location=New-Object System.Drawing.Point(205,150); $script:tSrcS.Size=New-Object System.Drawing.Size(120,25); $grpSrc.Controls.Add($script:tSrcS)
    if ($detectedSerial) { $script:tSrcS.Text = $detectedSerial }

    # 2. TRANSPORT
    $grpTr=New-Object System.Windows.Forms.GroupBox; $grpTr.Text="2. SECURITE TRANSPORT"; $grpTr.Location=New-Object System.Drawing.Point(20,220); $grpTr.Size=New-Object System.Drawing.Size(590,260); $form.Controls.Add($grpTr)
    
    $pnlP=New-Object System.Windows.Forms.Panel; $pnlP.Location=New-Object System.Drawing.Point(10,20); $pnlP.Size=New-Object System.Drawing.Size(570,70); $pnlP.BorderStyle="FixedSingle"; $grpTr.Controls.Add($pnlP)
    $lTp=New-Object System.Windows.Forms.Label; $lTp.Text="A. Mot de Passe :"; $lTp.Location=New-Object System.Drawing.Point(5,5); $pnlP.Controls.Add($lTp)
    $rbP_Keep=New-Object System.Windows.Forms.RadioButton; $rbP_Keep.Text="Garder Source"; $rbP_Keep.Location=New-Object System.Drawing.Point(10,30); $rbP_Keep.Width=110; $pnlP.Controls.Add($rbP_Keep)
    $rbP_New=New-Object System.Windows.Forms.RadioButton; $rbP_New.Text="Nouveau :"; $rbP_New.Location=New-Object System.Drawing.Point(130,30); $rbP_New.Width=80; $rbP_New.Checked=$true; $pnlP.Controls.Add($rbP_New)
    $tTrP=New-Object System.Windows.Forms.TextBox; $tTrP.Location=New-Object System.Drawing.Point(210,28); $tTrP.Width=150; $tTrP.Text=(Generate-Password); $pnlP.Controls.Add($tTrP)
    $rbP_None=New-Object System.Windows.Forms.RadioButton; $rbP_None.Text="Aucun"; $rbP_None.Location=New-Object System.Drawing.Point(380,30); $pnlP.Controls.Add($rbP_None)

    $pnlK=New-Object System.Windows.Forms.Panel; $pnlK.Location=New-Object System.Drawing.Point(10,100); $pnlK.Size=New-Object System.Drawing.Size(570,70); $pnlK.BorderStyle="FixedSingle"; $grpTr.Controls.Add($pnlK)
    $lTk=New-Object System.Windows.Forms.Label; $lTk.Text="B. Fichier Clé :"; $lTk.Location=New-Object System.Drawing.Point(5,5); $pnlK.Controls.Add($lTk)
    $rbK_Keep=New-Object System.Windows.Forms.RadioButton; $rbK_Keep.Text="Copier Source"; $rbK_Keep.Location=New-Object System.Drawing.Point(10,30); $rbK_Keep.Width=110; $pnlK.Controls.Add($rbK_Keep)
    $rbK_Gen=New-Object System.Windows.Forms.RadioButton; $rbK_Gen.Text="Générer"; $rbK_Gen.Location=New-Object System.Drawing.Point(130,30); $rbK_Gen.Width=80; $rbK_Gen.Checked=$true; $pnlK.Controls.Add($rbK_Gen)
    $rbK_None=New-Object System.Windows.Forms.RadioButton; $rbK_None.Text="Aucun"; $rbK_None.Location=New-Object System.Drawing.Point(380,30); $pnlK.Controls.Add($rbK_None)

    $pnlY=New-Object System.Windows.Forms.Panel; $pnlY.Location=New-Object System.Drawing.Point(10,180); $pnlY.Size=New-Object System.Drawing.Size(570,60); $pnlY.BorderStyle="FixedSingle"; $grpTr.Controls.Add($pnlY)
    $lTy=New-Object System.Windows.Forms.Label; $lTy.Text="C. YubiKey :"; $lTy.Location=New-Object System.Drawing.Point(5,5); $pnlY.Controls.Add($lTy)
    $cTrY=New-Object System.Windows.Forms.CheckBox; $cTrY.Text="Exiger la YubiKey (Même config que source)"; $cTrY.Location=New-Object System.Drawing.Point(10,30); $cTrY.Width=450; $pnlY.Controls.Add($cTrY)

    # 3. DESTINATION
    $grpDst=New-Object System.Windows.Forms.GroupBox; $grpDst.Text="3. DESTINATION"; $grpDst.Location=New-Object System.Drawing.Point(20,500); $grpDst.Size=New-Object System.Drawing.Size(590,140); $form.Controls.Add($grpDst)
    $script:tDstD=Create-FilePicker $grpDst 30 "Dossier Base" $true
    $script:tDstK=Create-FilePicker $grpDst 80 "Dossier Cle (Si applicable)" $true

    $btn=New-Object System.Windows.Forms.Button; $btn.Text="GENERER LE PACK"; $btn.Location=New-Object System.Drawing.Point(150,670); $btn.Size=New-Object System.Drawing.Size(350,50); $btn.BackColor="LightGreen"; $form.Controls.Add($btn)
    $log=New-Object System.Windows.Forms.TextBox; $log.Multiline=$true; $log.ScrollBars="Vertical"; $log.Location=New-Object System.Drawing.Point(20,740); $log.Size=New-Object System.Drawing.Size(590,150); $form.Controls.Add($log)

    $btn.Add_Click({
        $btn.Enabled=$false; $log.Text="Initialisation..."
        if ([string]::IsNullOrEmpty($kpPath) -or -not (Test-Path $kpPath)) { [System.Windows.Forms.MessageBox]::Show("Chemin KeePassXC invalide."); $btn.Enabled=$true; return }
        
        $sDB=$script:txtSrcDB.Text.Trim('"'); $sPwd=$script:tSrcP.Text; $sKey=$script:tSrcK.Text.Trim('"'); $sSerial=$script:tSrcS.Text.Trim()
        if (-not (Test-Path $sDB)) { [System.Windows.Forms.MessageBox]::Show("Base source introuvable"); $btn.Enabled=$true; return }
        
        # CIBLES
        $targetPwd = ""; if ($rbP_Keep.Checked) { $targetPwd = $sPwd } elseif ($rbP_New.Checked) { $targetPwd = $tTrP.Text }
        $needKey = ($rbK_Keep.Checked -and $sKey) -or $rbK_Gen.Checked
        $needYubi = $cTrY.Checked
        if ($needYubi -and -not $sSerial) { [System.Windows.Forms.MessageBox]::Show("Serial YubiKey manquant!"); $btn.Enabled=$true; return }
        
        $factors = 0; if ($targetPwd) { $factors++ }; if ($needKey) { $factors++ }; if ($needYubi) { $factors++ }
        if ($factors -eq 0) { [System.Windows.Forms.MessageBox]::Show("SECURITE INSUFFISANTE"); $btn.Enabled=$true; return }

        try { Get-Process "keepassxc*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue } catch {}
        
        $pack=Join-Path ([Environment]::GetFolderPath("Desktop")) "Pack_Keepass"
        if(Test-Path $pack){Remove-Item $pack -Recurse -Force}; New-Item $pack -Type Directory -Force | Out-Null
        Copy-Item "$kpPath\*" $pack -Recurse -Force
        $cliPack=(Get-ChildItem $pack -Filter "keepassxc-cli.exe" -Recurse | Select-Object -First 1).FullName
        
        $dDb=if($script:tDstD.Text){$script:tDstD.Text.Trim('"')}else{Join-Path $pack "database"}; if(!(Test-Path $dDb)){New-Item $dDb -Type Directory -Force|Out-Null}
        $dKy=if($script:tDstK.Text){$script:tDstK.Text.Trim('"')}else{$pack}; if(!(Test-Path $dKy)){New-Item $dKy -Type Directory -Force|Out-Null}
        $fDb=Join-Path $dDb "Transfert.kdbx"; $xml=Join-Path $pack "temp.xml"

        # 1. EXPORT (Modifié : Passage Pwd via Stdin)
        $log.AppendText("`r`n--- ETAPE 1: EXPORT ---")
        $ykArgSrc=""; if($script:cY1.Checked){$ykArgSrc=" -y 1"}elseif($script:cY2.Checked){$ykArgSrc=" -y 2"}; if($ykArgSrc){$ykArgSrc+=":$sSerial"}
        
        $ax = 'export "{0}"' -f $sDB
        if($sKey){ $ax += ' -k "{0}"' -f $sKey }
        if($ykArgSrc){ $ax += $ykArgSrc }
        
        # ICI LE CHANGEMENT : On passe $null en pwdToUnlock et $sPwd en stdinInput
        $res = Run-Cli-Safe -exe $cliPack -argsLine $ax -pwdToUnlock $null -stdinInput $sPwd -outFile $xml -logBox $log
        
        if ($res.ExitCode -ne 0 -or !(Test-Path $xml) -or (Get-Item $xml).Length -lt 50) { 
            $log.Text+="`r`n[ECHEC EXPORT] Code: $($res.ExitCode)`n$($res.Error)"; $btn.Enabled=$true; return 
        }

        # 2. PREP
        $fkFinal=$null
        if ($needKey) {
            $fkFinal = Join-Path $dKy "Trans.key"
            if ($rbK_Keep.Checked) { Copy-Item $sKey $fkFinal -Force } else { [System.IO.File]::WriteAllText($fkFinal, (Generate-Password)) }
        }

        # 3. IMPORT
        $log.AppendText("`r`n--- ETAPE 3: CREATION FINALE ---")
        $argsImp = 'import "{0}" "{1}"' -f $xml, $fDb
        if($fkFinal){ $argsImp += ' -k "{0}"' -f $fkFinal }
        if($needYubi){ $argsImp += $ykArgSrc }

        if($needYubi){ [System.Windows.Forms.MessageBox]::Show("TOUCHEZ VOTRE YUBIKEY quand demandé.", "Action Requise") }

        # Pour l'import/création, on injecte le nouveau mot de passe 2 fois
        $pwdToInject = if($targetPwd){ "$targetPwd`n$targetPwd" } else { "`n" }
        $resImp = Run-Cli-Safe -exe $cliPack -argsLine $argsImp -pwdToUnlock $null -stdinInput $pwdToInject -showWindow $needYubi -logBox $log
        
        Remove-Item $xml -Force
        if ($resImp.ExitCode -ne 0) { $log.Text+="`r`n[ECHEC IMPORT] Code: $($resImp.ExitCode)`n$($resImp.Error)"; $btn.Enabled=$true; return }

        $relDb=$fDb.Replace($pack,"").TrimStart("\"); $relKy=if($fkFinal){$fkFinal.Replace($pack,"").TrimStart("\")}else{$null}
        $savedSerial = if($needYubi){ $sSerial } else { $null }
        @{"DatabaseFile"=$relDb; "KeyFile"=$relKy; "YubiKey"=$needYubi; "YubiSerial"=$savedSerial} | ConvertTo-Json | Out-File (Join-Path $pack "info.json")
        
        [System.Windows.Forms.MessageBox]::Show("Terminé !"); Invoke-Item $pack; $form.Close()
    })
    $form.Add_Shown({$form.Activate()}); [void]$form.ShowDialog()
}