# Chargeur des dépendances
$LibDir = $PSScriptRoot
if (Test-Path "$LibDir\Services.ps1") { . "$LibDir\Services.ps1" } else { Write-Error "Services.ps1 manquant !" }
if (Test-Path "$LibDir\Common.ps1")   { . "$LibDir\Common.ps1" }

function Start-SenderMode {
    param($kpPath)
    $form = New-Object System.Windows.Forms.Form; $form.Text="EMETTEUR - Migration v6.2"; $form.Size=New-Object System.Drawing.Size(650,950); $form.StartPosition="CenterScreen"
    
    # --- 1. SOURCE ---
    $grpSrc=New-Object System.Windows.Forms.GroupBox; $grpSrc.Text="1. SOURCE (Base à exporter)"; $grpSrc.Location=New-Object System.Drawing.Point(20,20); $grpSrc.Size=New-Object System.Drawing.Size(590,190); $form.Controls.Add($grpSrc)
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

    # --- 2. TRANSPORT (OPTIONS RESTAUREES) ---
    $grpTr=New-Object System.Windows.Forms.GroupBox; $grpTr.Text="2. SECURITE DU TRANSPORT (Intermédiaire)"; $grpTr.Location=New-Object System.Drawing.Point(20,220); $grpTr.Size=New-Object System.Drawing.Size(590,280); $form.Controls.Add($grpTr)
    
    # A. Mot de Passe
    $pnlP=New-Object System.Windows.Forms.Panel; $pnlP.Location=New-Object System.Drawing.Point(10,20); $pnlP.Size=New-Object System.Drawing.Size(570,70); $pnlP.BorderStyle="FixedSingle"; $grpTr.Controls.Add($pnlP)
    $lTp=New-Object System.Windows.Forms.Label; $lTp.Text="A. Mot de Passe :"; $lTp.Location=New-Object System.Drawing.Point(5,5); $lTp.Font=[System.Drawing.Font]::new($lTp.Font, [System.Drawing.FontStyle]::Bold); $pnlP.Controls.Add($lTp)
    
    $rbP_Keep=New-Object System.Windows.Forms.RadioButton; $rbP_Keep.Text="Garder Source"; $rbP_Keep.Location=New-Object System.Drawing.Point(10,30); $rbP_Keep.Width=110; $pnlP.Controls.Add($rbP_Keep)
    $rbP_New=New-Object System.Windows.Forms.RadioButton; $rbP_New.Text="Nouveau :"; $rbP_New.Location=New-Object System.Drawing.Point(130,30); $rbP_New.Width=80; $rbP_New.Checked=$true; $pnlP.Controls.Add($rbP_New)
    $tTrP=New-Object System.Windows.Forms.TextBox; $tTrP.Location=New-Object System.Drawing.Point(210,28); $tTrP.Width=150; $tTrP.Text=(Generate-Password); $pnlP.Controls.Add($tTrP)
    $rbP_None=New-Object System.Windows.Forms.RadioButton; $rbP_None.Text="Aucun"; $rbP_None.Location=New-Object System.Drawing.Point(380,30); $pnlP.Controls.Add($rbP_None)

    # B. Fichier Clé
    $pnlK=New-Object System.Windows.Forms.Panel; $pnlK.Location=New-Object System.Drawing.Point(10,100); $pnlK.Size=New-Object System.Drawing.Size(570,70); $pnlK.BorderStyle="FixedSingle"; $grpTr.Controls.Add($pnlK)
    $lTk=New-Object System.Windows.Forms.Label; $lTk.Text="B. Fichier Clé :"; $lTk.Location=New-Object System.Drawing.Point(5,5); $lTk.Font=[System.Drawing.Font]::new($lTk.Font, [System.Drawing.FontStyle]::Bold); $pnlK.Controls.Add($lTk)
    
    $rbK_Keep=New-Object System.Windows.Forms.RadioButton; $rbK_Keep.Text="Copier Source"; $rbK_Keep.Location=New-Object System.Drawing.Point(10,30); $rbK_Keep.Width=110; $pnlK.Controls.Add($rbK_Keep)
    $rbK_Gen=New-Object System.Windows.Forms.RadioButton; $rbK_Gen.Text="Générer"; $rbK_Gen.Location=New-Object System.Drawing.Point(130,30); $rbK_Gen.Width=80; $rbK_Gen.Checked=$true; $pnlK.Controls.Add($rbK_Gen)
    $rbK_None=New-Object System.Windows.Forms.RadioButton; $rbK_None.Text="Aucun"; $rbK_None.Location=New-Object System.Drawing.Point(380,30); $pnlK.Controls.Add($rbK_None)

    # C. YubiKey (Option Manuelle)
    $pnlY=New-Object System.Windows.Forms.Panel; $pnlY.Location=New-Object System.Drawing.Point(10,180); $pnlY.Size=New-Object System.Drawing.Size(570,80); $pnlY.BorderStyle="FixedSingle"; $grpTr.Controls.Add($pnlY)
    $lTy=New-Object System.Windows.Forms.Label; $lTy.Text="C. YubiKey :"; $lTy.Location=New-Object System.Drawing.Point(5,5); $lTy.Font=[System.Drawing.Font]::new($lTy.Font, [System.Drawing.FontStyle]::Bold); $pnlY.Controls.Add($lTy)
    
    $cTrY=New-Object System.Windows.Forms.CheckBox; $cTrY.Text="Ajouter une YubiKey (Ouvrira l'interface graphique pour configurer)"; $cTrY.Location=New-Object System.Drawing.Point(10,30); $cTrY.Width=500; $pnlY.Controls.Add($cTrY)
    $lYInf=New-Object System.Windows.Forms.Label; $lYInf.Text="Si coché, le script ouvrira KeePassXC à la fin pour que vous ajoutiez la clé manuellement."; $lYInf.Location=New-Object System.Drawing.Point(30,55); $lYInf.Size=New-Object System.Drawing.Size(500,20); $lYInf.ForeColor="DimGray"; $pnlY.Controls.Add($lYInf)

    # --- 3. DESTINATION ---
    $grpDst=New-Object System.Windows.Forms.GroupBox; $grpDst.Text="3. DESTINATION"; $grpDst.Location=New-Object System.Drawing.Point(20,510); $grpDst.Size=New-Object System.Drawing.Size(590,140); $form.Controls.Add($grpDst)
    $script:tDstD=Create-FilePicker $grpDst 30 "Dossier Base" $true
    $script:tDstK=Create-FilePicker $grpDst 80 "Dossier Cle (Si applicable)" $true

    $btn=New-Object System.Windows.Forms.Button; $btn.Text="GENERER LE PACK"; $btn.Location=New-Object System.Drawing.Point(150,670); $btn.Size=New-Object System.Drawing.Size(350,50); $btn.BackColor="LightGreen"; $form.Controls.Add($btn)
    $log=New-Object System.Windows.Forms.TextBox; $log.Multiline=$true; $log.ScrollBars="Vertical"; $log.Location=New-Object System.Drawing.Point(20,740); $log.Size=New-Object System.Drawing.Size(590,150); $form.Controls.Add($log)

    $btn.Add_Click({
        $btn.Enabled=$false; $log.Text="Initialisation..."
        
        # 1. Recuperation & Nettoyage
        $sDB=$script:txtSrcDB.Text.Trim('"'); $sPwd=$script:tSrcP.Text; $sKey=$script:tSrcK.Text.Trim('"'); $sSerial=$script:tSrcS.Text.Trim()
        
        # 2. Détermination Identifiants Cible (Transport)
        $targetPwd = ""
        if ($rbP_Keep.Checked) { $targetPwd = $sPwd } 
        elseif ($rbP_New.Checked) { $targetPwd = $tTrP.Text }
        # else None

        $needKeyGen = $false
        $keySourceToCopy = $null
        
        if ($rbK_Keep.Checked) {
            if (-not $sKey) { [System.Windows.Forms.MessageBox]::Show("Option 'Copier Source' choisie mais pas de fichier clé source !"); $btn.Enabled=$true; return }
            $keySourceToCopy = $sKey
        } elseif ($rbK_Gen.Checked) {
            $needKeyGen = $true
        }

        # Validations de base
        if (-not (Test-Path $sDB)) { [System.Windows.Forms.MessageBox]::Show("Base source introuvable"); $btn.Enabled=$true; return }
        
        # Nettoyage Processus
        try { Get-Process "keepassxc*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue } catch {}
        
        # Dossiers
        $pack=Join-Path ([Environment]::GetFolderPath("Desktop")) "Pack_Keepass"
        if(Test-Path $pack){Remove-Item $pack -Recurse -Force}; New-Item $pack -Type Directory -Force | Out-Null
        Copy-Item "$kpPath\*" $pack -Recurse -Force
        $cliPack=(Get-ChildItem $pack -Filter "keepassxc-cli.exe" -Recurse | Select-Object -First 1).FullName
        $guiPack=(Get-ChildItem $pack -Filter "keepassxc.exe" -Recurse | Select-Object -First 1).FullName
        
        $dDb=if($script:tDstD.Text){$script:tDstD.Text.Trim('"')}else{Join-Path $pack "database"}; if(!(Test-Path $dDb)){New-Item $dDb -Type Directory -Force|Out-Null}
        $dKy=if($script:tDstK.Text){$script:tDstK.Text.Trim('"')}else{$pack}; if(!(Test-Path $dKy)){New-Item $dKy -Type Directory -Force|Out-Null}
        $fDb=Join-Path $dDb "Transfert.kdbx"; $xml=Join-Path $pack "temp.xml"

        # --- ETAPE A : EXPORT SOURCE (Déchiffrement) ---
        $log.AppendText("`r`n--- EXPORT SOURCE ---")
        $slotSrc = if($script:cY1.Checked){1}elseif($script:cY2.Checked){2}else{$null}
        $res = KP-Export-XML -cli $cliPack -dbIn $sDB -keyIn $sKey -slot $slotSrc -serial $sSerial -pwd $sPwd -xmlOut $xml -logBox $log
        if ($res.ExitCode -ne 0) { $log.Text+="`r`n[ERREUR EXPORT] $($res.Error)"; $btn.Enabled=$true; return }

        # --- ETAPE B : GESTION CLE CIBLE ---
        $fkFinal=$null
        if ($keySourceToCopy) {
            $fkFinal = Join-Path $dKy (Split-Path $keySourceToCopy -Leaf)
            Copy-Item $keySourceToCopy $fkFinal -Force
            $log.AppendText("`r`nClé copiée : $fkFinal")
        } elseif ($needKeyGen) {
            $fkFinal = Join-Path $dKy "Trans.key"
            [System.IO.File]::WriteAllText($fkFinal, (Generate-Password))
            $log.AppendText("`r`nClé générée : $fkFinal")
        }

        # --- ETAPE C : CREATION BASE DE TRANSPORT ---
        $log.AppendText("`r`n--- CREATION BASE TRANSPORT ---")
        $res = KP-Create-DB -cli $cliPack -xmlIn $xml -dbOut $fDb -keyOut $fkFinal -pwdNew $targetPwd -logBox $log
        Remove-Item $xml -Force
        if ($res.ExitCode -ne 0) { $log.Text+="`r`n[ERREUR CREATION] $($res.Error)"; $btn.Enabled=$true; return }

        # --- ETAPE D : YUBIKEY (VIA GUI SI DEMANDÉ) ---
        $yubiAdded = $false
        if ($cTrY.Checked) {
            $log.AppendText("`r`n--- CONFIGURATION MANUELLE YUBIKEY ---")
            
            $msgYubi = "La base de transport a été créée.`n"
            if($targetPwd){ $msgYubi += "Mot de passe : $targetPwd`n" } else { $msgYubi += "Mot de passe : (Aucun)`n" }
            $msgYubi += "`nKeePassXC va maintenant s'ouvrir.`n"
            $msgYubi += "1. Entrez le mot de passe (et/ou clé) pour ouvrir.`n"
            $msgYubi += "2. Allez dans : Base de données > Sécurité de la base.`n"
            $msgYubi += "3. Cliquez sur 'Ajouter YubiKey...' et configurez votre clé.`n"
            $msgYubi += "4. SAUVEGARDEZ et FERMEZ KeePassXC pour continuer."
            
            [System.Windows.Forms.MessageBox]::Show($msgYubi, "Action Requise", "OK", "Information")
            
            # Lancement GUI avec pré-sélection
            $argGui = "`"$fDb`""
            if ($fkFinal) { $argGui += " --keyfile `"$fkFinal`"" }
            
            $procGui = Start-Process -FilePath $guiPack -ArgumentList $argGui -PassThru
            $procGui.WaitForExit()
            
            $yubiAdded = $true
            $log.AppendText("`r`nKeePassXC fermé. Reprise...")
        }

        # JSON FINAL
        $relDb=$fDb.Replace($pack,"").TrimStart("\"); $relKy=if($fkFinal){$fkFinal.Replace($pack,"").TrimStart("\")}else{$null}
        # On sauvegarde le Serial Source par défaut, ou celui de la clé connectée si on vient d'en ajouter une
        $savedSerial = if($yubiAdded -or $detectedSerial){ $detectedSerial } elseif($sSerial){ $sSerial } else { $null }
        
        @{"DatabaseFile"=$relDb; "KeyFile"=$relKy; "YubiKey"=$yubiAdded; "YubiSerial"=$savedSerial} | ConvertTo-Json | Out-File (Join-Path $pack "info.json")
        
        [System.Windows.Forms.MessageBox]::Show("Terminé ! Le pack est prêt."); Invoke-Item $pack; $form.Close()
    })
    $form.Add_Shown({$form.Activate()}); [void]$form.ShowDialog()
}