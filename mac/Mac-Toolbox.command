#!/bin/bash
# =================================================================
#  MAC TOOLBOX — Diagnostics, maintenance, raccourcis & réglages
#  ∞ Infinity Coder — Derouiche Oussama
#  https://www.derouicheoussama.com  ·  https://github.com/derouicheoussama
# =================================================================
#  Usage : double-clic sur Mac-Toolbox.command (ou : bash Mac-Toolbox.command)
#  Aucune installation. Certaines actions demandent le mot de passe (sudo).
# =================================================================

VERSION="1.1.0"
MANIFEST_URL="https://raw.githubusercontent.com/derouicheoussama/windows-toolbox/main/mac/mac-version.json"
SCRIPT_URL="https://raw.githubusercontent.com/derouicheoussama/windows-toolbox/main/mac/Mac-Toolbox.command"

RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'
YELLOW='\033[1;33m'; GRAY='\033[0;90m'; BOLD='\033[1m'; NC='\033[0m'

# Garde-fou : à exécuter sur macOS uniquement
if [[ "$(uname)" != "Darwin" ]]; then
    echo "Ce programme est conçu pour macOS (ceci n'est pas un Mac)."
    exit 1
fi

header() {
    clear
    echo -e "${BLUE}${BOLD}=============================================================${NC}"
    echo -e "${BLUE}${BOLD}  MAC TOOLBOX v${VERSION} — Diagnostics · Maintenance · Raccourcis${NC}"
    echo -e "${GRAY}  ∞ Infinity Coder — Derouiche Oussama${NC}"
    echo -e "${BLUE}${BOLD}=============================================================${NC}"
}

pause() { echo ""; read -r -p "Entrée pour continuer…" _; }

section() { echo -e "\n${CYAN}${BOLD}$1${NC}"; }

# ----------------------------------------------------------------
self_update() {
    echo "Vérification de mise à jour…"
    local remote rver ok
    remote=$(curl -s --max-time 15 "$MANIFEST_URL")
    rver=$(echo "$remote" | grep -o '"version" *: *"[^"]*"' | cut -d '"' -f4)
    if [ -z "$rver" ]; then
        echo "Manifeste indisponible (hors ligne ?) — v$VERSION conservée."
        pause; return
    fi
    if [ "v$rver" = "v$VERSION" ]; then
        echo -e "${GREEN}Tu as déjà la dernière version (v$VERSION) ✓${NC}"
        pause; return
    fi
    echo -e "${YELLOW}Nouvelle version v$rver disponible (tu as la v$VERSION).${NC}"
    read -r -p "Télécharger et installer maintenant ? [o/N] : " ok
    if [[ ! "$ok" =~ ^[oO]$ ]]; then echo "Mise à jour reportée."; pause; return; fi
    curl -sL --max-time 60 -o "$0.new" "$SCRIPT_URL"
    if ! bash -n "$0.new" 2>/dev/null; then
        echo -e "${RED}Fichier téléchargé invalide — installation annulée (sécurité).${NC}"
        rm -f "$0.new"
        pause
        return
    fi
    local want got
    want=$(echo "$remote" | grep -o '"sha256" *: *"[^"]*"' | cut -d '"' -f4)
    if [ -n "$want" ]; then
        got=$(shasum -a 256 "$0.new" 2>/dev/null | awk '{print $1}' | tr 'A-Z' 'a-z')
        if [ "$got" != "$(echo "$want" | tr 'A-Z' 'a-z')" ]; then
            echo -e "${RED}Empreinte SHA256 différente du manifeste — installation annulée (sécurité).${NC}"
            rm -f "$0.new"
            pause
            return
        fi
        echo "Empreinte SHA256 du téléchargement vérifiée ✓"
    fi
    chmod +x "$0.new"
    mv -f "$0.new" "$0"
    echo -e "${GREEN}Version $rver installée — relance de la toolbox…${NC}"
    sleep 1
    exec bash "$0"
}

# ----------------------------------------------------------------
infos_systeme() {
    section "INFOS SYSTÈME"
    echo "macOS      : $(sw_vers -productVersion) (build $(sw_vers -buildVersion))"
    echo "Machine    : $(sysctl -n hw.model 2>/dev/null)"
    system_profiler SPHardwareDataType 2>/dev/null | grep -E "Model Name|Chip|Processor|Total Number of Cores|Memory|Serial"
    echo "Allumé depuis : $(uptime | sed 's/.*up //; s/, *load.*//; s/,.*uptime.*//')"
    echo ""
    echo "→ Rapport matériel complet : system_profiler (menu Disques/Réseau aussi)."
    pause
}

disques() {
    section "DISQUES & SSD"
    echo "=== Volumes & espace ==="
    df -h / /System/Volumes/Data 2>/dev/null | grep -v "^map"
    echo ""
    echo "=== Disques (diskutil list) ==="
    diskutil list 2>/dev/null
    echo ""
    echo "=== Santé du volume système ==="
    diskutil info / 2>/dev/null | grep -E "Volume Name|File System|SMART Status|Disk Size|Volume Used|Volume Free"
    echo ""
    echo "=== TRIM (SSD) ==="
    system_profiler SPNVMeDataType 2>/dev/null | grep -iE "Model|TRIM" || echo "Pas de NVMe détecté (Mac ancien ?)"
    echo ""
    read -r -p "Vérifier le volume système maintenant (diskutil verifyVolume, ~1 min) ? [o/N] : " ok
    if [[ "$ok" =~ ^[oO]$ ]]; then diskutil verifyVolume /; fi
    pause
}

batterie() {
    section "BATTERIE"
    pmset -g batt
    echo ""
    echo "=== Santé & cycles (system_profiler) ==="
    system_profiler SPPowerDataType 2>/dev/null | grep -E "Cycle Count|Condition|State of Health|Full Charge Capacity|Charge Remaining|Charging"
    echo ""
    echo "→ « Condition : Normal » et « State of Health : Good » = bonne santé."
    echo "→ Plus de 800-1000 cycles = batterie en fin de vie (à négocier à l'achat)."
    pause
}

ecran() {
    section "ÉCRAN & GPU"
    system_profiler SPDisplaysDataType 2>/dev/null | grep -E "Chipset|Cores|VRAM|Metal|Resolution|UI Looks like|Frames"
    echo ""
    echo "→ Les Hz du écran apparaissent dans « UI Looks like … @ xx Hz » (si exposé)."
    echo "→ Test pixels morts : menu Raccourcis → plein écran blanc puis noir."
    pause
}

reseau() {
    section "RÉSEAU"
    echo "=== Services réseau ==="
    networksetup -listallnetworkservices 2>/dev/null
    echo ""
    echo "=== Configuration IP (Wi-Fi / Ethernet actifs) ==="
    ifconfig en0 2>/dev/null | grep -E "inet |status" ; ifconfig en1 2>/dev/null | grep -E "inet |status"
    echo "IP publique : $(curl -s --max-time 8 https://ifconfig.me || echo 'hors ligne')"
    echo ""
    echo "=== Ports en écoute ==="
    lsof -iTCP -sTCP:LISTEN -P -n 2>/dev/null | head -15
    echo ""
    read -r -p "Ping Internet 8.8.8.8 ? [o/N] : " ok
    if [[ "$ok" =~ ^[oO]$ ]]; then ping -c 4 8.8.8.8; fi
    pause
}

maj_macos() {
    section "MISES À JOUR macOS"
    echo "Recherche des mises à jour macOS (softwareupdate -l)…"
    softwareupdate -l 2>&1
    echo ""
    read -r -p "Tout installer maintenant (sudo, peut être long) ? [o/N] : " ok
    if [[ "$ok" =~ ^[oO]$ ]]; then sudo softwareupdate -i -a; fi
    echo ""
    echo "→ Apps non-App Store : utilise Homebrew (menu suivant) ou leurs mises à jour internes."
    pause
}

nettoyage() {
    section "NETTOYAGE"
    echo "Tailles avant nettoyage :"
    du -sh ~/Library/Caches 2>/dev/null
    du -sh ~/.Trash 2>/dev/null || echo "Corbeille : vide"
    echo ""
    read -r -p "Vider les caches UTILISATEUR (~/Library/Caches) ? [o/N] : " ok
    if [[ "$ok" =~ ^[oO]$ ]]; then rm -rf ~/Library/Caches/* 2>/dev/null; echo "Caches utilisateur vidés."; fi
    read -r -p "Vider la corbeille ? [o/N] : " ok
    if [[ "$ok" =~ ^[oO]$ ]]; then rm -rf ~/.Trash/* 2>/dev/null; echo "Corbeille vidée."; fi
    read -r -p "Vider le cache DNS + purge mémoire (sudo) ? [o/N] : " ok
    if [[ "$ok" =~ ^[oO]$ ]]; then
        sudo dscacheutil -flushcache
        sudo killall -HUP mDNSResponder
        sudo purge
        echo "Cache DNS vidé + mémoire purgée."
    fi
    if command -v brew >/dev/null 2>&1; then
        read -r -p "Homebrew détecté — brew cleanup (anciens téléchargements) ? [o/N] : " ok
        if [[ "$ok" =~ ^[oO]$ ]]; then brew cleanup --prune=all; fi
    fi
    echo ""
    echo "→ Les zones « admin » (caches système) sont protégées : reste volontairement prudent."
    pause
}

brew_apps() {
    section "HOME BREW — apps & mises à jour"
    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew n'est pas installé (c'est le « winget » du Mac)."
        echo "Installe-le avec : /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        pause; return
    fi
    echo "=== Apps installées (brew) ==="
    brew list --versions 2>/dev/null | head -20
    echo ""
    echo "=== Obsolètes (brew outdated) ==="
    brew outdated
    echo ""
    read -r -p "Tout mettre à jour (brew upgrade) ? [o/N] : " ok
    if [[ "$ok" =~ ^[oO]$ ]]; then brew upgrade; fi
    pause
}

processus() {
    section "PROCESSUS & PERFORMANCE"
    echo "=== Top CPU ==="
    ps -Ao pcpu,pid,comm -r | head -12
    echo ""
    echo "=== Top RAM ==="
    ps -Ao pmem,pid,comm -m | head -12
    echo ""
    vm_stat | head -8
    echo ""
    read -r -p "Tuer un processus par PID ? (Entrée pour passer) : " pid
    if [ -n "$pid" ]; then kill "$pid" 2>/dev/null && echo "Signal envoyé à $pid." || echo "Échec (droits ? PID invalide ?)"; fi
    pause
}

materiel() {
    section "MATÉRIEL COMPLET (detection peripheriques)"
    echo "=== CARTE MÈRE / MACHINE ==="
    system_profiler SPHardwareDataType 2>/dev/null
    echo ""
    echo "=== MÉMOIRE RAM ==="
    system_profiler SPMemoryDataType 2>/dev/null || echo "(RAM soudée sur cette machine — non listable)"
    echo ""
    echo "=== DISQUES / NVMe / SATA ==="
    system_profiler SPNVMeDataType 2>/dev/null
    system_profiler SPSerialATADataType 2>/dev/null | head -20
    echo ""
    echo "=== GRAPHIQUE & ÉCRAN ==="
    system_profiler SPDisplaysDataType 2>/dev/null
    echo ""
    echo "=== AUDIO ==="
    system_profiler SPAudioDataType 2>/dev/null | head -25
    echo ""
    echo "=== USB (périphériques branchés) ==="
    system_profiler SPUSBDataType 2>/dev/null | grep -E "^\s{4,8}[A-Za-z]|Product ID|Vendor ID" | head -25
    echo ""
    echo "=== RÉSEAU (Wi-Fi, Ethernet, Bluetooth) ==="
    system_profiler SPNetworkDataType 2>/dev/null | head -20
    system_profiler SPBluetoothDataType 2>/dev/null | head -12
    echo ""
    echo "=== IMPRIMANTES ==="
    system_profiler SPPrintersDataType 2>/dev/null | head -12
    pause
}

reparations() {
    section "RÉPARATIONS"
    read -r -p "Vérifier puis réparer le volume système (sudo, ~2 min) ? [o/N] : " ok
    if [[ "$ok" =~ ^[oO]$ ]]; then
        diskutil verifyVolume /
        read -r -p "Des erreurs ? Réparer maintenant ? [o/N] : " ok2
        if [[ "$ok2" =~ ^[oO]$ ]]; then sudo diskutil repairVolume /; fi
    fi
    echo ""
    echo "=== GUIDES (impossibles depuis un logiciel, à faire au clavier) ==="
    echo "• NVRAM (Intel)      : redémarre en maintenant Option+Commande+P+R (20 s)."
    echo "• NVRAM (Apple S.)   : éteins, puis laisse allumé 30 s, rallume (recalcul auto)."
    echo "• SMC (Intel)        : éteins, Maj+Ctrl+Option + bouton power 10 s, rallume."
    echo "• Mode sans échec    : Intel = Maj au démarrage · Apple Silicon = bouton power maintenu."
    echo "• Utilitaire disque au démarrage : Cmd+R (Intel) / Options (Apple Silicon)."
    pause
}

prebuy() {
    section "ACHAT MAC — CHECKLIST COMPLÈTE"
    local out="$HOME/Desktop/verification-mac-$(hostname -s)-$(date +%Y%m%d-%H%M).txt"
    {
        echo "============================================================"
        echo "  TEST PRÉ-ACHAT MAC — Mac Toolbox (∞ Infinity Coder)"
        echo "============================================================"
        echo "Date : $(date '+%Y-%m-%d %H:%M')"
        echo ""
        echo "[1] SPÉCIFICATIONS (compare avec l'annonce)"
        system_profiler SPHardwareDataType 2>/dev/null | grep -E "Model Name|Model Identifier|Chip|Processor|Total Number of Cores|Memory|Serial Number"
        sw_vers -productVersion | awk '{print "macOS          : "$0}'
        system_profiler SPDisplaysDataType 2>/dev/null | grep -E "Resolution|UI Looks like"
        diskutil info / 2>/dev/null | grep -E "Disk Size|Volume Used|Volume Free|SMART Status"
        echo ""
        echo "[2] BATTERIE"
        system_profiler SPPowerDataType 2>/dev/null | grep -E "Cycle Count|Condition|State of Health|Full Charge Capacity"
        pmset -g batt
        echo ""
        echo "[3] FIABILITÉ"
        echo "Rapports de plantage : $(ls -1 ~/Library/Logs/DiagnosticReports 2>/dev/null | wc -l | tr -d ' ') fichiers"
        echo "Allumé depuis : $(uptime | sed 's/.*up //')"
        echo ""
        echo "[4] SÉCURITÉ"
        csrutil status
        fdesetup status
        /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
        echo ""
        echo "============================================================"
    } | tee "$out"
    echo ""
    echo "→ Rapport enregistré : $out"
    echo "→ Vérifie aussi à la main : écran (pixels), clavier, enceintes, micro, ports USB-C, tracepad."
    pause
}

securite() {
    section "SÉCURITÉ"
    echo "=== SIP (System Integrity Protection) ==="
    csrutil status
    echo "=== FileVault (chiffrement du disque) ==="
    fdesetup status
    echo "=== Pare-feu applicatif ==="
    /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
    echo "=== Gatekeeper (apps externes) ==="
    spctl --status
    echo ""
    echo "→ SIP désactivé ou Gatekeeper inactif sur un Mac à acheter = méfiance."
    pause
}

raccourcis() {
    section "RACCOURCIS — choisis"
    echo "  1) Calculatrice      2) Notes            3) Aperçu (Preview)"
    echo "  4) Moniteur d'activité  5) Utilitaire de disque  6) Terminal"
    echo "  7) Téléchargements   8) Bibliothèque (caché)  9) /Applications"
    echo " 10) Réglages Réseau  11) Réglages Batterie  12) Réglages Général"
    read -r -p "Choix : " c
    case $c in
        1) open -a "Calculator" ;;
        2) open -a "Notes" ;;
        3) open -a "Preview" ;;
        4) open -a "Activity Monitor" ;;
        5) open -a "Disk Utility" ;;
        6) open -a "Terminal" ;;
        7) open "$HOME/Downloads" ;;
        8) open "$HOME/Library" ;;
        9) open "/Applications" ;;
        10) open "x-apple.systempreferences:com.apple.preference.network" ;;
        11) open "x-apple.systempreferences:com.apple.preference.battery" ;;
        12) open "x-apple.systempreferences:com.apple.preference.general" 2>/dev/null || open "x-apple.systempreferences" ;;
        *) echo "Choix invalide." ;;
    esac
}

show_menu() {
    header
    echo ""
    echo -e "  ${BOLD} 1)${NC} Infos système              ${BOLD} 8)${NC} Homebrew : apps & mises à jour"
    echo -e "  ${BOLD} 2)${NC} Disques & SSD (santé)      ${BOLD} 9)${NC} Processus & performance"
    echo -e "  ${BOLD} 3)${NC} Batterie (santé, cycles)   ${BOLD}10)${NC} Réparations (NVRAM/SMC/disque)"
    echo -e "  ${BOLD} 4)${NC} Écran & GPU                ${BOLD}11)${NC} ACHAT MAC — checklist"
    echo -e "  ${BOLD} 5)${NC} Réseau (IP, ping, DNS)     ${BOLD}12)${NC} Sécurité (SIP, FileVault…)"
    echo -e "  ${BOLD} 6)${NC} Mises à jour macOS         ${BOLD}13)${NC} Raccourcis (apps, réglages)"
    echo -e "  ${BOLD} 7)${NC} Nettoyage (caches…)        ${BOLD}14)${NC} Mettre à jour la toolbox"
    echo -e "  ${BOLD}15)${NC} Matériel complet (carte mère, RAM, USB…)"
    echo ""
    echo -e "  ${BOLD} 0)${NC} Quitter"
    echo ""
    read -r -p "  Choix : " choix
}

while true; do
    show_menu
    case $choix in
        1) infos_systeme ;;
        2) disques ;;
        3) batterie ;;
        4) ecran ;;
        5) reseau ;;
        6) maj_macos ;;
        7) nettoyage ;;
        8) brew_apps ;;
        9) processus ;;
        10) reparations ;;
        11) prebuy ;;
        12) securite ;;
        13) raccourcis ;;
        14) self_update ;;
        15) materiel ;;
        0) clear; echo "∞ Infinity Coder — merci !"; exit 0 ;;
        *) ;;
    esac
done
