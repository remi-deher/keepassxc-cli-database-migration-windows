<#
.SYNOPSIS
    Services métiers KeePassXC.
    Gère la construction des commandes.
#>

# EXPORT XML (Déchiffrement Source)
function KP-Export-XML {
    param($cli, $dbIn, $keyIn, $slot, $serial, $pwd, $xmlOut, $logBox)
    
    $argsList = 'export "{0}"' -f $dbIn
    if (-not [string]::IsNullOrEmpty($keyIn)) { $argsList += ' -k "{0}"' -f $keyIn }
    
    # Gestion YubiKey en lecture (Ca ça marche !)
    if ($slot) {
        $yArg = " -y $slot"
        if ($serial) { $yArg += ":$serial" }
        $argsList += $yArg
    }
    
    # Pour déverrouiller, on passe le pwd via stdinInput car -pwdToUnlock (EnvVar) peut bugger avec certains caractères
    return Run-Cli-Safe -exe $cli -argsLine $argsList -stdinInput $pwd -outFile $xmlOut -logBox $logBox
}

# CREATION DB (Import XML -> KDBX)
function KP-Create-DB {
    param($cli, $xmlIn, $dbOut, $keyOut, $pwdNew, $logBox)
    
    # import "XML" "DB"
    $argsList = 'import "{0}" "{1}"' -f $xmlIn, $dbOut
    
    # On définit le fichier clé DIRECTEMENT à la création (supporté par import)
    if (-not [string]::IsNullOrEmpty($keyOut)) {
        $argsList += ' -k "{0}"' -f $keyOut
    }
    
    # Note: On ne met PAS de -y ici car keepassxc-cli ne sait pas créer une DB avec YubiKey
    
    # Injection du nouveau mot de passe (2 fois pour confirmation)
    $inputPwd = if ($pwdNew) { "$pwdNew`n$pwdNew" } else { "`n" }
    
    return Run-Cli-Safe -exe $cli -argsLine $argsList -stdinInput $inputPwd -logBox $logBox
}