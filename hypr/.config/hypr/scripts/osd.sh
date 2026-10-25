#!/usr/bin/env bash
# Phím media + popup OSD qua dunst (cùng stack tag → thay tại chỗ, không chồng)
# osd.sh {volume-up|volume-down|volume-mute|mic-mute|brightness-up|brightness-down}

notify() { # notify <icon> <nhãn> <giá trị 0-100>
    notify-send -a OSD -u low -t 1200 \
        -h string:x-dunst-stack-tag:osd \
        -h int:value:"$3" \
        "$1  $2  $3%"
}

volume() { # volume <sink|source>
    local target out pct
    target=$([ "$1" = source ] && echo @DEFAULT_AUDIO_SOURCE@ || echo @DEFAULT_AUDIO_SINK@)
    out=$(wpctl get-volume "$target")  # "Volume: 0.45" hoặc "Volume: 0.45 [MUTED]"
    pct=$(awk '{printf "%d", $2 * 100 + 0.5}' <<<"$out")

    if [ "$1" = source ]; then
        if [[ $out == *MUTED* ]]; then notify 󰍭 "Mic tắt" 0; else notify 󰍬 "Mic" "$pct"; fi
    elif [[ $out == *MUTED* ]]; then
        notify 󰝟 "Tắt tiếng" 0
    elif [ "$pct" -lt 34 ]; then
        notify 󰕿 "Âm lượng" "$pct"
    elif [ "$pct" -lt 67 ]; then
        notify 󰖀 "Âm lượng" "$pct"
    else
        notify 󰕾 "Âm lượng" "$pct"
    fi
}

brightness() {
    local pct
    pct=$(brightnessctl -m | cut -d, -f4 | tr -d %)
    notify 󰃠 "Độ sáng" "$pct"
}

case "$1" in
    volume-up) wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+ && volume sink ;;
    volume-down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && volume sink ;;
    volume-mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && volume sink ;;
    mic-mute) wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle && volume source ;;
    brightness-up) brightnessctl -e4 -n2 set 5%+ >/dev/null && brightness ;;
    brightness-down) brightnessctl -e4 -n2 set 5%- >/dev/null && brightness ;;
    *) echo "usage: $0 {volume-up|volume-down|volume-mute|mic-mute|brightness-up|brightness-down}" >&2; exit 1 ;;
esac
