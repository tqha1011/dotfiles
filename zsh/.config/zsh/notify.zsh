# Thông báo khi lệnh chạy lâu xong mà cửa sổ terminal không còn được focus — nạp bởi ~/.zshrc.
# Ngưỡng mặc định 30 giây (đặt LONG_CMD_SECONDS để đổi). Chỉ chạy trong phiên Hyprland.
[[ -n $HYPRLAND_INSTANCE_SIGNATURE ]] || return 0
zmodload zsh/datetime
autoload -Uz add-zsh-hook

# PID của ghostty chứa shell này (rỗng nếu shell nằm trong zellij vì server zellij tách khỏi ghostty)
_ln_find_term() {
  local p=$$ comm
  while (( p > 1 )); do
    read -r comm <"/proc/$p/comm" 2>/dev/null || return
    [[ $comm == ghostty ]] && { _ln_term_pid=$p; return }
    p=$(awk '{print $4}' "/proc/$p/stat" 2>/dev/null)
    [[ -n $p ]] || return
  done
}
_ln_term_pid=
_ln_find_term

_ln_preexec() { _ln_start=$EPOCHSECONDS; _ln_cmd=$1 }

_ln_precmd() {
  [[ -n $_ln_start ]] || return
  local dur=$(( EPOCHSECONDS - _ln_start )) rc=${STARSHIP_CMD_STATUS:-0} cmd=$_ln_cmd
  _ln_start=
  (( dur >= ${LONG_CMD_SECONDS:-30} )) || return
  # lệnh tương tác: kết thúc là do bạn tự thoát, không cần báo
  case ${cmd%% *} in
    vim|nvim|less|man|ssh|top|btop|yazi|y|lazygit|lg|lzd|zellij|zj|zp|atuin|fzf|code|idea|rider|webstorm|pgcli|pgsh|dsh|gh|ghci) return ;;
  esac
  local win; win=$(hyprctl activewindow -j 2>/dev/null) || return
  if [[ -n $_ln_term_pid ]]; then
    [[ $(jq -r '.pid' <<<"$win") == $_ln_term_pid ]] && return
  else
    [[ $(jq -r '.class' <<<"$win") == ghostty* ]] && return
  fi
  local t=$(printf '%dm %02ds' $(( dur / 60 )) $(( dur % 60 )))
  if (( rc == 0 )); then
    notify-send -a Terminal -h string:x-dunst-stack-tag:longcmd "✔ Xong sau $t" "$cmd"
  else
    notify-send -a Terminal -u critical -t 20000 -h string:x-dunst-stack-tag:longcmd "✘ Lỗi ($rc) sau $t" "$cmd"
  fi
}

add-zsh-hook preexec _ln_preexec
add-zsh-hook precmd _ln_precmd
