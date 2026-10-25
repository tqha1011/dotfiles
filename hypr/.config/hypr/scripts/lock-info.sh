#!/usr/bin/env bash
# Nội dung cho các label của hyprlock: lock-info.sh {greeting|status|weather}

# shellcheck source=/dev/null
. "$HOME/.cache/theme/palette.sh" 2>/dev/null
muted=${THEME_MUTED:-#565f89}
red=${THEME_RED:-#f7768e}

greeting() {
    local hour name
    hour=$(date +%-H)
    name=$(getent passwd "$USER" | cut -d: -f5 | cut -d, -f1 | awk '{print $NF}')
    [ -n "$name" ] || name=$USER

    if [ "$hour" -ge 5 ] && [ "$hour" -lt 12 ]; then
        echo "Chào buổi sáng, $name"
    elif [ "$hour" -ge 12 ] && [ "$hour" -lt 18 ]; then
        echo "Chào buổi chiều, $name"
    else
        echo "Chào buổi tối, $name"
    fi
}

status() {
    local out="" bat cap state icon ssid
    local levels=(󰂎 󰁺 󰁻 󰁼 󰁽 󰁾 󰁿 󰂀 󰂁 󰂂 󰁹)

    for bat in /sys/class/power_supply/BAT*; do
        [ -r "$bat/capacity" ] || continue
        cap=$(<"$bat/capacity")
        state=$(<"$bat/status")
        if [ "$state" = "Charging" ]; then
            icon=󰂄
        else
            icon=${levels[$((cap / 10))]}
        fi
        if [ "$cap" -lt 20 ] && [ "$state" != "Charging" ]; then
            out="<span color='$red'>$icon $cap%</span>"
        else
            out="$icon $cap%"
        fi
        break
    done

    ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | sed -n 's/^yes://p' | head -n1)
    if [ -n "$ssid" ]; then
        out="$out    󰖩 $ssid"
    else
        out="$out    <span color='$muted'>󰖪 Offline</span>"
    fi

    echo "$out"
}

weather() {
    # Không có mạng hoặc wttr.in lỗi → in rỗng để label biến mất
    # %x = mã thời tiết dạng chữ, đổi sang icon Nerd Font cho đồng bộ (emoji màu của %c bị lệch tông)
    local w code temp icon
    w=$(curl -sf --max-time 5 'https://wttr.in/?format=%x+%t' 2>/dev/null) || exit 0
    case "$w" in
        *Unknown* | *html* | "") exit 0 ;;
    esac
    code=${w% *}
    temp=${w##* }
    case "$code" in
        o) icon=󰖙 ;;
        m) icon=󰖕 ;;
        mm | mmm) icon=󰖐 ;;
        =) icon=󰖑 ;;
        '/!/' | '!/' | '*!*') icon=󰙾 ;;
        '///') icon=󰖖 ;;
        '/' | '//' | '.') icon=󰖗 ;;
        '*' | '**' | '*/*' | x | x/) icon=󰖘 ;;
        *) icon=󰖐 ;;
    esac
    echo "$icon $temp"
}

case "$1" in
    greeting) greeting ;;
    status) status ;;
    weather) weather ;;
    *) echo "usage: $0 {greeting|status|weather}" >&2; exit 1 ;;
esac
