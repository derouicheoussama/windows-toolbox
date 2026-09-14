# 🧰 Windows 11 Toolbox — Commandes, SSD & Diagnostics

> **Toutes les commandes Windows, les tests SSD et les outils de diagnostic de Windows 11 — dans une seule fenêtre.**
> ∞ Infinity Coder — [Derouiche Oussama](https://www.derouicheoussama.com) · [GitHub](https://github.com/derouicheoussama)

---

## 🚀 Lancement

| Méthode | Action |
|---|---|
| `Lancer-Toolbox.cmd` | **Double-clic** — aucun réglage requis (contourne ExecutionPolicy) |
| `.\Windows-Toolbox.ps1` | Lancement direct dans PowerShell |
| `.\Windows-Toolbox.ps1 -Admin` | Relance automatique en administrateur (UAC) |
| `.\Windows-Toolbox.ps1 -List` | Mode console : inventaire disques + outils détectés (sans interface) |

**Prérequis** : Windows 10/11 + PowerShell 5.1 (inclus par défaut). Aucune installation, aucun module externe.

## 🖥️ Ce que contient l'interface (6 onglets)

| Onglet | Contenu |
|---|---|
| **🖥 Système** | Résumé PC, msinfo32, dxdiag, activation, **SFC /scannow**, **DISM** (Check/Scan/RestoreHealth, WinSxS), moniteurs (taskmgr, resmon, perfmon, eventvwr), nettoyage, rapport batterie, horloge |
| **💾 Disques & SSD** | Santé `Get-PhysicalDisk`, **SMART** (prédiction de panne), détails/firmware/série, volumes, **optimisation TRIM**, `chkdsk /scan`, **benchmark disque** (winsat), SMART détaillé (température, heures, usure), diagnostic RAM |
| **🌐 Réseau** | ipconfig /all, adaptateurs, ping Internet/box, DNS, tracert, ports en écoute, fast.com, **vidage cache DNS**, reset Winsock/TCP-IP |
| **🛠 Outils Windows** | Paramètres, registre, gpedit, msconfig, services, périphériques, programmes, variables d'env, restauration système, apps au démarrage, stockage, **winget upgrade** (liste + tout mettre à jour), terminaux |
| **⚡ Commandes rares** | **Batterie** (usure %, cycles, consommation instantanée, energy, sleepstudy, lastwake, waketimers), fsutil/TRIM, CompactOS, analyse WinSxS, vssadmin, WinSAT, bcdedit, BitLocker, ARP/route/pathping, wlanreport, événements & BSOD (Id 41/6008 + minidumps), gpresult, verifier, moniteur de fiabilité (`perfmon /rel`), psr, mrt, clé BIOS, RAM par barrette, top processus, taille des dossiers de C: |
| **🧹 Nettoyage & rapidité** | **🔍 Audit express du PC** (verdict en 30 s), mesure des fichiers temporaires, nettoyage `%TEMP%` / Temp Windows / **cache Windows Update** / Delivery Optimization / vignettes / WER / **cache Chrome-Edge** / corbeille (avec Mo libérés affichés), point de restauration, **hibernation off (libère hiberfil.sys)**, plans Haute performance/Équilibré, redémarrage Explorateur, apps au démarrage, réparation recherche Windows & apps Store, réduction télémétrie |
| **🛒 Achat PC (pré-achat)** | **TEST PRÉ-ACHAT COMPLET en un clic** : specs réelles vs annonce, santé disques + SMART, historique BSOD/arrêts (90 j), erreurs 7 j, activation Windows, Defender, usure batterie, périphériques en erreur → **verdict + rapport .txt enregistré automatiquement**. Vérifications une par une. **Tests matériels guidés** : pixels morts (plein écran 9 couleurs), test clavier, test son (bips), webcam, ports USB. Idéal depuis une clé USB (aucune installation) |
| **🧰 Outils tiers** | Détection automatique des outils installés (CrystalDiskInfo, HWiNFO…) + boutons vers sites officiels + lancement des `.exe` portables du dossier `tools\` |
| **ℹ À propos** | Mode d'emploi + crédits |

**Code couleur** : 🔵 bleu = commande exécutée ici (résultat dans la console en bas) · 🟠 orange = droits admin requis (fenêtre UAC) · ⚪ blanc = ouvre un outil intégré · 🔷 bleu clair = site officiel.

## 🔒 Sécurité & confiance

- **Lecture seule par défaut** : à l'ouverture, seul un inventaire informatif est lancé automatiquement.
- **Aucune action destructive cachée** : tout se lance par bouton, et les actions sensibles (TRIM, chkdsk, reset réseau…) passent par une console administrateur séparée que tu lis avant de valider.
- Le bouton **« Enregistrer rapport »** exporte toute la console en `.txt` (utile pour garder une trace d'un diagnostic).

## 📁 Dossier `tools\`

Place ici tes outils **portables** (`Victoria.exe`, `HWiNFO64.exe`, `BlueScreenView.exe`, `GPU-Z.exe`…) :
ils apparaissent automatiquement en bouton dans l'onglet **Outils tiers**.

## 🛒 Mode « achat PC d'occasion »

Copie **tout le dossier** `windows-toolbox\` sur une clé USB. Chez le vendeur :

1. Double-clic sur `Lancer-Toolbox.cmd` — aucune installation, aucun droit admin requis pour les tests principaux.
2. Onglet **🛒 Achat PC** → bouton **« TEST PRÉ-ACHAT COMPLET »** : specs réelles, santé disques/SMART, BSOD des 90 derniers jours, activation, Defender, batterie — avec **verdict** et **rapport .txt enregistré** (sur la clé USB).
3. Tests manuels guidés : écran (pixels morts), clavier, son, webcam, USB.
4. Reprends la clé USB — le rapport reste ton preuve pour négocier.

---

# 📋 Liste des logiciels de diagnostic recommandés (.exe)

> Télécharge **uniquement depuis les sites officiels** liés ci-dessous. Les gratuits « portable » peuvent être posés dans `tools\`.

## 1. SSD / Disques durs — santé, SMART, benchmark

| Outil | Usage | Licence | Site |
|---|---|---|---|
| **CrystalDiskInfo** | Santé SMART, température, heures d'utilisation, statut « Bon/Prudence/Mauvais » | Gratuit | [crystalmark.info](https://crystalmark.info/en/software/crystaldiskinfo/) |
| **CrystalDiskMark** | Benchmark vitesse lecture/écriture séquentielle et aléatoire | Gratuit | [crystalmark.info](https://crystalmark.info/en/software/crystaldiskmark/) |
| **Victoria** | Test de surface (secteurs défectueux), SMART avancé, remap | Gratuit | [hdd.by/victoria](https://hdd.by/victoria/) |
| **HD Tune** | Test d'erreurs, benchmark, health | Essai / gratuit | [hdtune.com](http://www.hdtune.com/) |
| **ATTO Disk Benchmark** | Benchmark par tailles de blocs (validations SSD) | Gratuit | [atto.com](https://www.atto.com/disk-benchmark/) |
| **smartmontools (smartctl)** | SMART en ligne de commande, tous les disques/NVMe | Open source | [smartmontools.org](https://www.smartmontools.org/) |
| **Samsung Magician** | Diagnostic + firmware SSD Samsung | Gratuit | [samsung.com](https://semiconductor.samsung.com/consumer-storage/magician/) |
| **WD Dashboard** | Diagnostic + firmware SSD Western Digital | Gratuit | [support.wdc.com](https://support.wdc.com/downloads.aspx?p=279) |
| **SeaTools** | Diagnostic disques Seagate | Gratuit | [seagate.com](https://www.seagate.com/fr/fr/support/software/seatools/) |

## 2. RAM / Mémoire

| Outil | Usage | Licence | Site |
|---|---|---|---|
| **MemTest86** (PassMark) | Test RAM approfondi depuis clé USB bootable — la référence | Gratuit | [memtest86.com](https://www.memtest86.com/) |
| **TestMem5 (TM5)** | Stress RAM poussé (overclocking, instabilités) | Gratuit | [testmem.cz](https://testmem.cz/) |
| *Diagnostic mémoire Windows* (`mdsched.exe`) | Test RAM intégré — bouton dans l'onglet Disques | Intégré | — |

## 3. CPU / GPU / Capteurs (températures, tensions)

| Outil | Usage | Licence | Site |
|---|---|---|---|
| **HWiNFO64** | Le plus complet : capteurs, SMART, sons, rapports | Gratuit | [hwinfo.com](https://www.hwinfo.com/) |
| **HWMonitor** (CPUID) | Températures / tensions / ventilateurs, simple | Gratuit | [cpuid.com](https://www.cpuid.com/softwares/hwmonitor.html) |
| **Libre Hardware Monitor** | Capteurs matériels, open source | Open source | [librehardwaremonitor.github.io](https://librehardwaremonitor.github.io/) |
| **Core Temp** | Température CPU par cœur | Gratuit | [alcpu.com](https://www.alcpu.com/CoreTemp/) |
| **CPU-Z** | Identité CPU / RAM / carte mère + bench rapide | Gratuit | [cpuid.com](https://www.cpuid.com/softwares/cpu-z.html) |
| **GPU-Z** | Identité et capteurs carte graphique | Gratuit | [techpowerup.com](https://www.techpowerup.com/gpu-z/) |
| **OCCT** | Stress test CPU / GPU / alimentation + détection d'erreurs | Gratuit (perso) | [ocbase.com](https://www.ocbase.com/) |
| **FurMark** | Stress thermique GPU (test refroidissement) | Gratuit | [geeks3d.com](https://geeks3d.com/furmark/) |
| **AIDA64** | Suite complète diagnostic + benchmarks | Payant (essai 30 j) | [aida64.com](https://www.aida64.com/) |
| **Speccy** | Résumé matériel complet en 1 écran | Gratuit | [ccleaner.com/speccy](https://www.ccleaner.com/speccy) |

## 4. Système / Pannes (BSOD, processus, démarrage)

| Outil | Usage | Licence | Site |
|---|---|---|---|
| **Process Explorer** | Gestionnaire des tâches avancé (Microsoft Sysinternals) | Gratuit | [learn.microsoft.com/sysinternals](https://learn.microsoft.com/sysinternals/) |
| **Process Monitor** | Journal temps réel fichiers/registre/réseau (Sysinternals) | Gratuit | [learn.microsoft.com/sysinternals](https://learn.microsoft.com/sysinternals/) |
| **Autoruns** | Tout ce qui se lance au démarrage (Sysinternals) | Gratuit | [learn.microsoft.com/sysinternals](https://learn.microsoft.com/sysinternals/) |
| **BlueScreenView** | Analyse des écrans bleus (minidumps) — fautif identifié | Gratuit | [nirsoft.net](https://www.nirsoft.net/utils/blue_screen_view.html) |
| **WhoCrashed** | Cause des crashs expliquée en langage clair | Gratuit (perso) | [resplendence.com](https://www.resplendence.com/whocrashed) |
| **Everything** | Recherche de fichiers instantanée (diagnostic d'espace) | Gratuit | [voidtools.com](https://www.voidtools.com/) |
| **Revo Uninstaller** | Désinstallation propre + nettoyage résidus | Freemium | [revouninstaller.com](https://www.revouninstaller.com/) |
| **Malwarebytes** | Antimalware complémentaire à Defender | Freemium | [malwarebytes.com](https://www.malwarebytes.com/) |

## 5. Réseau

| Outil | Usage | Licence | Site |
|---|---|---|---|
| **Wireshark** | Capture et analyse du trafic réseau | Open source | [wireshark.org](https://www.wireshark.org/) |
| *Outils intégrés* | ipconfig, ping, tracert, netsh, Get-NetTCPConnection — boutons dans l'onglet Réseau | Intégré | — |

## 🎯 Kit minimal conseillé

1. **CrystalDiskInfo** — santé SSD en un coup d'œil
2. **CrystalDiskMark** — prouver une baisse de performances disque
3. **HWiNFO64** — températures et tensions
4. **MemTest86** — éliminer la RAM en cas de crashs aléatoires
5. **BlueScreenView** — comprendre un écran bleu

## ⌨️ Raccourcis & systray (v2.0)

| Raccourci | Action |
|---|---|
| **Ctrl+Alt+T** *(global, partout)* | Afficher / masquer la toolbox — même en plein jeu ou film |
| Ctrl+1 … Ctrl+9 | Changer d'onglet |
| Ctrl+H | Masquer dans la zone de notification (systray) |
| Ctrl+U | Vérifier les mises à jour |
| F1 | Onglet À propos |
| Icône systray — clic gauche | Afficher / masquer |
| Icône systray — clic droit | Menu : audit express, mises à jour, quitter |

**Options persistantes** (onglet 🚀 Raccourcis → Options, stockées dans le registre) : réduire dans le systray au lieu de la barre des tâches · activer/désactiver le raccourci global · **démarrer automatiquement avec Windows**.

## 🚀 Onglet Raccourcis

Applications Windows (calculatrice, capture, clavier visuel…), réglages rapides (Bluetooth, WiFi, thème, nuit, son…), dossiers usuels (Téléchargements, TEMP…), actions système (verrouiller, afficher le bureau, vider le presse-papiers, veille, redémarrer/éteindre avec avertissement).

## 🔄 Mises à jour à distance

La toolbox se met à jour **toute seule depuis GitHub** :

- **Au démarrage** : vérification silencieuse (aucune interruption si rien de neuf ou hors ligne).
- **Manuellement** : bouton **« Vérifier les mises à jour »** dans le bandeau de l'onglet *À propos*.
- Si une version plus récente existe : proposition de téléchargement → **vérification du SHA256** (si renseigné dans le manifeste) → **validation de la syntaxe** → remplacement du fichier → redémarrage proposé.

**Publier / mettre à jour (toi, côté auteur) :**

1. Crée le dépôt GitHub `derouicheoussama/windows-toolbox` puis pousse `Windows-Toolbox.ps1` et `version.json` :
   ```bash
   git init && git add . && git commit -m "Windows 11 Toolbox"
   git branch -M main
   git remote add origin https://github.com/derouicheoussama/windows-toolbox.git
   git push -u origin main
   ```
2. Pour chaque nouvelle version : augmente `$script:ToolboxVersion` dans le .ps1, régénère l'empreinte (`.\Build-Toolbox.ps1`), édite `version.json` (version + notes + sha256), pousse. Les utilisateurs reçoivent la mise à jour au prochain démarrage.

L'URL du manifeste se personnalise en tête du script : `$script:UpdateManifestUrl`.

## 🛡️ Protection du logiciel & du code source

| Moyen | Commande | Effet |
|---|---|---|
| **Empreintes SHA256** | `.\Build-Toolbox.ps1` | Écrit `checksums.txt` ; la toolbox **se contrôle elle-même au démarrage** (alerte si le fichier est modifié/corrompu) et la mise à jour à distance refuse tout fichier dont le hash diffère du manifeste. |
| **Compilation en .EXE** | `.\Build-Toolbox.ps1 -Exe` | Convertit le script en `Windows-Toolbox.exe` autonome via **ps2exe** (code compilé, métadonnées auteur/version, pas de fenêtre console). Le code n'est plus lisible en clair comme un .ps1. |
| **Signature Authenticode** | `.\Build-Toolbox.ps1 -Exe -SignCert "cert.pfx" -CertPassword "mdp"` | Signe l'EXE (et/ou le .ps1 avec `-SignPs1`) : prouve l'auteur, **détecte toute falsification**, évite SmartScreen une fois réputé. |

**Limites honnêtes** : aucun code PowerShell n'est 100 % irrécupérable (l'EXE embarque le code compilé). La stratégie efficace est : distribuer **l'EXE signé**, garder le `.ps1` dans un **dépôt privé**, et publier les mises à jour avec leur SHA256. Un utilisateur honnête voit une application signée et intègre ; un curieux ne récupère pas le source directement.

## 💜 Soutenir le projet

Le bouton **« Faire un don »** (barre du haut + onglet À propos) ouvre ta page PayPal.
Personnalise le lien en tête de `Windows-Toolbox.ps1` : `$script:DonationUrl = 'https://www.paypal.com/donate'`.
Les liens officiels de l'auteur (site, GitHub, réseaux sociaux) sont dans l'onglet **À propos** et configurables en tête du script.

---

*∞ Infinity Coder — Derouiche Oussama · [derouicheoussama.com](https://www.derouicheoussama.com) · [github.com/derouicheoussama](https://github.com/derouicheoussama)*
