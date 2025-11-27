function Start-SenderMode {
    param($kpPath)
    $form = New-Object System.Windows.Forms.Form; $form.Text="EMETTEUR - Migration"; $form.Size=New-Object System.Drawing.Size(650,950); $form.StartPosition="CenterScreen"
    
    # --- FONCTION SECURISEE (VERSION FINALE) ---
    function Run-Cli-Safe {
        param($exe, $argsLine, $pwd, $outFile)
        
        # On tente d'injecter le mot de passe. 
        # Si ça échoue (caractères spéciaux), KeePassXC demandera le mot de passe dans la fenêtre.
        $env:KEEPASSXC_PASSWORD = $pwd
        
        $batFile = [System.IO.Path]::GetTempFileName() + ".bat"
        
        # CONSTRUCTION DE LA COMMANDE
        # On remet la redirection vers le fichier pour enregistrer le XML
        $finalCmd = "`"$exe`" $argsLine"
        if ($outFile) { $finalCmd += " > `"$outFile`"" }
        
        $batContent = @"
@echo off
:: Force l'encodage UTF-8 pour que le XML soit lisible (accents)
chcp 65001 > NUL
echo.
echo [EXPORT EN COURS]
echo.
echo 1. Si le script s'arrête ici sans rien faire : TAPEZ VOTRE MOT DE PASSE (il sera invisible) puis ENTREE.
echo 2. Si vous utilisez une YUBIKEY : Touchez-la maintenant.
echo.
$finalCmd
if %errorlevel% neq 0 (
    echo.
    echo [ERREUR FATALE] Code de sortie : %errorlevel%
    echo L'export a échoué.
    pause
    exit /b %errorlevel%
)
exit /b 0
"@
        [System.IO.File]::WriteAllText($batFile, $batContent, [System.Text.Encoding]::Default)
        
        try {
            $p = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$batFile`"" -PassThru -Wait -WindowStyle Normal
            return $p.ExitCode
        } finally {
            $env:KEEPASSXC_PASSWORD = $null 
            if(Test-Path $batFile){Remove-Item $batFile -Force -ErrorAction SilentlyContinue}
        }
    }

    # 1. SOURCE
    $grpSrc=New-Object System.Windows.Forms.GroupBox; $grpSrc.Text="1. SOURCE (Base actuelle)"; $grpSrc.Location=New-Object System.Drawing.Point(20,20); $grpSrc.Size=New-Object System.Drawing.Size(590,190); $form.Controls.Add($grpSrc)
    $script:txtSrcDB=Create-FilePicker $grpSrc 30 "Base .kdbx" $false; $script:txtSrcDB.Location=New-Object System.Drawing.Point(20,50)
    
    $l2=New-Object System.Windows.Forms.Label; $l2.Text="Mot de passe Actuel"; $l2.Location=New-Object System.Drawing.Point(20,90); $grpSrc.Controls.Add($l2)
    $script:tSrcP=New-Object System.Windows.Forms.TextBox; $script:tSrcP.UseSystemPasswordChar=$true; $script:tSrcP.Location=New-Object System.Drawing.Point(20,110); $script:tSrcP.Size=New-Object System.Drawing.Size(250,25); $grpSrc.Controls.Add($script:tSrcP)
    
    $script:tSrcK=Create-FilePicker $grpSrc 90 ("Fichier Cle Actuel (Opt)") $false; $script:tSrcK.Location=New-Object System.Drawing.Point(290,110); $script:tSrcK.Size=New-Object System.Drawing.Size(200,25)
    
    $script:cY1=New-Object System.Windows.Forms.CheckBox; $script:cY1.Text="Slot 1"; $script:cY1.Location=New-Object System.Drawing.Point(20,150); $script:cY1.Width=60; $grpSrc.Controls.Add($script:cY1)
    $script:cY2=New-Object System.Windows.Forms.CheckBox; $script:cY2.Text="Slot 2"; $script:cY2.Location=New-Object System.Drawing.Point(90,150); $script:cY2.Width=60; $grpSrc.Controls.Add($script:cY2)
    $lS=New-Object System.Windows.Forms.Label; $lS.Text="Serial YubiKey:"; $lS.Location=New-Object System.Drawing.Point(160,153); $lS.AutoSize=$true; $grpSrc.Controls.Add($lS)
    $script:tSrcS=New-Object System.Windows.Forms.TextBox; $script:tSrcS.Location=New-Object System.Drawing.Point(260,150); $script:tSrcS.Size=New-Object System.Drawing.Size(120,25); $grpSrc.Controls.Add($script:tSrcS)

    # 2. TRANSPORT
    $grpTr=New-Object System.Windows.Forms.GroupBox; $grpTr.Text="2. SECURITE DU TRANSPORT"; $grpTr.Location=New-Object System.Drawing.Point(20,220); $grpTr.Size=New-Object System.Drawing.Size(590,260); $form.Controls.Add($grpTr)
    
    $pnlP=New-Object System.Windows.Forms.Panel; $pnlP.Location=New-Object System.Drawing.Point(10,20); $pnlP.Size=New-Object System.Drawing.Size(570,70); $pnlP.BorderStyle="FixedSingle"; $grpTr.Controls.Add($pnlP)
    $lTp=New-Object System.Windows.Forms.Label; $lTp.Text="A. Mot de Passe :"; $lTp.Location=New-Object System.Drawing.Point(5,5); $lTp.Font=[System.Drawing.Font]::new($lTp.Font, [System.Drawing.FontStyle]::Bold); $pnlP.Controls.Add($lTp)
    $rbP_Keep=New-Object System.Windows.Forms.RadioButton; $rbP_Keep.Text="Garder celui de la source"; $rbP_Keep.Location=New-Object System.Drawing.Point(10,30); $rbP_Keep.Width=160; $pnlP.Controls.Add($rbP_Keep)
    $rbP_New=New-Object System.Windows.Forms.RadioButton; $rbP_New.Text="Nouveau :"; $rbP_New.Location=New-Object System.Drawing.Point(180,30); $rbP_New.Width=80; $rbP_New.Checked=$true; $pnlP.Controls.Add($rbP_New)
    $tTrP=New-Object System.Windows.Forms.TextBox; $tTrP.Location=New-Object System.Drawing.Point(260,28); $tTrP.Width=150; $tTrP.Text=(Generate-Password); $pnlP.Controls.Add($tTrP)
    $rbP_None=New-Object System.Windows.Forms.RadioButton; $rbP_None.Text="Aucun"; $rbP_None.Location=New-Object System.Drawing.Point(430,30); $pnlP.Controls.Add($rbP_None)

    $pnlK=New-Object System.Windows.Forms.Panel; $pnlK.Location=New-Object System.Drawing.Point(10,100); $pnlK.Size=New-Object System.Drawing.Size(570,70); $pnlK.BorderStyle="FixedSingle"; $grpTr.Controls.Add($pnlK)
    $lTk=New-Object System.Windows.Forms.Label; $lTk.Text="B. Fichier Clé :"; $lTk.Location=New-Object System.Drawing.Point(5,5); $lTk.Font=[System.Drawing.Font]::new($lTk.Font, [System.Drawing.FontStyle]::Bold); $pnlK.Controls.Add($lTk)
    $rbK_Keep=New-Object System.Windows.Forms.RadioButton; $rbK_Keep.Text="Garder (Copier)"; $rbK_Keep.Location=New-Object System.Drawing.Point(10,30); $rbK_Keep.Width=160; $pnlK.Controls.Add($rbK_Keep)
    $rbK_Gen=New-Object System.Windows.Forms.RadioButton; $rbK_Gen.Text="Générer un nouveau"; $rbK_Gen.Location=New-Object System.Drawing.Point(180,30); $rbK_Gen.Width=150; $rbK_Gen.Checked=$true; $pnlK.Controls.Add($rbK_Gen)
    $rbK_None=New-Object System.Windows.Forms.RadioButton; $rbK_None.Text="Aucun"; $rbK_None.Location=New-Object System.Drawing.Point(430,30); $pnlK.Controls.Add($rbK_None)

    $pnlY=New-Object System.Windows.Forms.Panel; $pnlY.Location=New-Object System.Drawing.Point(10,180); $pnlY.Size=New-Object System.Drawing.Size(570,60); $pnlY.BorderStyle="FixedSingle"; $grpTr.Controls.Add($pnlY)
    $lTy=New-Object System.Windows.Forms.Label; $lTy.Text="C. YubiKey :"; $lTy.Location=New-Object System.Drawing.Point(5,5); $lTy.Font=[System.Drawing.Font]::new($lTy.Font, [System.Drawing.FontStyle]::Bold); $pnlY.Controls.Add($lTy)
    $cTrY=New-Object System.Windows.Forms.CheckBox; $cTrY.Text="Exiger la YubiKey (Même config que source)"; $cTrY.Location=New-Object System.Drawing.Point(10,30); $cTrY.Width=450; $pnlY.Controls.Add($cTrY)

    # 3. DESTINATION
    $grpDst=New-Object System.Windows.Forms.GroupBox; $grpDst.Text="3. DESTINATION"; $grpDst.Location=New-Object System.Drawing.Point(20,500); $grpDst.Size=New-Object System.Drawing.Size(590,140); $form.Controls.Add($grpDst)
    $script:tDstD=Create-FilePicker $grpDst 30 "Dossier Base" $true
    $script:tDstK=Create-FilePicker $grpDst 80 "Dossier Cle (Si applicable)" $true

    $cDeb=New-Object System.Windows.Forms.CheckBox; $cDeb.Text="Mode Debug"; $cDeb.Location=New-Object System.Drawing.Point(20,650); $form.Controls.Add($cDeb)
    $btn=New-Object System.Windows.Forms.Button; $btn.Text="GENERER LE PACK DE MIGRATION"; $btn.Location=New-Object System.Drawing.Point(150,670); $btn.Size=New-Object System.Drawing.Size(350,50); $btn.BackColor="LightGreen"; $form.Controls.Add($btn)
    $log=New-Object System.Windows.Forms.TextBox; $log.Multiline=$true; $log.ScrollBars="Vertical"; $log.Location=New-Object System.Drawing.Point(20,740); $log.Size=New-Object System.Drawing.Size(590,150); $form.Controls.Add($log)

    $btn.Add_Click({
        $btn.Enabled=$false; $log.Text="Initialisation..."
        
        # VALIDATIONS
        if ([string]::IsNullOrEmpty($kpPath) -or -not (Test-Path $kpPath)) { [System.Windows.Forms.MessageBox]::Show("Chemin KeePassXC non défini. Relancez 'Vérifier/Installer'."); $btn.Enabled=$true; return }
        
        $sDB=$script:txtSrcDB.Text; $sPwd=$script:tSrcP.Text; $sKey=$script:tSrcK.Text; $sSerial=$script:tSrcS.Text
        if (-not (Test-Path $sDB)) { [System.Windows.Forms.MessageBox]::Show("Base source introuvable"); $btn.Enabled=$true; return }
        
        $targetPwd = ""; if ($rbP_Keep.Checked) { $targetPwd = $sPwd } elseif ($rbP_New.Checked) { $targetPwd = $tTrP.Text }
        $needKey = ($rbK_Keep.Checked -and $sKey) -or $rbK_Gen.Checked
        $needYubi = $cTrY.Checked
        
        $factors = 0; if ($targetPwd) { $factors++ }; if ($needKey) { $factors++ }; if ($needYubi) { $factors++ }
        if ($factors -eq 0) { [System.Windows.Forms.MessageBox]::Show("SECURITE INSUFFISANTE : Sélectionnez au moins une protection."); $btn.Enabled=$true; return }

        # PREPARATION
        Get-Process "keepassxc*" -ErrorAction SilentlyContinue | Stop-Process -Force
        $pack=Join-Path ([Environment]::GetFolderPath("Desktop")) "Pack_Keepass"
        if(Test-Path $pack){Remove-Item $pack -Recurse -Force}; New-Item $pack -Type Directory -Force | Out-Null
        Copy-Item "$kpPath\*" $pack -Recurse -Force
        
        $cliPack=(Get-ChildItem $pack -Filter "keepassxc-cli.exe" -Recurse | Select-Object -First 1).FullName
        if (-not $cliPack) { [System.Windows.Forms.MessageBox]::Show("Erreur critique: keepassxc-cli.exe non trouvé après copie."); $btn.Enabled=$true; return }

        $dDb=if($script:tDstD.Text){$script:tDstD.Text}else{Join-Path $pack "database"}; if(!(Test-Path $dDb)){New-Item $dDb -Type Directory -Force|Out-Null}
        $dKy=if($script:tDstK.Text){$script:tDstK.Text}else{$pack}; if(!(Test-Path $dKy)){New-Item $dKy -Type Directory -Force|Out-Null}
        $fDb=Join-Path $dDb "Transfert.kdbx"
        $xml=Join-Path $pack "temp.xml"

        # --- EXPORT ---
        $log.Text+="`r`nExport de la source..."
        
        $ykArgSrc=""; if($script:cY1.Checked){$ykArgSrc=" -y 1"}elseif($script:cY2.Checked){$ykArgSrc=" -y 2"}; if($ykArgSrc){$ykArgSrc+=":$sSerial"}
        $ax="export `"$sDB`""
        if($sKey){$ax+=" -k `"$sKey`""}
        $ax+=$ykArgSrc
        
        # Appel avec redirection active
        $code = Run-Cli-Safe -exe $cliPack -argsLine $ax -pwd $sPwd -outFile $xml
        
        if ($code -ne 0) { $log.Text+="`r`n[ECHEC] Code de sortie CLI : $code"; $btn.Enabled=$true; return }
        if (-not (Test-Path $xml)) { $log.Text+="`r`n[ECHEC] Fichier XML non créé."; $btn.Enabled=$true; return }
        if ((Get-Item $xml).Length -lt 50) { $log.Text+="`r`n[ECHEC] Fichier XML vide."; $btn.Enabled=$true; return }

        # --- IMPORT ---
        $log.Text+="`r`nImport temporaire..."
        $tempPwd = Generate-Password
        
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $cliPack; $psi.Arguments = "import -p `"$xml`" `"$fDb`""
        $psi.UseShellExecute = $false; $psi.RedirectStandardInput = $true; $psi.RedirectStandardOutput = $true; $psi.CreateNoWindow = $true
        $psi.EnvironmentVariables["KEEPASSXC_PASSWORD"] = $tempPwd 

        $p = New-Object System.Diagnostics.Process; $p.StartInfo = $psi; $p.Start() | Out-Null
        $p.StandardInput.WriteLine($tempPwd); Start-Sleep -Milliseconds 100
        $p.StandardInput.WriteLine($tempPwd); $p.StandardInput.Close()
        $p.WaitForExit()
        
        Remove-Item $xml -Force
        if ($p.ExitCode -ne 0) { $log.Text+="`r`n[ECHEC IMPORT]"; $btn.Enabled=$true; return }

        # --- SECURISATION ---
        $log.Text+="`r`nSecurisation finale..."
        $fkFinal=$null
        if ($needKey) {
            $fkFinal = Join-Path $dKy "Trans.key"
            if ($rbK_Keep.Checked) { Copy-Item $sKey $fkFinal -Force } else { [System.IO.File]::WriteAllText($fkFinal, (Generate-Password)) }
        }

        $ae="db-edit -p `"$fDb`" --password"; if($fkFinal){$ae+=" -k `"$fkFinal`""}; if($needYubi){$ae+=$ykArgSrc}

        if ($needYubi) {
            if($targetPwd) { [System.Windows.Forms.MessageBox]::Show("YubiKey + Changement de mot de passe :`nTapez le NOUVEAU mot de passe dans la fenêtre noire qui s'ouvre.", "Action") }
            else { [System.Windows.Forms.MessageBox]::Show("YubiKey + Aucun mot de passe :`nFaites ENTREE dans la fenêtre noire.", "Action") }
            Run-Cli-Safe -exe $cliPack -argsLine $ae -pwd $tempPwd
        } else {
            $psi2 = New-Object System.Diagnostics.ProcessStartInfo; $psi2.FileName=$cliPack; $psi2.Arguments=$ae
            $psi2.EnvironmentVariables["KEEPASSXC_PASSWORD"]=$tempPwd
            $psi2.UseShellExecute=$false; $psi2.RedirectStandardInput=$true; $psi2.CreateNoWindow=$true
            $p2=[System.Diagnostics.Process]::Start($psi2)
            $p2.StandardInput.WriteLine($targetPwd)
            $p2.StandardInput.WriteLine($targetPwd)
            $p2.StandardInput.Close(); $p2.WaitForExit()
        }

        # JSON
        $relDb=$fDb.Replace($pack,"").TrimStart("\"); $relKy=if($fkFinal){$fkFinal.Replace($pack,"").TrimStart("\")}else{$null}
        @{"DatabaseFile"=$relDb;"KeyFile"=$relKy;"YubiKey"=$needYubi}|ConvertTo-Json|Out-File (Join-Path $pack "info.json")
        
        [System.Windows.Forms.MessageBox]::Show("Terminé !"); Invoke-Item $pack; $form.Close()
    })
    $form.Add_Shown({$form.Activate()}); [void]$form.ShowDialog()
}