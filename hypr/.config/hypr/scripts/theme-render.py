#!/usr/bin/env python3
"""Render bảng màu dùng chung ra file màu của từng app.

    theme-render.py tokyonight          # bảng màu cố định trong ~/.config/theme/palettes.toml
    theme-render.py wallpaper <ảnh>     # token [matugen] lấy từ wallpaper qua `matugen image`

Template: ~/.config/theme/templates/*, placeholder {{token}} / {{token.hex}} (không có #).
Chỉ ghi file khi nội dung đổi. In ra danh sách file đã đổi (theme-mode dùng để biết cần reload gì).
"""

import hashlib
import json
import re
import shutil
import subprocess
import sys
import tomllib
from pathlib import Path

HOME = Path.home()
THEME = HOME / ".config/theme"
CACHE = HOME / ".cache/theme"

OUTPUTS = {
    "gtk-define.css": [HOME / ".config/waybar/colors.css", HOME / ".config/wlogout/colors.css"],
    "rofi.rasi": [HOME / ".config/rofi/shared/colors.rasi"],
    "dunst.conf": [HOME / ".config/dunst/dunstrc.d/50-colors.conf"],
    "hyprland.lua": [HOME / ".config/hypr/colors.lua"],
    "hyprlock.conf": [HOME / ".config/hypr/colors-hyprlock.conf"],
    "ghostty": [HOME / ".config/ghostty/colors"],
    "palette.sh": [CACHE / "palette.sh"],
    "starship.toml": [HOME / ".config/starship.toml"],
    "fzf": [CACHE / "fzf"],
    "zsh.zsh": [CACHE / "zsh.zsh"],
    "eza.yml": [HOME / ".config/eza/theme.yml"],
    "btop.theme": [HOME / ".config/btop/themes/palette.theme"],
    "lazygit.yml": [HOME / ".config/lazygit/config.yml"],
    "delta.gitconfig": [HOME / ".config/git/config"],
    "zellij.kdl": [HOME / ".config/zellij/themes/palette.kdl"],
    "atuin.toml": [HOME / ".config/atuin/themes/palette.toml"],
    "yazi.toml": [HOME / ".config/yazi/theme.toml"],
}

# Template chỉ render khi lệnh này đã cài (core.pager = delta mà thiếu delta thì `git diff` hỏng)
REQUIRES = {"delta.gitconfig": "delta"}

# Token nào lấy từ role Material nào ở chế độ wallpaper (khớp chú thích [matugen] trong palettes.toml)
MATUGEN_ROLES = {
    "bg": "surface",
    "bg_dark": "surface_container_lowest",
    "bg_alt": "surface_container_low",
    "surface": "surface_container_high",
    "border": "outline_variant",
    "fg": "on_surface",
    "fg_dim": "on_surface_variant",
    "muted": "outline",
    "accent": "primary",
    "accent2": "tertiary",
    "cyan": "secondary",
}

# Màu gốc của Breeze-Dark → token. Mọi màu trong gtk.css của Breeze được thay bằng token
# của màu gốc gần nhất (giữ alpha), nên không phụ thuộc phiên bản Breeze.
BREEZE_BASE = {
    "#fcfcfc": "fg", "#a1a9b1": "fg_dim",
    "#202326": "bg", "#1d2023": "bg", "#202428": "bg",
    "#141618": "bg_dark", "#121416": "bg_dark", "#272c31": "bg_dark",
    "#292c30": "surface", "#4c4e51": "border", "#535659": "border",
    "#3daee9": "accent", "#1d99f3": "accent", "#9b59b6": "accent2",
    "#da4453": "red", "#f67400": "orange", "#27ae60": "green",
}

# libadwaita (GTK4) đọc các tên này từ ~/.config/gtk-4.0/gtk.css → colors.css
ADWAITA = {
    "window_bg_color": "bg", "window_fg_color": "fg",
    "view_bg_color": "bg_dark", "view_fg_color": "fg",
    "headerbar_bg_color": "bg_dark", "headerbar_fg_color": "fg",
    "sidebar_bg_color": "bg_alt", "sidebar_fg_color": "fg",
    "card_bg_color": "bg_alt", "card_fg_color": "fg",
    "popover_bg_color": "surface", "popover_fg_color": "fg",
    "dialog_bg_color": "bg", "dialog_fg_color": "fg",
    "accent_bg_color": "accent", "accent_color": "accent", "accent_fg_color": "bg",
    "destructive_bg_color": "red", "destructive_color": "red",
    "success_color": "green", "warning_color": "yellow", "error_color": "red",
}


def rgb(hex_color):
    h = hex_color.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    """Pha màu a với b: t = phần của b (0 → a, 1 → b)."""
    return "#" + "".join(f"{round(x + (y - x) * t):02x}" for x, y in zip(rgb(a), rgb(b)))


def with_dim_tokens(palette):
    """Token <màu>_dim: màu pha 82% nền, dùng làm nền nhạt (diff đỏ/xanh của delta…)."""
    for token in ("red", "green", "yellow", "accent", "accent2", "cyan"):
        palette[f"{token}_dim"] = mix(palette[token], palette["bg"], 0.82)
    return palette


def load_palette(mode, wallpaper=None):
    palette = tomllib.loads((THEME / "palettes.toml").read_text())["tokyonight"]
    if mode == "tokyonight":
        return with_dim_tokens(palette)
    # --prefer: wallpaper nhiều màu thì lấy màu rực nhất làm accent (không hỏi tương tác)
    # --fallback-color: wallpaper gần như xám (chainsaw-man) thì nghiêng về xanh TokyoNight
    out = subprocess.run(
        ["matugen", "image", str(wallpaper), "--mode", "dark", "--json", "hex", "--dry-run",
         "--prefer", "saturation", "--fallback-color", palette["accent"]],
        capture_output=True, text=True, check=True,
    ).stdout
    colors = json.loads(out[out.index("{"):])["colors"]
    for token, role in MATUGEN_ROLES.items():
        # matugen 4: {"role": {"dark": {"color": "#…"}}}; matugen 3: {"role": {"dark": "#…"}};
        # matugen 2: {"dark": {"role": "#…"}}
        value = colors[role]["dark"] if role in colors else colors["dark"][role]
        palette[token] = value["color"] if isinstance(value, dict) else value
    return with_dim_tokens(palette)


def render(template, palette):
    def sub(m):
        token, _, variant = m.group(1).partition(".")
        value = palette[token]
        return value.lstrip("#") if variant == "hex" else value
    return re.sub(r"\{\{\s*([a-z_0-9.]+)\s*\}\}", sub, template)


def gtk_colors(palette, gtk_version):
    source = Path(f"/usr/share/themes/Breeze-Dark/gtk-{gtk_version}/gtk.css").read_text()
    bases = [(rgb(h), token) for h, token in BREEZE_BASE.items()]

    def nearest(r, g, b):
        return min(bases, key=lambda bt: sum((x - y) ** 2 for x, y in zip(bt[0], (r, g, b))))[1]

    lines = ["/* Sinh tự động bởi theme-render.py từ Breeze-Dark — đừng sửa tay */"]
    for name, value in re.findall(r"@define-color (\w+_breeze) ([^;]+);", source):
        if m := re.fullmatch(r"#([0-9a-fA-F]{6})", value.strip()):
            value = palette[nearest(*rgb(m.group(0)))]
        elif m := re.fullmatch(r"rgba\((\d+),\s*(\d+),\s*(\d+),\s*([\d.]+)\)", value.strip()):
            r, g, b = rgb(palette[nearest(*map(int, m.groups()[:3]))])
            value = f"rgba({r}, {g}, {b}, {m.group(4)})"
        lines.append(f"@define-color {name} {value};")
    lines += [f"@define-color {name} {palette[token]};" for name, token in ADWAITA.items()]
    return "\n".join(lines) + "\n"


def write(path, content, changed):
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and path.read_text() == content:
        return
    path.write_text(content)
    changed.append(str(path))


def wlogout_icons(palette, changed):
    """Icon menu nguồn: glyph Nerd Font tô bằng muted / fg / red (bản -hover sáng hơn)."""
    glyphs = {"lock": 0xF033E, "logout": 0xF0343, "suspend": 0xF04B2, "reboot": 0xF0709, "shutdown": 0xF0425}
    font = "/usr/share/fonts/TTF/JetBrainsMonoNerdFontPropo-Regular.ttf"
    out = HOME / ".config/wlogout/icons"
    stamp = out / ".palette"
    key = hashlib.sha1(f"{palette['muted']}{palette['fg']}{palette['red']}".encode()).hexdigest()
    if stamp.exists() and stamp.read_text() == key:
        return
    out.mkdir(parents=True, exist_ok=True)
    for name, cp in glyphs.items():
        hover = palette["red"] if name == "shutdown" else palette["fg"]
        for suffix, color in (("", palette["muted"]), ("-hover", hover)):
            subprocess.run(["magick", "-background", "none", "-fill", color, "-font", font,
                            "-pointsize", "200", f"label:{chr(cp)}", "-trim", "+repage",
                            "-gravity", "center", "-extent", "220x220", str(out / f"{name}{suffix}.png")],
                           check=True)
    stamp.write_text(key)
    changed.append(str(out))


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "tokyonight"
    palette = load_palette(mode, sys.argv[2] if len(sys.argv) > 2 else None)
    changed = []
    for name, targets in OUTPUTS.items():
        if name in REQUIRES and not shutil.which(REQUIRES[name]):
            continue
        content = render((THEME / "templates" / name).read_text(), palette)
        for target in targets:
            write(target, content, changed)
    for version in ("3.0", "4.0"):
        write(HOME / f".config/gtk-{version}/colors.css", gtk_colors(palette, version), changed)
    wlogout_icons(palette, changed)
    write(CACHE / "palette.json", json.dumps(palette, indent=2) + "\n", changed)
    print("\n".join(changed))


if __name__ == "__main__":
    main()
