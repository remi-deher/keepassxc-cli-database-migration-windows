# KeePassXC Database Migration Tool (Windows)

Un outil d'automatisation PowerShell doté d'une interface graphique WinForms, conçu pour faciliter et sécuriser le transfert ou la passation de bases de données KeePassXC entre utilisateurs.

Ce script gère automatiquement le téléchargement de la version portable de KeePassXC, la manipulation des méthodes de chiffrement (Mot de passe, Fichier Clé, YubiKey) et la reconfiguration des accès pour le destinataire.

## Fonctionnalités Principales
* Interface Graphique (GUI) : Aucune commande complexe à taper, tout se fait via des fenêtres WinForms.
* Support Complet du Chiffrement : Gère les 3 méthodes (Mot de passe, Fichier Clé, YubiKey) individuellement ou combinées.
* Automatisation : Télécharge automatiquement la dernière version portable de KeePassXC depuis le dépôt officiel.

### Ce script propose deux modes de fonctionnement distincts selon votre rôle dans la migration.

#### 1. Pour l'Émetteur (Mode Export)
Ce mode prépare la base de données pour la transmission.

1. [Le script télécharge et décompresse la version 2.7.9 Portable de KeePassXC](#version-keepassxc)
2. L'utilisateur sélectionne le fichier de base de données (.kdbx) à transférer.
3. L'utilisateur saisit les identifiants actuels (Mot de passe, Clé, YubiKey) pour valider l'accès. 
4. Reconfiguration : Si nécessaire, l'utilisateur peut définir un nouveau mot de passe, ou retirer l'obligation du fichier clé/YubiKey pour le transfert

#### Le script génère un dossier contenant les fichiers prêts à être transmis au destinataire via un support sécurisé.
#### L'utilisateur peut séparer le dossier d'installation de Yubikey, le fichier de clé ainsi que la base de donnée sur un autre support
##

#### 2. Pour le Destinataire (Mode Import)
Ce mode installe et configure la base de données reçue.

1. L'utilisateur exécute le script en mode Import.
2. Il définit un répertoire de destination pour l'installation.
3. Il saisit les informations de déchiffrement définies par l'émetteur lors de la création de la migration.
4. Personnalisation : L'utilisateur peut modifier le mot de passe final, générer un nouveau fichier clé ou associer sa propre YubiKey.

5. Finalisation : Les données sont installées, KeepassXC reste en mode portable, et un raccourci est créé sur le bureau pour un accès immédiat.

#### Portabilité : Le résultat final est un dossier autonome contenant KeePassXC portable et la base de données, prêt à l'emploi (sur clé USB, Cloud, etc.).

## ⚖️ Avis de Non-Responsabilité et Conformité

Ce logiciel est distribué sous la **licence MIT**. Il est fourni « tel quel », sans aucune garantie expresse ou implicite.

En utilisant ce logiciel pour manipuler des bases de données KeePassXC, vous reconnaissez et acceptez les points suivants :

### 1. Responsabilité des Données
L'utilisateur est seul responsable de la sécurité, de l'intégrité et de la confidentialité de ses données. L'auteur du logiciel ne saurait être tenu responsable en cas de perte de données, corruption de la base de données ou compromission suite à une négligence (ex: historique de terminal non nettoyé, support USB perdu).

### 2. Limitation de Responsabilité
En aucun cas, l'auteur ou les contributeurs ne pourront être tenus responsables des dommages directs, indirects ou consécutifs découlant de l'utilisation de ce logiciel ou du non-respect des bonnes pratiques de sécurité.

### 3. Bonnes Pratiques de Sécurité
Il est de la responsabilité de l'utilisateur de :
* ✅ **Sauvegarder :** Toujours disposer de backups fiables avant manipulation.
* ✅ **Sécuriser :** Ne jamais laisser de mots de passe en clair dans les scripts ou l'historique.
* ✅ **Chiffrer :** Utiliser des supports de transfert (Clés USB) chiffrés matériellement ou logiciellement (BitLocker/LUKS).

### 4. Conformité Générale (ISO, RGPD, ANSSI)
L'utilisation de ce script doit s'effectuer en conformité avec la PSSI de votre organisation :
* **ISO/IEC 27001 (A.9) :** Respect des procédures de gestion des accès privilégiés.
* **RGPD (Art. 32) :** Garantie de la sécurité du traitement pour éviter toute violation de données personnelles.
* **ANSSI / NIST :** Respect des recommandations sur la robustesse des mots de passe.

### 5. Spécificités Sectorielles (Santé, Finance, OIV)
L'utilisateur opérant dans un secteur régulé doit valider l'usage de cet outil au regard de ses cadres normatifs :
* **Santé (PGSSI-S / HDS / HIPAA) :** Le transfert d'accès aux données de santé doit respecter les protocoles de traçabilité et de chiffrement imposés par la PGSSI-S ou HIPAA.
* **Finance (PCI-DSS / DORA) :** L'outil doit être utilisé en conformité avec les exigences de protection des authentifiants (Requirement 8 PCI-DSS).
* **Critique (LPM / NIS 2) :** L'usage dans le cadre d'OIV/OSE doit être soumis à homologation interne.

⚠️ **Note Importante :** L'introduction de cet outil dans un système d'information professionnel doit être validée par le Responsable de la Sécurité (CISO/Rana), la DSI ou tout autre personne habilité.

## 🏗️ Architecture et Dépendances

Ce logiciel est une solution d'automatisation (Wrapper) qui orchestre les composants suivants :

* **Moteur Cryptographique :** [KeePassXC](https://keepassxc.org/) (via `keepassxc-cli`). C'est lui qui assure la manipulation sécurisée des fichiers `.kdbx`.
* **Interface et Logique :** Écrit en **PowerShell** et utilise la librairie .NET **WinForms** (`System.Windows.Forms`) pour l'interface graphique.

**Prérequis techniques :**
* Système d'exploitation : Windows 10/11 (Recommandé pour le support natif WinForms).
* Environnement : PowerShell 5.1 ou supérieur.
* Framework .NET : Requis pour l'affichage des fenêtres.

<a id="version-keepassxc"></a>
*Par défaut, ce script télécharge la version 2.7.9 disponible via l'API GitHub du projet KeePassXC.*

**cette vesion à recu la certification ANSSI-CSPN-2025/16 le 17 Novembre 2025**   
**https://cyber.gouv.fr/produits-certifies/keepassxc-version-279**

# Environnement de test de developpement

- Windows 11 Professionnel pour les Stations de travail
- Clé OTP Yubikey 5
- Environnement Powershell : $PSVersionTable

```text
Name                           Value
----                           -----
PSVersion                      5.1.26100.7019
PSEdition                      Desktop
PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0...}
BuildVersion                   10.0.26100.7019
CLRVersion                     4.0.30319.42000
WSManStackVersion              3.0
PSRemotingProtocolVersion      2.3
SerializationVersion           1.1.0.1
```
