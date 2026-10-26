#!/usr/bin/env bash
# Cài theme SDDM tokyonight (cần root): sudo ./sddm/install.sh
# Thư mục sddm/ không phải stow package — theme phải nằm ở /usr/share/sddm/themes để user sddm đọc được.
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "Chạy bằng sudo: sudo $0" >&2
    exit 1
fi

src=$(dirname "$(realpath "$0")")/tokyonight
dest=/usr/share/sddm/themes/tokyonight
user=${SUDO_USER:-}

install -d "$dest"
cp -r "$src"/. "$dest"/
echo "Đã cài theme vào $dest"

install -d /etc/sddm.conf.d
# InputMethod rỗng: ghi đè 10-endeavouros.conf (qtvirtualkeyboard), bàn phím ảo che mất nút tắt máy/khởi động lại
cat >/etc/sddm.conf.d/20-tokyonight.conf <<'EOF'
[General]
InputMethod=

[Theme]
Current=tokyonight
CursorTheme=Bibata-Modern-Ice
CursorSize=24
EOF
echo "Đã ghi /etc/sddm.conf.d/20-tokyonight.conf"

# Ảnh đại diện: SDDM đọc từ AccountsService (không đọc được ~/.face trong home của user)
if [ -n "$user" ]; then
    face=$(getent passwd "$user" | cut -d: -f6)/.face
    if [ -e "$face" ]; then
        install -d /var/lib/AccountsService/icons
        install -m 644 "$(realpath "$face")" "/var/lib/AccountsService/icons/$user"
        echo "Đã chép ảnh đại diện $face"
    fi
fi

echo "Xong. Theme sẽ hiện ở lần đăng nhập tới."
