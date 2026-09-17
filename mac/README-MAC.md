# 🍎 Mac Toolbox

> **L'équivalent de la Windows 11 Toolbox pour macOS** : diagnostics, batterie, disques/SSD, réseau, nettoyage, sécurité, checklist d'achat Mac et raccourcis — un seul fichier, **aucune installation**.
> ∞ Infinity Coder — [Derouiche Oussama](https://www.derouicheoussama.com) · [GitHub](https://github.com/derouicheoussama)

---

## 🚀 Utilisation

1. Copie `Mac-Toolbox.command` sur le Mac (clé USB, AirDrop, e-mail…)
2. **Double-clic** dessus (ou clic droit → *Ouvrir avec* → Terminal)
   - Première ouverture depuis Internet : clic droit → **Ouvrir** (contourne Gatekeeper)
3. Navigue avec les **numéros** au clavier, `0` pour quitter

**Prérequis** : macOS uniquement. Aucune dépendance (bash + outils système natifs). `Homebrew` optionnel pour le menu apps.

## 🗂 Les 14 fonctions

| # | Fonction | Détail |
|---|---|---|
| 1 | **Infos système** | macOS, modèle, puce, cœurs, RAM, numéro de série, uptime |
| 2 | **Disques & SSD** | Volumes, espace, `diskutil list`, **statut SMART**, **TRIM**, vérification/réparation du volume |
| 3 | **Batterie** | Charge en cours, **cycles**, **condition / State of Health**, capacité pleine vs origine |
| 4 | **Écran & GPU** | Puce graphique, résolution, Hz (si exposé), renvoi vers le test pixels |
| 5 | **Réseau** | Services, IP locale/publique, ports en écoute, ping |
| 6 | **Mises à jour macOS** | Liste + installation (`softwareupdate`) |
| 7 | **Nettoyage** | Caches utilisateur, corbeille, **cache DNS**, purge mémoire, `brew cleanup` |
| 8 | **Homebrew** | Le « winget du Mac » : apps installées, obsolètes, `brew upgrade` |
| 9 | **Processus** | Top CPU / RAM, tuer un processus |
| 10 | **Réparations** | Vérifier/réparer le volume, **guides NVRAM / SMC / mode sans échec** (Intel & Apple Silicon) |
| 11 | **ACHAT MAC — checklist** | Specs + batterie (cycles/santé) + plantages + sécurité → **rapport .txt sur le Bureau** |
| 12 | **Sécurité** | SIP, FileVault, pare-feu, Gatekeeper |
| 13 | **Raccourcis** | Apps, dossiers (y compris Bibliothèque cachée), réglages Système |
| 14 | **Mettre à jour la toolbox** | Auto-update depuis GitHub (contrôle de syntaxe avant installation) |

## ⌨️ Notes

- Les actions sensibles demandent le **mot de passe** (sudo) directement dans le Terminal.
- Le **raccourci global à la Windows (Ctrl+Alt+T)** n'existe pas en bash natif : il faudrait une app compilée (Hammerspoon). La toolbox reste un onglet Terminal qu'on ferme/rappelle librement.
- **Mises à jour** : même système que la version Windows — manifeste sur GitHub, contrôle de version et de syntaxe avant installation. Publier une version : augmenter `VERSION` dans le script, éditer `mac-version.json`, pousser.

## 💜 Soutenir

[PayPal](https://www.paypal.com/donate) — lien personnalisable en tête du script comme pour la version Windows.

---

*∞ Infinity Coder — Derouiche Oussama · [derouicheoussama.com](https://www.derouicheoussama.com)*
