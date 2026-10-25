#!/usr/bin/env bash
# Cài màn hình boot Plymouth tokyonight (EndeavourOS: dracut + systemd-boot/kernel-install)
#   sudo ./plymouth/install.sh       cài
#   sudo ./plymouth/uninstall.sh     gỡ, trả lại như cũ
# Nếu boot bị đen: ở menu systemd-boot bấm `e`, xóa chữ "splash" để boot vào chế độ chữ như trước.
set -euo pipefail

[ "$EUID" -eq 0 ] || { echo "Chạy bằng sudo: sudo $0" >&2; exit 1; }
command -v plymouth-set-default-theme >/dev/null || { echo "Chưa cài plymouth: sudo pacman -S plymouth" >&2; exit 1; }

src=$(dirname "$(realpath "$0")")/tokyonight
cmdline=/etc/kernel/cmdline

install -d /usr/share/plymouth/themes/tokyonight
cp -r "$src"/. /usr/share/plymouth/themes/tokyonight/
echo "Đã cài theme vào /usr/share/plymouth/themes/tokyonight"

# Kernel cmdline: backup một lần, thêm quiet splash nếu chưa có
[ -e "$cmdline.bak-plymouth" ] || cp "$cmdline" "$cmdline.bak-plymouth"
args=$(tr -s ' \n' ' ' <"$cmdline" | sed 's/ *$//')
for a in quiet splash; do
    [[ " $args " == *" $a "* ]] || args="$args $a"
done
printf '%s\n' "$args" >"$cmdline"
echo "Kernel cmdline: $args"

echo 'add_dracutmodules+=" plymouth "' >/etc/dracut.conf.d/plymouth.conf
plymouth-set-default-theme tokyonight

echo "Đang build lại initramfs (reinstall-kernels)…"
reinstall-kernels
echo "Xong. Khởi động lại để xem màn hình boot mới."
