# simpleshell

Un shell minimaliste pour [Hyprland](https://hyprland.org), écrit avec
[Quickshell](https://quickshell.org) : **rien à l'écran, tout à portée de main**. Pas de barre en
permanence. Le panneau rapide, les notifications, le lanceur et le menu d'alimentation s'ouvrent
au raccourci clavier ou au geste du pavé tactile, puis disparaissent.

![Panneau rapide](docs/screenshots/panel.png)

| Notifications | Lanceur |
|---|---|
| ![Notifications](docs/screenshots/notifications.png) | ![Lanceur](docs/screenshots/launcher.png) |

| Réglages | Écran de verrouillage |
|---|---|
| ![Réglages](docs/screenshots/settings.png) | ![Écran de verrouillage](docs/screenshots/lockscreen.png) |

## Fonctionnalités

| Élément | Comment l'ouvrir |
|---|---|
| Panneau rapide : heure, batterie, Wi-Fi, Bluetooth, Ne pas déranger, éclairage nocturne, profil d'énergie, caféine, luminosité, son, micro, applis en arrière-plan, musique | `Super + A`, ou 4 doigts vers la gauche |
| Notifications : historique, Ne pas déranger, tout effacer | `Super + N`, ou 4 doigts vers la droite |
| Notification surgissante | dans le coin choisi dans les Réglages, sauf en Ne pas déranger (les critiques passent quand même) |
| Lanceur d'applis (une espace au début = recherche web) | `Super + Espace` |
| Menu d'alimentation | `Super + Échap`, ou le bouton rouge du panneau |
| Capture d'écran (écran, zone, fenêtre) et enregistrement vidéo (écran, zone, avec ou sans son) | `Impr. écran` ou `Super + Maj + S`, ou le bouton appareil photo du panneau |
| Réglages : accent, thème clair/sombre, fond d'écran, mise en veille, notifications… | bouton Settings du panneau |
| OSD : volume, luminosité, clavier, micro, profil d'énergie, mode avion, pavé tactile, chargeur, bureaux | apparaissent seuls |
| Rappel batterie | notification à 20 %, puis une critique à 10 % |
| Clé USB | notification au branchement (bouton Ouvrir) et au retrait |
| Mot de passe administrateur (polkit) | s'ouvre seul quand une appli en a besoin |
| Écran de verrouillage (hyprlock) et de connexion (SDDM) | aux couleurs du shell |

Le shell applique aussi son thème (clair/sombre, couleur d'accent) aux applis : GTK 3/4, Qt
(qt5ct/qt6ct), KDE, Alacritty, micro, imv, mpv, rmpc, et les bordures de fenêtres d'Hyprland. Les
dossiers de Nautilus prennent la couleur d'accent.

## Installation

### Prérequis

- **Arch Linux** ou une distribution basée sur Arch (CachyOS, EndeavourOS…).
- **Hyprland 0.56 ou plus récent**, avec une config en **Lua** (`~/.config/hypr/hyprland.lua`).
  Un ancien `hyprland.conf` doit d'abord être converti.

### Installer

```sh
git clone https://github.com/git-psi/simpleshell ~/.config/quickshell/simpleshell
~/.config/quickshell/simpleshell/install.sh
```

Lance-le avec ton utilisateur, pas en root : `sudo` est demandé quand il faut. Ensuite,
déconnecte-toi (ou redémarre) et choisis Hyprland sur l'écran de connexion. Si tu es déjà dans
Hyprland : `hyprctl reload`, puis `qs -c simpleshell -d`.

### Ce que fait l'installeur

1. **Paquets** depuis les dépôts officiels : Quickshell, Hyprland et ses outils (hypridle,
   hyprlock, hyprsunset, hyprpicker, portails), PipeWire, NetworkManager, BlueZ, UPower,
   power-profiles-daemon, udisks2, brightnessctl, ddcutil, matugen, ImageMagick, les polices, SDDM,
   et pour les captures grim, wf-recorder, wl-clipboard et ffmpeg.
   Il installe aussi les applis par défaut : **Alacritty** (avec **fish** et **fastfetch**),
   **Nautilus**, **imv**, **mpv**, **micro**.
2. **AUR**, seulement pour ce qui n'est pas dans les dépôts : **Monique** (gestion des écrans,
   `Super + P`) et le curseur **Bibata**. Il passe par paru ou yay s'ils sont là, sinon par
   `makepkg`.
3. **Le shell** : un lien de `~/.config/quickshell/simpleshell` vers le dossier cloné, si tu l'as
   cloné ailleurs.
4. **Hyprland** : `simpleshell.lua` et `hyprlock.conf` sont liés dans `~/.config/hypr/`, puis :
   - si tu as un `hyprland.lua`, il ajoute `require("simpleshell")` à la fin ;
   - sinon, il crée un `hyprland.lua` minimal ;
   - si tu n'as qu'un `hyprland.conf`, il te prévient sans rien toucher.

   **Ta config reste la tienne.** Une config complète, prête à copier, est dans
   [HYPRLAND_FR.md](HYPRLAND_FR.md).
5. **Terminal** : un message d'accueil fish avec fastfetch.
6. **Applis par défaut** : Nautilus pour les dossiers, imv pour les images, mpv pour la vidéo et
   le son, micro pour le texte.
7. **Services** : NetworkManager, Bluetooth, power-profiles-daemon (sauf si tlp est actif) et
   SDDM. Si un autre gestionnaire de connexion est actif, il demande avant de le remplacer.
8. **Écran de connexion** SDDM aux couleurs du shell, et le curseur Bibata pour tout le système.

Les fichiers existants sont mis de côté en `*.bak-<date>` avant d'être remplacés. L'installeur
peut être relancé sans risque, par exemple après un `git pull`.

### Premier démarrage

Au premier lancement, le shell crée ses fichiers dans `~/.local/state/simpleshell/` (réglages,
couleurs) et la config des applis (Alacritty, mpv, micro, GTK, Qt). L'interface est en anglais.
Dans les Réglages (`Super + A`, puis le bouton Settings), choisis :

- la couleur d'accent (**Accent color**) et le thème clair ou sombre (**Theme**) ;
- le fond d'écran (**Wallpaper**) ;
- puis clique sur **Sync** à la ligne **Login screen**, pour que l'écran de connexion reprenne
  l'accent et le fond d'écran.

### À ne pas lancer en parallèle

simpleshell est **le serveur de notifications et l'agent polkit**. Ne lance pas en plus mako,
dunst, swaync, hyprpolkitagent ou polkit-gnome, ni une autre barre ou un autre shell
(Waybar, Noctalia, HyprPanel…).

## Utilisation

### Raccourcis

| Raccourci | Action |
|---|---|
| `Super + A` | panneau rapide |
| `Super + N` | notifications |
| `Super + Espace` | lanceur |
| `Super + Échap` | menu d'alimentation |
| `Super + P` | écrans (Monique) |
| `Impr. écran` ou `Super + Maj + S` | menu de capture ; à nouveau, menu ouvert : capture de tout l'écran ; pendant un enregistrement : l'arrêter |
| `Maj + Impr. écran` | capture d'une zone, directement |
| 4 doigts ← / → | panneau rapide / notifications |
| touches volume, luminosité, média, rétroéclairage clavier, pavé tactile | gérées par le shell, avec OSD |

Ces raccourcis sont dans `hypr/simpleshell.lua`. Les autres (applis, fenêtres, bureaux) relèvent
de ta propre config : voir [HYPRLAND_FR.md](HYPRLAND_FR.md).

### En ligne de commande

Toutes les actions passent aussi par IPC :

```sh
qs -c simpleshell ipc call shell panel           # ou power, notifications, launcher
qs -c simpleshell ipc call shell dnd             # Ne pas déranger
qs -c simpleshell ipc call shell clearNotifications
qs -c simpleshell ipc call shell page settings   # ou wifi, bluetooth
qs -c simpleshell ipc call shell brightness 5    # ou -5
qs -c simpleshell ipc call shell media toggle    # ou next, previous, stop
qs -c simpleshell ipc call shell capture         # comme Impr. écran
qs -c simpleshell ipc call shell screenshot region   # ou screen, window
qs -c simpleshell ipc call shell record screen   # ou region ; stopRecording pour arrêter
```

### Captures d'écran et enregistrements

- `Impr. écran` fige l'écran puis ouvre le menu : **Screen**, **Region**, **Window**,
  **Record screen**, **Record region**, et l'interrupteur **Record sound** (le son des
  haut-parleurs). Le menu n'apparaît jamais sur la capture.
- **Zone** : glisse pour la dessiner, ou clique sur une fenêtre. **Fenêtre** : clique dessus.
  Une fenêtre est capturée seule, sans ce qui passe devant (notifications, autres fenêtres).
  `Échap` ou clic droit annule.
- **Enregistrement** : compte à rebours 3, 2, 1, puis enregistrement. Pour l'arrêter :
  `Impr. écran`, `Super + Maj + S` ou le bouton stop du panneau, qui affiche la durée.
- Les captures vont dans `~/Pictures/Screenshots` (PNG), les vidéos dans `~/Videos/Recordings`
  (MP4). Ces dossiers suivent ceux de `xdg-user-dirs` : `Images`, `Vidéos` en français. L'image,
  ou le fichier vidéo, est copié dans le presse-papier.
- Une notification montre l'aperçu, avec **Open**, **Show in folder** et **Delete** (vers la
  corbeille, sans fermer le panneau des notifications).

### Comportement

- **Verrouiller** passe par `loginctl lock-session`, et hypridle lance hyprlock.
- **Veille** : le shell verrouille, affiche l'écran de connexion SDDM puis met en veille. La
  session est gardée, et se reconnecter dans SDDM la rouvre (`power/greeter.sh`).
- **Éclairage nocturne** lance `hyprsunset`. **Caféine** bloque la veille avec `systemd-inhibit`.
- Les délais de veille (verrouillage, écran éteint, mise en veille) se règlent dans
  Settings > Idle.

## Développement

### Lancer le shell à la main

```sh
pkill -x qs; qs -c simpleshell      # au premier plan, avec les logs dans le terminal
```

Quickshell recharge le shell tout seul à chaque fichier enregistré : pas besoin de le relancer.
Pour le relancer en arrière-plan : `qs -c simpleshell -d`.

### Organisation

```
install.sh         installeur (Arch)
shell.qml          point d'entrée
Theme.qml          tout le style : couleurs, police, tailles, rayons, espacements, durées
Ui.qml             ce qui est ouvert, état des interrupteurs
Config.qml         commandes (verrouiller, veille…) et réglages modifiés à la main
Settings.qml       valeurs de la page Réglages (~/.local/state/simpleshell/settings.json)
Shortcuts.qml      raccourcis Hyprland et commandes IPC
Toggles.qml        ce que font « Éclairage nocturne » et « Caféine »
Format.js          formatage partagé (volume, Bluetooth, batterie, durées)
components/        briques réutilisables (Icon, Tile, ListRow, IconButton…) et icônes Lucide
services/          luminosité, Wi-Fi, Bluetooth (+ agent d'appairage), son, applis, énergie, notifications
panel/             le panneau rapide et ses pages (Wi-Fi, Bluetooth, Réglages)
osd/               affichages à l'écran
notifs/            panneau de notifications, notifications surgissantes, clés USB
launcher/          lanceur d'applis
wallpaper/         fond d'écran
polkit/            demande de mot de passe administrateur
power/             menu d'alimentation, mise en veille, rappels batterie
apps/              thème des applis (matugen, icônes de dossiers)
capture/           captures d'écran et enregistrements : menu, sélection de zone, compte à rebours
sddm/              écran de connexion : sudo sddm/install.sh
hypr/              config Hyprland, hypridle et hyprlock
dotfiles/          accueil fish et config fastfetch, installés par install.sh
```

### Règles de design

- Chaque valeur vient de `Theme.qml` : aucune couleur ni aucun rayon écrit en dur ailleurs.
- **Rayon intérieur = rayon extérieur − marge.** Une carte de 14 px avec une marge de 10 px donne
  4 px aux éléments collés à son bord intérieur (`Theme.inner(14, 10)`).
- Pas de cercles ni de pilules : des coins arrondis partout.
- Pas d'ombres : ce qui flotte au-dessus du bureau (menus, OSD, notifications, lanceur) a un
  contour de 1 px (`Theme.outline`).
- Icônes : [Lucide](https://lucide.dev) 1.52.0 (licence ISC, voir `LICENSE-lucide`). Seules celles
  utilisées sont dans `components/lucide/`, recolorées au rendu : `Icon { name: "wifi" }`. Pour en
  ajouter une, copie son SVG depuis Lucide dans ce dossier.

### Thème des applis

`apps/AppTheme.qml` lance `apps/theme.sh` à chaque changement de thème ou d'accent. Le script
appelle matugen avec `apps/matugen/config.toml`, qui écrit les fichiers de couleurs à partir des
modèles de `apps/matugen/templates/`, puis règle le reste (gsettings, qt5ct/qt6ct, kdeglobals,
icônes de dossiers). Pour thémer une nouvelle appli, ajoute un modèle et une entrée dans
`config.toml`.

### Écran de connexion

```sh
sddm-greeter-qt6 --test-mode --theme sddm/simpleshell   # aperçu, sans l'installer
sudo sddm/install.sh                                     # installation (ou Settings > Sync)
```

## Licence

simpleshell est sous licence MIT (`LICENSE`). Icônes [Lucide](https://lucide.dev) sous licence
ISC (`LICENSE-lucide`).
