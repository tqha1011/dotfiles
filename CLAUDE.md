# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal Arch Linux dotfiles for a Hyprland (Wayland) desktop, managed with GNU Stow. Each top-level directory (`hypr`, `waybar`, `rofi`, `zsh`, `assets`, …) is a stow package whose contents mirror paths under `$HOME`. There is no build, lint, or test step. `README.md` lists the package dependencies (pacman + AUR) and the install steps.

## Applying and checking changes

```bash
stow <package>            # link a package into $HOME (.stowrc sets --target=/home/ha)
stow -R <package>         # restow after adding/removing files in a package
hyprctl reload            # re-read the Hyprland config
hyprctl configerrors      # show Hyprland config errors after an edit
killall -SIGUSR2 waybar   # reload waybar config/style
```

The packages are already stowed on this machine, and Stow folds whole directories: for example, `~/.config/hypr` and `~/.config/waybar` are symlinks to the directories in this repo. Edits here are therefore live right away. Only new top-level paths need a restow.

## Things that aren't obvious from a single file

- **The Hyprland config is Lua, not hyprlang.** `hypr/.config/hypr/hyprland.lua` uses the `hl.*` API (`hl.config`, `hl.bind`, `hl.on("hyprland.start", …)`, `hl.dsp.*`, `hl.window_rule`). The Lua type stubs live at `/usr/share/hypr/stubs` (`.vscode/settings.json` points to them). External dispatches use Lua expressions too, e.g. `hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })'` in `hypridle.conf`. Use this same syntax in waybar `on-click` commands too (e.g. `hyprctl dispatch 'hl.dsp.exit()'`). The lock screen is `hyprlock`; swaylock isn't installed.
- **Autostart lives in `hyprland.lua`.** Each daemon gets its own `hl.on("hyprland.start", …)` block: awww wallpaper daemon, blueman-applet, nm-applet, hyprpolkitagent, waybar (started after `fc-cache -f`), fcitx5, dunst, hypridle, cliphist watchers, hyprsunset, `apply-theme.sh`. The waybar block runs `theme-mode apply` first, so the generated color files exist before waybar reads them. Dunst has to start early because `org.kde.plasma.Notifications` is also registered on D-Bus and could otherwise take over notifications. Waybar reloads its own style (`reload_style_on_change`).
- **The wallpaper backend is `awww`** (the successor to swww). The current wallpaper is tracked by the symlink `~/.cache/current-wallpaper`, which hyprlock uses as its blurred background. Anything that sets a wallpaper must update that symlink, through `hypr/.config/hypr/scripts/set-wallpaper.sh <path> [duration]` or, for waypaper, its `post_command`. Three places use the wallpaper pool `assets/.local/share/wallpapers` (stowed to `~/.local/share/wallpapers`):
  - startup in `hyprland.lua`, which restores the last wallpaper from the symlink and falls back to chainsaw-man.jpg
  - `hypr/.config/hypr/scripts/wallpaper-picker-rofi.sh` (SUPER+W), which caches thumbnails made with ImageMagick in `~/.cache/wallpaper-thumbs` and shows them through `rofi/.config/rofi/wallpaper.rasi`
  - waypaper (the GUI picker)
- **Locking goes through hypridle.** SUPER+L and the waybar lock button run `loginctl lock-session`, and hypridle's `lock_cmd` (`pidof hyprlock || hyprlock`) does the actual locking, so there's never a second instance. The lock screen also locks before suspend. `hyprlock.conf` gets its widget text from `scripts/lock-info.sh {greeting|status|weather}`, and its avatar is `~/.face`. hyprlock's `#` starts a comment, so colors inside markup must be written `##rrggbb`. Testing a hyprlock change means really locking the session (the user has to type their password), so ask first.
- **waypaper rewrites its own `config.ini` at runtime**, for example the selected `wallpaper =`. That file also contains absolute paths into this repo, so a diff in it is often just app state and not a deliberate edit.
- **Colors come from one place: `theme/.config/theme/palettes.toml`** (TokyoNight tokens). `hypr/scripts/theme-render.py` renders `theme/.config/theme/templates/*` into each app's color file:
  - `waybar/colors.css` and `wlogout/colors.css` (`@import`ed by their `style.css`)
  - `rofi/shared/colors.rasi`
  - `dunst/dunstrc.d/50-colors.conf`
  - `hypr/colors.lua` (window borders, loaded with `dofile`, with a fallback)
  - `hypr/colors-hyprlock.conf` (`source`d by `hyprlock.conf`)
  - `ghostty/colors` and `~/.cache/theme/palette.sh`
  - `~/.config/gtk-{3,4}.0/colors.css`, built by mapping every Breeze-Dark color to its nearest token, plus libadwaita names
  - the wlogout icons

  All of these are generated and gitignored, so never edit them by hand: change a token or a template, then run `theme-mode apply`. `theme-mode wallpaper` swaps the `[matugen]` tokens for colors extracted from `~/.cache/current-wallpaper`, while status colors (red/yellow/green/orange) stay fixed. SDDM, Plymouth, starship and `TokyoNight.colors` (Qt) still use static TokyoNight values.
- Motion uses one tempo everywhere: Hyprland's `easeOutQuint` at speed 3 matches waybar's `cubic-bezier(0.23, 1, 0.32, 1)` 300ms transitions, and the Plymouth dots advance every 15 frames (≈300ms).
- **Waybar workspace dots:** buttons have an empty `format`, and `#workspaces button label { font-size: 1px }` keeps them 8px tall (the `*` rule would otherwise give the label a 13px line and force the bar to 44px). Check `waybar -l warning` for "minimum height" warnings after you change spacing.
- **Hardcoded user paths:** `.stowrc` targets `/home/ha`, and `waypaper/config.ini` and `.zshrc` contain `/home/ha/...` paths.
- **App theming is done by `hypr/.config/hypr/scripts/apply-theme.sh`, not by stowed files.** It runs at login and sets gsettings (Breeze-Dark, prefer-dark, Tela-dark, Bibata-Modern-Ice) plus `plasma-apply-colorscheme TokyoNight`, using `theme/.local/share/color-schemes/TokyoNight.colors`. `~/.config/gtk-*/` and `kdeglobals` are never stowed, because Plasma (also installed) rewrites them. Qt apps follow it through `QT_QPA_PLATFORMTHEME=kde` in `hyprland.lua`. GTK4 apps on Wayland ignore gsettings and `settings.ini` (they read the KDE portal), so `hyprland.lua` also sets `GTK_THEME=Breeze-Dark`. That theme is then tinted TokyoNight through the generated `colors.css`.
- **`plymouth/` is not a stow package either.** `sudo ./plymouth/install.sh` edits `/etc/kernel/cmdline` (backed up to `.bak-plymouth`) and the dracut config, then runs `reinstall-kernels`. Plymouth can't be previewed from inside a Wayland session.
- **`sddm/` is not a stow package.** The theme has to live in `/usr/share/sddm/themes`, so `sudo ./sddm/install.sh` installs it. To preview without logging out, run `sddm-greeter-qt6 --test-mode --theme sddm/tokyonight`. Its layout mirrors `hyprlock.conf`, so change both together.
- **wlogout 1.2 doesn't render markup or `\n` in layout `text`**, so its icons are PNGs in `wlogout/icons/`, rendered from Nerd Font glyphs with ImageMagick. The `-L`/`-R` margins in the SUPER+Escape bind are computed from the button width in `style.css`.
- Volume and brightness keys go through `scripts/osd.sh`, which shows a dunst popup with stack tag `osd`, so popups replace each other instead of piling up.
- Some comments in the configs are in Vietnamese.

## Conventions

Commit messages are short and lowercase, sometimes with a `feat:`/`fix:` prefix (e.g. `add auto start hyprpolkitagent`, `fix: reduce loading wallpaper time`). When you add a stow package or a new dependency, update the directory tree and the dependency tables in `README.md`.
