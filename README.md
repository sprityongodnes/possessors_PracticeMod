# 🎭 Possessor(s) - UE4SS Practice Mod

[EN] A lightweight practice and speedrun mod for **Possessor(s)**, powered by UE4SS. Features local savestates, real-time timer, FPS counter, health/ammo tracking, and a customizable HUD overlay.

[FR] Un mod d'entraînement et de speedrun léger pour **Possessor(s)** via UE4SS. Inclut des savestates locales, un chrono en temps réel, un compteur d'images par seconde (FPS), le suivi de la santé/munitions et un HUD entièrement personnalisable.

---

## 👥 Credits / Crédits

- **Co-Engineer / Co-Ingénieur :** [drewkri](https://github.com/drewkri)

---

## ✨ Features / Fonctionnalités

- **💾 Savestates (5 Slots) :** Saves player position, rotation, health, ammo, current timer, and `SaveSlotSubsystem` game data. / _Sauvegarde la position, la rotation, la santé, les munitions, le chrono actuel et l'état du jeu._
- **⏱️ Speedrun Timer :** Live timer display formatted in `mm:ss.ms` or `hh:mm:ss.ms`. / _Chronomètre en temps réel._
- **📈 FPS Counter :** Live frames per second tracking. / _Affichage des images par seconde en temps réel._
- **📊 Attempt Counter :** Automatically tracks attempts per save slot upon reloading. / _Compteur d'essais automatique par slot._
- **🎨 Persistent HUD :** Free pixel movement and dynamic text scaling saved in `practice_mod_config.txt`. / _Positionnement libre en pixels et taille de texte ajustablement sauvegardés._

---

## 🎮 Controls & Keybinds / Commandes & Raccourcis

| Key / Touche             | Action (EN)                     | Action (FR)                                 |
| :----------------------- | :------------------------------ | :------------------------------------------ |
| **F1**                   | Toggle Timer Start/Pause        | Démarrer / Pause le chrono                  |
| **F2**                   | Reset Timer                     | Réinitialiser le chrono                     |
| **F3 / F4**              | Previous / Next Save Slot (1-5) | Slot de sauvegarde précédent / suivant      |
| **F5**                   | Save State                      | Sauvegarder la position, le chrono & l'état |
| **F6**                   | Load State                      | Charger la position, le chrono & l'état     |
| **F7**                   | Toggle Timer Visibility         | Afficher / Cacher le chrono                 |
| **F8**                   | Toggle Stats Visibility         | Afficher / Cacher les stats (Slot & Essais) |
| **F9**                   | Toggle FPS Visibility           | Afficher / Cacher les FPS                   |
| **Arrow Keys / Flèches** | Move HUD freely                 | Déplacer le HUD librement (Pixels X/Y)      |
| **Page Up / Page Down**  | Scale HUD Size                  | Agrandir / Réduire la taille du HUD         |

---

## 📦 Installation

1. Install **UE4SS** for _Possessor(s)_.
2. Download the latest release from the "Releases" page on the right (download the file labeled `Source Code.zip`).
3. Place the contents of that file in `Possessor(s)\Pose\Binaries\Win64\ue4ss\Mods\PracticeMod\`.
4. Ensure the mod folder name (`PracticeMod`) is added to `Mods/mods.txt` and set to `1`.
