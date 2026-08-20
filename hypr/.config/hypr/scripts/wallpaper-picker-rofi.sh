#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/.local/share/wallpapers"

chosen=$(for wall in "$WALLPAPER_DIR"/*.{jpg,jpeg,png,webp}; do
    [ -e "$wall" ] || continue
    name=$(basename "$wall")
    echo -en "${name}\0icon\x1f${wall}\n"
done | rofi -dmenu -show-icons -p "Wallpaper" -theme ~/.config/rofi/wallpaper.rasi)

[ -z "$chosen" ] && exit 0

chosen_path="$WALLPAPER_DIR/$chosen"
[ -f "$chosen_path" ] || exit 1

awww img "$chosen_path" --transition-type wipe --transition-duration 1.5