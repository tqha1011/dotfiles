#!/usr/bin/env bash
# Gỡ Plymouth tokyonight: trả kernel cmdline + dracut như trước khi chạy install.sh
set -euo pipefail

[ "$EUID" -eq 0 ] || { echo "Chạy bằng sudo: sudo $0" >&2; exit 1; }

cmdline=/etc/kernel/cmdline
if [ -e "$cmdline.bak-plymouth" ]; then
    mv "$cmdline.bak-plymouth" "$cmdline"
    echo "Đã khôi phục $cmdline"
fi
rm -f /etc/dracut.conf.d/plymouth.conf
rm -rf /usr/share/plymouth/themes/tokyonight

echo "Đang build lại initramfs (reinstall-kernels)…"
reinstall-kernels
echo "Xong."
