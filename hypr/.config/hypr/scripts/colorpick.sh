#!/usr/bin/env bash
# Hút màu trên màn hình (SUPER+SHIFT+C): copy mã hex + thông báo có ô màu

color=$(hyprpicker -a -f hex) || exit 0
[ -n "$color" ] || exit 0

swatch="${XDG_RUNTIME_DIR:-/tmp}/colorpick.png"
magick -size 64x64 xc:none -fill "$color" -draw "roundrectangle 0,0 63,63 14,14" "$swatch"

notify-send -a "Color Picker" -i "$swatch" "$color" "Đã copy vào clipboard"
