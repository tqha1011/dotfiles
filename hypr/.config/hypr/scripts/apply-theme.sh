#!/usr/bin/env bash
# Theme cho app GTK/Qt + icon + con trỏ. Chạy lại bao nhiêu lần cũng được (autostart trong hyprland.lua).
# Không stow ~/.config/gtk-*/ hay kdeglobals: Plasma cũng ghi các file đó.

gtk_theme=Breeze-Dark
icons=Tela-dark
cursor=Bibata-Modern-Ice
cursor_size=24
kde_colors=TokyoNight # theme/.local/share/color-schemes/TokyoNight.colors

# GTK (Wayland đọc từ gsettings; libadwaita đọc color-scheme qua portal)
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"
gsettings set org.gnome.desktop.interface icon-theme "$icons"
gsettings set org.gnome.desktop.interface cursor-theme "$cursor"
gsettings set org.gnome.desktop.interface cursor-size "$cursor_size"

# GTK4 (pavucontrol…) đọc settings.ini chứ không theo gsettings; file do Plasma sinh nên chỉ sửa từng key.
# Màu TokyoNight của Breeze nằm trong colors.css cạnh đó (theme-render.py).
for v in 3.0 4.0; do
    ini="$HOME/.config/gtk-$v/settings.ini"
    kwriteconfig6 --file "$ini" --group Settings --key gtk-theme-name "$gtk_theme"
    kwriteconfig6 --file "$ini" --group Settings --key gtk-application-prefer-dark-theme true
    kwriteconfig6 --file "$ini" --group Settings --key gtk-icon-theme-name "$icons"
    kwriteconfig6 --file "$ini" --group Settings --key gtk-cursor-theme-name "$cursor"
    kwriteconfig6 --file "$ini" --group Settings --key gtk-cursor-theme-size "$cursor_size"
done

# Qt/KDE (QT_QPA_PLATFORMTHEME=kde trong hyprland.lua)
if command -v plasma-apply-colorscheme >/dev/null; then
    plasma-apply-colorscheme "$kde_colors" >/dev/null
else
    kwriteconfig6 --file kdeglobals --group General --key ColorScheme "$kde_colors"
fi
kwriteconfig6 --file kdeglobals --group Icons --key Theme "$icons"
kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme "$cursor"
kwriteconfig6 --file kcminputrc --group Mouse --key cursorSize "$cursor_size"

# Con trỏ Hyprland (cần bibata-cursor-theme-bin; nếu chưa cài Hyprland tự fallback)
hyprctl setcursor "$cursor" "$cursor_size" >/dev/null
