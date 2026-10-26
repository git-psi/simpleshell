# SimpleShell

**Un shell pour Hyprland, sans barre : rien à l'écran, tout à portée de main.**

Ton bureau reste vide. Le panneau rapide, les notifications, le lanceur ou les captures d'écran
apparaissent d'un raccourci ou d'un glissement de doigts sur le pavé tactile, puis s'effacent.
Écrit avec [Quickshell](https://quickshell.org), pour Arch Linux.

![simpleshell : le panneau rapide](docs/screenshots/panel.jpg)

<details>
<summary><b>Voir la vidéo</b></summary>
<br>

![Démonstration de simpleshell](docs/showcase.mp4)

</details>

## Ce qu'il y a dedans

| | |
|---|---|
| <img src="docs/screenshots/panel.jpg" alt="Panneau rapide" width="420"> | **Panneau rapide** `Super + A`<br>Heure, batterie, Wi-Fi, Bluetooth, Ne pas déranger, éclairage nocturne, profil d'énergie, caféine, luminosité, son, micro, musique en cours, applis en arrière-plan. |
| <img src="docs/screenshots/notifications.jpg" alt="Notifications" width="420"> | **Notifications** `Super + N`<br>Historique, aperçu des images, boutons d'action, Ne pas déranger. |
| <img src="docs/screenshots/launcher.jpg" alt="Lanceur" width="420"> | **Lanceur** `Super + Espace`<br>Tape le nom d'une appli. Commence par une espace pour chercher sur le web. |
| <img src="docs/screenshots/power.jpg" alt="Menu d'alimentation" width="420"> | **Menu d'alimentation** `Super + Échap`<br>Verrouiller, veille, déconnexion, éteindre, redémarrer. |
| <img src="docs/screenshots/settings.jpg" alt="Réglages" width="420"> | **Réglages** (bouton du panneau)<br>Couleur d'accent, thème clair ou sombre, fond d'écran, délais de veille, position des notifications… |

Et aussi :

- **Des bulles discrètes (OSD)** pour le volume, la luminosité, le clavier, le micro, le mode
  avion, ...
- **Des rappels** : batterie faible, clé USB branchée.
- **La demande de mot de passe administrateur** (polkit), aux couleurs du shell.
- **L'écran de verrouillage et l'écran de connexion** assortis (utilise sddm).
- **Tes applis aux mêmes couleurs** : GTK, Qt, KDE, Alacritty, mpv, micro, imv, et les bordures
  des fenêtres. Change la couleur, tout s'adapte.

## Captures d'écran et vidéos

![Menu de capture](docs/screenshots/capture.jpg)

Appuie sur `Impr. écran` (ou `Super + Maj + S`).

- **Screen**, **Region**, **Window** : tout l'écran, une zone à dessiner, ou une fenêtre à
  cliquer.
- **Record screen**, **Record region**, Enregistre l'ecran sous forme vidéo, pour arrêter, appuie à nouveau sur `Impr. écran`.
- Pressé deux fois de suite, `Impr. écran` capture directement tout l'écran.

La capture est copiée dans le presse-papier et rangée dans `Images/Screenshots` (ou
`Vidéos/Recordings`).

![Notification d'une capture](docs/screenshots/screenshot-notification.jpg)

## Raccourcis

| Touches | Action |
|---|---|
| `Super + A` | panneau rapide |
| `Super + N` | notifications |
| `Super + Espace` | lanceur |
| `Super + Échap` | menu d'alimentation |
| `Impr. écran` ou `Super + Maj + S` | capture d'écran |
| `Maj + Impr. écran` | capture d'une zone, directement |
| `Super + P` | disposition d'écrans (Monique) |
| 4 doigts ← / → (pavé tactile) | panneau rapide / notifications |

Les touches de volume, de luminosité, de musique et de rétroéclairage clavier marchent aussi, avec
leur bulle à l'écran.

<details>
<summary>Depuis un terminal ou un script</summary>

```sh
qs -c simpleshell ipc call shell panel             # ou notifications, launcher, power, capture
qs -c simpleshell ipc call shell page settings     # ou wifi, bluetooth
qs -c simpleshell ipc call shell dnd               # Ne pas déranger
qs -c simpleshell ipc call shell screenshot region # ou screen, window
qs -c simpleshell ipc call shell record screen     # ou region ; stopRecording pour arrêter
```

</details>

## Installation

Il te faut **Arch Linux** (ou CachyOS, EndeavourOS…) et **Hyprland 0.56 ou plus**, avec une
config en Lua (`hyprland.lua`).

```sh
git clone https://github.com/git-psi/simpleshell ~/.config/quickshell/simpleshell
~/.config/quickshell/simpleshell/install.sh
```

Puis déconnecte-toi et choisis Hyprland sur l'écran de connexion. C'est tout !

L'installeur installe ce qu'il faut, active les services, et ajoute le shell à ta config Hyprland
sans la remplacer.

<details>
<summary>Détail du script</summary>

- **Paquets** des dépôts officiels : Quickshell, les outils Hyprland, PipeWire, NetworkManager,
  Bluetooth, la gestion d'énergie, les outils de capture, les polices. Et quelques applis par
  défaut : Alacritty (avec fish), Nautilus, imv, mpv, micro.
- **AUR**, seulement pour Monique (les écrans) et le curseur Bibata, via paru, yay ou makepkg.
- **Hyprland** : ajoute `require("simpleshell")` à la fin de ton `hyprland.lua`, ou en crée un
  minimal si tu n'en as pas.
- **Services** : NetworkManager, Bluetooth, profils d'énergie, et SDDM pour l'écran de connexion.
  S'il trouve un autre écran de connexion, il te demande avant de le remplacer.
- Les fichiers qu'il remplace sont gardés à côté, en `*.bak-<date>`.

</details>

> **À ne pas lancer en même temps** : simpleshell gère lui-même les notifications et les demandes
> de mot de passe. Désactive mako, dunst, swaync, hyprpolkitagent ou polkit-gnome, et toute autre
> barre (Waybar…).

## Configuration

**Le plus simple : la page Réglages** du panneau rapide. Couleur d'accent, thème, fond d'écran,
délais de veille, moteur de recherche, position des notifications, ce que montre le panneau.
Après avoir changé l'accent ou le fond d'écran, clique sur **Sync** à la ligne *Login screen* pour
que l'écran de connexion se synchronise.

Pour aller plus loin, tout se modifie à la main, et le shell se recharge tout seul à
l'enregistrement :

| Fichier | Ce qu'il contient |
|---|---|
| `hypr/simpleshell.lua` | les raccourcis du shell, les animations des fenêtres, le curseur |
| `hypr/hyprlock.conf` | l'écran de verrouillage (redirige vers sddm) |
| `Theme.qml` | tout le style : couleurs, police, tailles, arrondis, durées |
| `Config.qml` | les commandes (verrouiller, veille…) et les moteurs de recherche |

Le reste de Hyprland (clavier, fenêtres, bureaux) reste dans ta propre config.
Tu peux voir ma configuration ici: [HYPRLAND_FR.md](HYPRLAND_FR.md).

## Développement

```sh
pkill -x qs; qs -c simpleshell      # lance le shell dans le terminal, avec ses messages de deboguage.
```

Chaque fichier enregistré recharge le shell. Pour le relancer en arrière-plan :
`qs -c simpleshell -d`.

<details>
<summary>Organisation du code</summary>

```
shell.qml        point d'entrée
Theme.qml        tout le style
Ui.qml           ce qui est ouvert
Settings.qml     les valeurs de la page Réglages
components/      briques réutilisables (boutons, tuiles, icônes Lucide…)
services/        réseau, Bluetooth, son, luminosité, énergie, notifications, captures
panel/           le panneau rapide et ses pages
notifs/          notifications
launcher/        lanceur
capture/         captures d'écran et vidéos
osd/             bulles à l'écran
power/           menu d'alimentation, veille, batterie
polkit/          mot de passe administrateur
apps/            couleurs des applis (matugen)
sddm/            écran de connexion
hypr/            config Hyprland, hypridle, hyprlock
```

</details>

Les regles pour le style suivi durant le développement :

- Chaque couleur, taille ou durée vient de `Theme.qml`, jamais écrite ailleurs.
- Des coins arrondis partout, ni cercles ni pilules (radius interne = radius externe - marge entre les deux).
- Pas d'ombres : ce qui flotte a un contour d'un pixel.
- Icônes [Lucide](https://lucide.dev) : copie le SVG dans `components/lucide/`, puis
  `Icon { name: "wifi" }`.

## Licence

MIT (`LICENSE`). Icônes [Lucide](https://lucide.dev) sous licence ISC (`LICENSE-lucide`).
