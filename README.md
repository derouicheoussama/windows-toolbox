# 🧰 Windows 11 Toolbox

> **La boîte à outils Windows que tu gardes sur ta clé USB** : diagnostics, tests SSD, réparations, registre, BIOS/UEFI, nettoyage, achat PC, raccourcis — 10 onglets, **250+ commandes cliquables**, dans une seule fenêtre. PowerShell natif, **aucune installation**.

**v2.1.0** · Windows 10/11 · ∞ Infinity Coder — [Derouiche Oussama](https://www.derouicheoussama.com) · [GitHub](https://github.com/derouicheoussama) · [💜 Faire un don](https://www.paypal.com/donate)

---

## 📑 Sommaire

1. [Démarrage rapide](#-démarrage-rapide)
2. [Les 10 onglets](#-les-10-onglets)
3. [Raccourcis clavier & systray](#-raccourcis-clavier--systray)
4. [Corrections du registre Windows](#-corrections-du-registre-windows)
5. [BIOS / UEFI](#-bios--uefi)
6. [Mises à jour à distance](#-mises-à-jour-à-distance)
7. [Protection du logiciel & du code](#-protection-du-logiciel--du-code)
8. [FAQ](#-faq)
9. [Soutenir le projet](#-soutenir-le-projet)

## 🚀 Démarrage rapide

### 📥 Téléchargement (clients)

**Page Releases : [github.com/derouicheoussama/windows-toolbox/releases](https://github.com/derouicheoussama/windows-toolbox/releases)**

| Fichier | Pour qui |
|---|---|
| **`Windows-Toolbox.exe`** | Double-clic et c'est tout — application compilée, aucune installation |
| **`Setup-Toolbox.cmd`** | Installateur 1-fichier : télécharge la dernière version depuis GitHub, vérifie le SHA256, installe raccourcis + désinstalleur |
| **`Mac-Toolbox.command`** | La version macOS (voir [mac/README-MAC.md](mac/README-MAC.md)) |

| Méthode locale | Action |
|---|---|
| `Lancer-Toolbox.cmd` | **Double-clic** — aucun réglage requis (contourne ExecutionPolicy) |
| `.\Windows-Toolbox.ps1 -Admin` | Lancement direct + élévation administrateur (UAC) |
| `.\Windows-Toolbox.ps1 -List` | Inventaire console sans interface (disques, outils détectés) |
| `.\Installer-Toolbox.ps1` / `-Uninstall` | Installation complète locale (raccourcis + désinstalleur) |
| Clé USB | Copie le dossier entier, double-clique chez le vendeur ou un ami |

**Prérequis** : Windows 10/11, PowerShell 5.1 (inclus par défaut). Rien d'autre.

### 📦 Installation (optionnelle)

Double-clic sur **`Installer-Toolbox.ps1`** (ou clic droit → *Exécuter avec PowerShell*) :

- Copie l'application dans `%LOCALAPPDATA%\Programs\WindowsToolbox`
- Raccourcis **Menu Démarrer + Bureau** (icône bouclier)
- Entrée **« Windows 11 Toolbox »** dans *Applications & fonctionnalités* avec **Désinstaller** propre
- Les **mises à jour à distance continuent de fonctionner** sur la copie installée

Désinstallation : *Paramètres → Applications*, le raccourci « Desinstaller » du Menu Démarrer, ou `.\Installer-Toolbox.ps1 -Uninstall`.

À l'ouverture : **inventaire automatique** (PC, SSD, santé) dans la console, puis vérification silencieuse des mises à jour.

## 🗂 Les 10 onglets

| Onglet | Contenu |
|---|---|
| **🖥 Système** | Résumé PC, msinfo32, dxdiag, activation, **SFC /scannow**, **DISM** (Check/Scan/RestoreHealth/WinSxS), moniteurs (taskmgr, resmon, perfmon, eventvwr), nettoyage, rapport batterie |
| **💾 Disques & SSD** | Santé `Get-PhysicalDisk`, **SMART**, détails/firmware, volumes, **TRIM**, `chkdsk /scan`, **benchmark winsat**, SMART détaillé, diagnostic RAM |
| **🌐 Réseau** | ipconfig, adaptateurs, ping Internet/box, DNS, tracert, ports en écoute, fast.com, cache DNS, **reset Winsock/TCP-IP** |
| **🛠 Windows** | Paramètres, registre, gpedit, msconfig, services, périphériques, restauration, **winget** : lister, **mettre à jour TOUT avec rapport en direct dans la console**, actualiser les sources · **Corrections du registre** · **BIOS/UEFI** (voir ci-dessous) |
| **⚡ Rares** | Batterie (usure %, energy, sleepstudy, lastwake), fsutil/TRIM, CompactOS, WinSxS, vssadmin, WinSAT, BitLocker, ARP/pathping, wlanreport, **BSOD & minidumps**, gpresult, verifier, perfmon /rel, psr, mrt, clé BIOS, RAM par barrette |
| **🧹 Nettoyage** | **NETTOYAGE COMPLET EN 1 CLIC (rapport en direct, total libéré)**, **Audit express**, mesure des fichiers temporaires, nettoyage `%TEMP%` / Windows / **cache Windows Update** / Delivery Optimization / vignettes / WER / **Chrome-Edge** / corbeille (Mo libérés affichés), point de restauration, **hibernation off**, plans d'alimentation, réparation recherche & Store, télémétrie |
| **🛒 Achat PC** | **TEST PRÉ-ACHAT COMPLET en 1 clic** (specs vs annonce, SMART, BSOD 90 j, activation, Defender, batterie → **verdict + rapport .txt**), tests guidés : **pixels morts**, clavier, son, webcam, USB · **Tests PC PORTABLE** : écran **résolution + Hz + toutes les fréquences supportées**, dalle, **rétro-éclairage** (30→100%), **consommation batterie en watts (temps réel)**, **puissance du chargeur**, touchpad, micro |
| **🚀 Raccourcis** | Applications (calc, capture, clavier visuel…), réglages rapides (WiFi, thème, nuit…), dossiers usuels, actions système (verrouiller, veille…), **options de l'app** |
| **🧰 Tiers** | Détection auto des outils installés (CrystalDiskInfo, HWiNFO…), liens officiels, lancement des `.exe` portables du dossier `tools\` |
| **ℹ À propos** | Design cartes, liens officiels, **vérifier les mises à jour**, don |

## ⌨️ Raccourcis clavier & systray

| Raccourci | Action |
|---|---|
| **Ctrl+Alt+T** *(global — même hors de la fenêtre)* | Afficher / masquer la toolbox |
| **Ctrl+1 … Ctrl+9** | Changer d'onglet · **F1** = À propos |
| **Ctrl+H** | Masquer dans le systray · **Ctrl+U** = vérifier les mises à jour |
| **Icône systray** | Clic gauche : afficher/masquer · clic droit : menu (audit, mises à jour, quitter) |

**Options** (onglet 🚀 Raccourcis, persistées dans le registre) : réduire dans le systray · raccourci global on/off · **démarrer avec Windows**.

**🛡️ God Mode & dossiers secrets** (onglet 🚀 Raccourcis) : ouvre le fameux **God Mode** (250+ outils Windows dans une seule liste), crée/supprime le dossier `God Mode` sur ton Bureau, ou déploie un pack de **10 dossiers secrets** (outils d'administration, options d'alimentation, son, centre réseau, système, polices…) — et les retire aussi proprement.

**Code couleur** : bordure bleue = commande ici · orange = admin (UAC, console séparée) · blanc = outil intégré · bleu clair = site web.

## 🔧 Corrections du registre Windows

*(onglet 🛠 Windows — chaque correction **sauvegarde la clé modifiée** dans `Documents\WindowsToolbox-RegBackup\` avant d'agir)*

| Correction | Répare |
|---|---|
| Réactiver le Gestionnaire des tâches | « Le Gestionnaire des tâches a été désactivé par votre administrateur » |
| Réactiver l'invite de commandes (CMD) | « L'invite de commandes a été désactivée » |
| Réactiver l'Éditeur du registre | « La modification du registre a été désactivée » |
| Réactiver le Panneau de configuration & Paramètres | Accès bloqué aux réglages |
| Réparer l'ouverture des fichiers .exe | « Windows ne peut pas ouvrir ce fichier » pour tout |
| Réparer les raccourcis .lnk | Raccourcis qui ne s'ouvrent plus ou association cassée |
| **Réinitialiser TOUTES les stratégies** | Restrictions imposées par des malwares (⚠ retire aussi les stratégies d'entreprise) |
| Débloquer Windows Update | Stratégies qui désactivent les mises à jour |
| Réparer le cache des icônes | Icônes blanches/corrompues |

Avant toute session de corrections : bouton **« Point de restauration »** (filet de sécurité supplémentaire).

## 🔌 BIOS / UEFI

| Fonction | Détail |
|---|---|
| **UEFI ou Legacy ? Secure Boot ? TPM ?** | Diagnostic du mode firmware en 1 clic |
| **Redémarrer dans le BIOS/UEFI** | `shutdown /r /fw` — redémarre directement dans l'interface firmware (PC en mode UEFI) |
| **Réinitialiser les réglages BIOS/UEFI** | Notre outil **te démarre dans le BIOS et t'affiche le pas-à-pas** (Load Setup Defaults → F9, Save & Exit → F10), avec annulation possible via `shutdown /a` |
| **Effacer la puce TPM** | Réinitialisation de la puce de sécurité (⚠ définitif — attention si BitLocker sans clé sauvegardée) |

> ℹ️ Un « reset CMOS » matériel (jumper/pile) ne peut pas être fait depuis Windows : le firmware est protégé en écriture. La toolbox fait le maximum côté logiciel : démarrage direct dans le BIOS + guide intégré pour remettre les valeurs d'usine.

## 🔄 Mises à jour à distance

- **Automatique et silencieuse** au démarrage ; bouton **« Vérifier les mises à jour »** dans À propos.
- Flux : manifeste `version.json` (GitHub) → comparaison de version → proposition → **téléchargement → contrôle SHA256 → validation syntaxe** → remplacement → redémarrage. ([Test end-to-end validé : 2.0.0 → 2.0.1 installée automatiquement](#))
- **Publier une mise à jour (auteur)** :
  ```bash
  # 1. Augmente $script:ToolboxVersion dans Windows-Toolbox.ps1
  .\Build-Toolbox.ps1               # 2. régénère le SHA256
  # 3. Édite version.json (version + sha256 + notes)
  git add -A && git commit -m "v2.1.1" && git push
  ```
- **Première publication** : `gh auth login` puis `gh repo create windows-toolbox --public --source . --remote origin --push`

## 🛡 Protection du logiciel & du code

| Niveau | Commande | Effet |
|---|---|---|
| Intégrité | `.\Build-Toolbox.ps1` | `checksums.txt` + auto-contrôle au démarrage (alerte si fichier modifié) |
| Compilation | `.\Build-Toolbox.ps1 -Exe` | **Windows-Toolbox.exe** autonome via ps2exe (code compilé, métadonnées auteur) |
| Signature | `… -SignCert "cert.pfx" -CertPassword "mdp"` | Authenticode EXE et/ou .ps1 (anti-falsification, SmartScreen) |

Stratégie conseillée : distribuer **l'EXE signé**, garder le `.ps1` en dépôt privé, publier chaque version avec son SHA256.

## 🦠 Faux positif antivirus (Kaspersky, Defender…)

Un alerte du type **PDM:Trojan.Win32.Generic** est un **faux positif heuristique** : la toolbox enchaîne des commandes d'administration légitimes (téléchargement vérifié, registre, planificateur, élévation) que les heuristiques confondent avec un comportement malveillant. **Le code source est public et auditable.**

**Solutions, de la plus rapide à la plus définitive :**
1. **Vérifie le fichier** sur [opentip.kaspersky.com](https://opentip.kaspersky.com/) (scan 70+ moteurs — les gros noms le passent, seules 1-2 heuristiques râlent)
2. **Ajoute une exclusion** pour le dossier de la toolbox (Kaspersky : *Paramètres → Menaces et exclusions* · Windows : *Sécurité Windows → Exclusions*)
3. **Signale le faux positif** à l'éditeur de l'antivirus (Kaspersky : bouton *Faux positif* sur opentip)
4. **Signature Authenticode** (`Build-Toolbox.ps1 -SignCert`) : suppression définitive du problème
5. Si restauré depuis la quarantaine : **ajoute d'abord l'exclusion**, sinon l'antivirus re-flaguera au prochain lancement

Le bouton dédié **« Antivirus : faux positif ? (aide) »** dans l'onglet *À propos* ouvre le scan multi-moteurs et affiche la procédure.

## ❓ FAQ

- **Pourquoi des boutons orange (admin) ?** SFC, DISM, chkdsk, TRIM, Clear-Tpm, le reset BIOS écrivent dans des zones protégées : Windows exige l'élévation. Tout le reste marche en utilisateur standard.
- **Est-ce que ça installe des choses ?** Non. Aucun service, aucune tâche planifiée, aucun démarrage caché — sauf si tu coches toi-même « Démarrer avec Windows ».
- **Ça marche sur le PC de quelqu'un d'autre ?** Oui : clé USB + double-clic, lecture seule par défaut, rapport .txt exportable (onglet 🛒 Achat PC).
- **Comment désinstaller ?** Supprime le dossier. Pour l'option « démarrer avec Windows » : décoche-la avant, ou supprime la valeur `WindowsToolbox` dans `HKCU\...\CurrentVersion\Run`.
- **Antivirus/SmartScreen râle sur l'EXE ?** Normal pour un exe non signé : signe-le (`-SignCert`) ou distribue le `.ps1` avec le `.cmd`.
- **Un fichier est signalé modifié au démarrage ?** L'auto-contrôle d'intégrité a détecté une différence avec `checksums.txt` — retélécharge depuis la source officielle.

## 📄 Licence open source

**GPL-3.0** — Copyright (C) 2026 Derouiche Oussama — ∞ Infinity Coder.

Le projet est **open source** : tu peux l'utiliser, l'étudier, le modifier et le redistribuer librement. En contrepartie du copyleft GPL-3.0, **toute copie ou version modifiée doit rester open source** et créditer l'auteur d'origine. Le copyright reste la propriété de Derouiche Oussama — la licence définit simplement les droits accordés aux autres. Texte complet : fichier [`LICENSE`](LICENSE).

## ✍️ Signature du code (Certum Open Source)

Ce projet est **signé avec un certificat Certum Open Source Code Signing** — c'est le lien GitHub fourni à Certum pour la vérification.

**Signer après compilation** (SimplySign doit être connecté — la carte virtuelle Certum expose le certificat dans le magasin Windows) :

```bash
.\Build-Toolbox.ps1 -Exe -SignStore "Certum"          # compile ET signe l'EXE (+ Setup-Toolbox.exe)
.\Build-Toolbox.ps1 -Exe -SignCert "cert.pfx" -CertPassword "mdp"   # variante PFX
.\Build-Toolbox.ps1 -Checksums                        # régénère les empreintes SHA256
```

**Workflow de release complet** : `Build -Exe -SignStore "Certum"` → `Build -Checksums` → éditer `version.json` (version + sha256 ps1 + section exe avec le SHA256 de l'EXE) → `git push` → créer la Release GitHub avec les assets.

## 💜 Soutenir le projet

Le bouton **« Faire un don »** (barre du haut + À propos) ouvre ta page PayPal — personnalise-la en tête de `Windows-Toolbox.ps1` (`$script:DonationUrl`). Les liens site/réseaux sociaux sont juste en dessous.

---

*∞ Infinity Coder — Derouiche Oussama · [derouicheoussama.com](https://www.derouicheoussama.com) · [github.com/derouicheoussama](https://github.com/derouicheoussama)*
