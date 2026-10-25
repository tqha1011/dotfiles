#!/usr/bin/env bash
# Terminal thả xuống (SUPER+`): ghostty nằm trong special workspace "term", bật/tắt bằng scratchpad.
# Lần đầu chưa có cửa sổ thì mở ghostty (rule trong hyprland.lua tự đưa nó vào special:term).
class="ghostty.dropdown"

if hyprctl clients -j | jq -e --arg c "$class" 'any(.[]; .class == $c)' >/dev/null; then
    hyprctl dispatch 'hl.dsp.workspace.toggle_special("term")'
else
    ghostty --class="$class" >/dev/null 2>&1 &
fi
