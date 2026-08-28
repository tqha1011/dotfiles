# dotfiles

Personal Linux desktop configuration for a Hyprland-based Wayland setup, managed with [GNU Stow](https://www.gnu.org/software/stow/). Each top-level directory is a stow package that maps onto `$HOME`.

## Directory tree

```text
dotfiles/
├── assets/
│   └── .local/share/
│       ├── ascii/
│       │   └── logo.txt                  # ASCII art used by fastfetch
│       └── wallpapers/                   # Wallpaper pool used by awww / waypaper
│
├── dunst/                                # Notification daemon (package present, not yet configured)
│
├── fastfetch/
│   └── .config/fastfetch/
│       └── config.jsonc                  # System info screen shown in terminal
│
├── ghostty/
│   └── .config/ghostty/
│       └── config                        # Terminal emulator config
│
├── hypr/
│   └── .config/hypr/
│       ├── hyprland.lua                  # Main Hyprland compositor config (Lua)
│       ├── hypridle.conf                 # Idle/lock/suspend timers
│       ├── hyprlock.conf                 # Lock screen config
│       ├── hyprlock/wallpapers/          # Lock screen background
│       └── scripts/
│           └── wallpaper-picker-rofi.sh  # Rofi wallpaper picker (bound to SUPER+W)
│
├── rofi/
│   └── .config/rofi/
│       ├── launcher.rasi                 # App launcher theme
│       ├── wallpaper.rasi                # Wallpaper picker theme
│       └── shared/
│           ├── colors.rasi
│           └── fonts.rasi
│
├── waybar/
│   └── .config/waybar/
│       ├── config.jsonc                  # Bar modules layout
│       ├── style.css                     # Bar styling
│       └── scripts/
│           └── auto-reload.sh            # Watches the waybar config dir and reloads on change
│
├── waypaper/
│   └── .config/waypaper/
│       └── config.ini                    # GUI wallpaper picker config
│
├── wlogout/
│   └── .config/wlogout/
│       ├── layout                        # Power menu entries
│       └── style.css
│
├── zsh/
│   ├── .zshrc                            # Shell config (oh-my-zsh, plugins, starship)
│   └── .config/
│       └── starship.toml                 # Prompt config
│
├── .stowrc                               # Stow target defaults to $HOME
├── .vscode/settings.json
├── .gitignore
└── README.md
```

## Prerequisites

- Arch Linux (or an Arch-based distro) with `pacman` and an AUR helper such as [`yay`](https://github.com/Jguer/yay).
- Git.

Install `git` and `stow` first if you don't already have them:

```bash
sudo pacman -S --needed git stow
```

## Installing the dependencies

### Core desktop (official repos)

```bash
sudo pacman -S --needed \
  hyprland hypridle hyprlock \
  waybar rofi dunst \
  fastfetch ghostty \
  stow zsh zsh-autosuggestions zsh-syntax-highlighting starship \
  brightnessctl playerctl wireplumber pavucontrol networkmanager \
  imagemagick ttf-jetbrains-mono-nerd otf-font-awesome \
  awww
```

| Package | Used for |
| --- | --- |
| `hyprland` | Wayland compositor (config in `hypr/`, written in Lua) |
| `hypridle` / `hyprlock` | Idle timeout handling and lock screen |
| `waybar` | Status bar |
| `rofi` | App launcher and the custom wallpaper picker |
| `dunst` | Notification daemon |
| `fastfetch` | Terminal system info banner |
| `ghostty` | Terminal emulator |
| `zsh` + `zsh-autosuggestions` + `zsh-syntax-highlighting` | Shell and plugins used in `.zshrc` |
| `starship` | Shell prompt |
| `brightnessctl` | Laptop brightness keybinds |
| `playerctl` | Media key bindings |
| `wireplumber` | Provides `wpctl`, used for volume keybinds |
| `pavucontrol` | Audio mixer (opened from the waybar pulseaudio module) |
| `networkmanager` | Provides `nmcli`, used by the network module |
| `imagemagick` | Provides `magick`, used to generate thumbnails in the wallpaper picker script |
| `ttf-jetbrains-mono-nerd` | Nerd Font used across waybar, rofi, ghostty |
| `otf-font-awesome` | Icon glyphs used by waybar |
| `awww` | Wallpaper daemon (autostarted in `hyprland.lua`, sets/transitions wallpapers) |

### AUR packages (install with `yay`)

```bash
yay -S --needed \
  wlogout waypaper hyprlauncher brave-bin
```

| Package | Used for |
| --- | --- |
| `wlogout` | Power menu (SUPER+Escape) |
| `waypaper` | GUI wallpaper picker (alternative to the rofi script) |
| `hyprlauncher` | App menu (SUPER+R) |
| `brave-bin` | Browser autostarted on login |

### oh-my-zsh (not a pacman/AUR package)

`.zshrc` expects oh-my-zsh to already be installed:

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

## Applying the dotfiles

Clone the repo and stow the packages you want:

```bash
git clone <this-repo-url> ~/Code/personal/dotfiles
cd ~/Code/personal/dotfiles
stow hypr waybar rofi dunst fastfetch ghostty waypaper wlogout zsh assets
```

`.stowrc` already points the stow target at `$HOME`, so no `-t` flag is needed. Re-run `stow -R <package>` after adding new files to a package (e.g. a new wallpaper) to refresh its symlinks.
