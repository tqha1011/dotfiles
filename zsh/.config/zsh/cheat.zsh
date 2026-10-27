# Tra cứu nhanh lệnh docker / curl / jq...: nạp bởi ~/.zshrc (mọi *.zsh trong ~/.config/zsh)
# Dữ liệu nằm ở cheatsheet.txt cạnh file này (mỗi dòng: nhóm :: mô tả :: lệnh)
_cheat_file=${${(%):-%x}:A:h}/cheatsheet.txt

# cheat [từ khoá]: lọc cheatsheet bằng fzf, khung dưới hiện lệnh mẫu (chỉ để xem, không chèn gì vào prompt).
# Không có mục nào khớp thì rơi về trang tldr của lệnh đầu tiên.
cheat() {
  local q=$*
  local rows; rows=$(grep -vE '^\s*(#|$)' "$_cheat_file" | awk -F' :: ' '{ printf "%-8s\t%s\t%s\n", $1, $2, $3 }')

  if [[ -n $q ]] && ! print -r -- "$rows" | fzf --filter "$q" >/dev/null; then
    command -v tldr >/dev/null && tldr -c "${q%% *}" | less -RF
    return
  fi

  print -r -- "$rows" | fzf --query "$q" --delimiter $'\t' --with-nth 1,2 --nth 1,2,3 \
    --height 80% --tiebreak=index --header 'Ctrl-/ ẩn/hiện khung lệnh' \
    --preview "printf '# %s\n%s\n' {2} {3} | bat -l bash -p --color=always" \
    --preview-window 'down,35%,wrap,border-top' >/dev/null
}

# Ctrl-G: mở cheat với từ đầu tiên đang gõ trên dòng lệnh làm từ khoá (bỏ qua sudo), dòng lệnh giữ nguyên
_cheat_widget() {
  local w=${BUFFER#sudo }
  zle -I
  cheat "${w%% *}"
  zle reset-prompt
}
zle -N _cheat_widget
bindkey '^G' _cheat_widget
