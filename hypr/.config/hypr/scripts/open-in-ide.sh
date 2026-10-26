#!/usr/bin/env bash
# Mở thư mục hoặc file bằng IDE hợp với dự án: Gradle/Maven → IDEA, .NET → Rider, còn lại → VS Code.
#   open-in-ide.sh <đường dẫn> [dòng]
target=$(realpath -- "${1:-.}") || exit 1
line=$2

dir=$target
[ -f "$dir" ] && dir=$(dirname "$dir")
root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || echo "$dir")

has() { compgen -G "$root/$1" >/dev/null; }

if has pom.xml || has 'build.gradle*' || has 'settings.gradle*'; then
    ide=idea
elif has '*.sln' || has '*.csproj'; then
    ide=rider
else
    ide=code
fi

command -v "$ide" >/dev/null || { notify-send -a Dev "Chưa cài $ide" "Không mở được $target"; exit 1; }

case $ide in
    code)
        if [ -f "$target" ] && [ -n "$line" ]; then arg=(-g "$target:$line"); else arg=("$target"); fi ;;
    *)
        if [ -f "$target" ] && [ -n "$line" ]; then arg=(--line "$line" "$target"); else arg=("$target"); fi ;;
esac

setsid -f "$ide" "${arg[@]}" >/dev/null 2>&1
