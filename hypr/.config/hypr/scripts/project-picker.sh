#!/usr/bin/env bash
# Chọn dự án trong ~/Code bằng rofi.
#   project-picker.sh        ghostty tại thư mục dự án, vào phiên zellij cùng tên với layout "dev" (SUPER+O)
#   project-picker.sh ide    mở bằng IDE phù hợp (SUPER+SHIFT+O)

theme="$HOME/.config/rofi/clipboard.rasi"
pidof rofi >/dev/null && exit 0

# Repo git (cả worktree) sâu tối đa 4 cấp dưới ~/Code
mapfile -t dirs < <(fd --hidden --max-depth 4 --glob '.git' "$HOME/Code" 2>/dev/null | sed -E 's#/\.git/?$##' | sort)
[ "${#dirs[@]}" -gt 0 ] || exit 0

idx=$(printf '%s\n' "${dirs[@]#"$HOME"/Code/}" | rofi -dmenu -i -format i -p "󰉋" \
    -mesg "Enter: ${1:+IDE}${1:-terminal + zellij}" -theme "$theme") || exit 0
dir=${dirs[$idx]}
name=$(basename "$dir")

if [ "$1" = ide ]; then
    exec "$HOME/.config/hypr/scripts/open-in-ide.sh" "$dir"
fi
exec ghostty --working-directory="$dir" --title="$name" \
    -e zellij attach -c "$name" options --default-layout dev
