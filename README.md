# possessors_PracticeMod
One mod UE4SS for Possessor(s) game

# 🎭 Possessor(s) - UE4SS Practice Mod

[EN] A lightweight practice and speedrun mod for **Possessor(s)**, powered by UE4SS. Features local savestates, real-time timer, health/ammo tracking, and a customizable HUD overlay.

[FR] Un mod d'entraînement et de speedrun léger pour **Possessor(s)** via UE4SS. Inclut des savestates locales, un chrono en temps réel, le suivi de la santé/munitions et un HUD entièrement personnalisable.

---

## 👥 Credits / Crédits

* **Co-Engineer / Co-Ingénieur :** `drewgobrr`

---

## ✨ Features / Fonctionnalités

* **💾 Savestates (5 Slots) :** Saves player position, rotation, health, ammo, and `SaveSlotSubsystem` game data. / *Sauvegarde la position, la rotation, la santé, les munitions et l'état du jeu.*
* **⏱️ Speedrun Timer :** Live timer display formatted in `mm:ss.ms` or `hh:mm:ss.ms`. / *Chronomètre en temps réel.*
* **📊 Attempt Counter :** Automatically tracks attempts per save slot upon reloading. / *Compteur d'essais automatique par slot.*
* **🎨 Persistent HUD :** Free pixel movement and dynamic text scaling saved in `practice_mod_config.txt`. / *Positionnement libre en pixels et taille de texte ajustablement sauvegardés.*

---

## 🎮 Controls & Keybinds / Commandes & Raccourcis

| Key / Touche | Action (EN) | Action (FR) |
| :--- | :--- | :--- |
| **F1** | Toggle Timer Start/Pause | Démarrer / Pause le chrono |
| **F2** | Reset Timer | Réinitialiser le chrono |
| **F3 / F4** | Previous / Next Save Slot (1-5) | Slot de sauvegarde précédent / suivant |
| **F5** | Save State | Sauvegarder la position & l'état |
| **F6** | Load State | Charger la position & l'état |
| **F7** | Toggle Timer Visibility | Afficher / Cacher le chrono |
| **F8** | Toggle Stats Visibility | Afficher / Cacher les stats (Slot & Essais) |
| **Arrow Keys / Flèches** | Move HUD freely | Déplacer le HUD librement (Pixels X/Y) |
| **Page Up / Page Down** | Scale HUD Size | Agrandir / Réduire la taille du HUD |

---

## 📦 Installation

1. Install **UE4SS** for *Possessor(s)*.
2. Place the mod folder inside `Possessor(s)\Pose\Binaries\Win64\ue4ss\Mods\PracticeMod\Scripts`.
3. Ensure the mod folder name is added to `Mods/mods.txt` and set to `1`.
