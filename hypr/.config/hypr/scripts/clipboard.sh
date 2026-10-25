#!/usr/bin/env bash
# Lịch sử clipboard qua cliphist + rofi (SUPER+SHIFT+V). Alt+Delete trong rofi: xóa mục đang chọn.
#   clipboard.sh        chọn và dán lại
#   clipboard.sh wipe   xóa toàn bộ lịch sử

theme="$HOME/.config/rofi/clipboard.rasi"

if [ "$1" = wipe ]; then
    cliphist wipe && notify-send -a Clipboard "Đã xóa lịch sử clipboard"
    exit 0
fi

pidof rofi >/dev/null && exit 0

while true; do
    choice=$(cliphist list | rofi -dmenu -i -p "󰅍" -display-columns 2 \
        -kb-custom-1 "Alt+Delete" -mesg "Enter: copy   ·   Alt+Delete: xóa mục" -theme "$theme")
    code=$?
    [ -z "$choice" ] && exit 0
    if [ "$code" -eq 10 ]; then
        cliphist delete <<<"$choice"   # xóa rồi mở lại danh sách
        continue
    fi
    cliphist decode <<<"$choice" | wl-copy
    exit 0
done
