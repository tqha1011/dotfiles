#!/usr/bin/env bash
# Đặt wallpaper và ghi lại vào ~/.cache/current-wallpaper (hyprlock dùng làm nền)

[ -f "$1" ] || exit 1

awww img "$1" --transition-type wipe --transition-duration "${2:-1.5}"
ln -sf "$(realpath "$1")" "$HOME/.cache/current-wallpaper"
"$HOME/.config/hypr/scripts/theme-mode" refresh
