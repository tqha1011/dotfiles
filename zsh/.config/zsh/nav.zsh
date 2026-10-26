# Điều hướng dự án và tìm kiếm — nạp bởi ~/.zshrc (mọi *.zsh trong ~/.config/zsh)
_open_in_ide=~/.config/hypr/scripts/open-in-ide.sh

# Mọi repo git (cả worktree) sâu tối đa 4 cấp dưới ~/Code
_proj_roots() {
  fd --hidden --max-depth 4 --glob '.git' ~/Code 2>/dev/null | sed -E 's#/\.git/?$##' | sort
}

# Chọn dự án bằng fzf, in đường dẫn đầy đủ; một kết quả khớp thì chọn luôn
_proj_pick() {
  _proj_roots | sed "s#^$HOME/Code/##" | fzf --query "${*:-}" --select-1 --exit-0 \
    --header 'Dự án' --preview "git -C ~/Code/{} log --oneline --color=always -8 2>/dev/null; echo; eza -1 --icons --color=always ~/Code/{}" \
    | sed "s#^#$HOME/Code/#"
}

# pj [từ khoá]: nhảy vào dự án
pj() { local dir; dir=$(_proj_pick "$@") && [[ -n $dir ]] && cd "$dir" }

# zp [từ khoá]: nhảy vào dự án và vào phiên zellij cùng tên (layout dev: shell / run / git)
zp() {
  local dir; dir=$(_proj_pick "$@") && [[ -n $dir ]] || return
  cd "$dir" && zellij attach -c "${dir:t}" options --default-layout dev
}

# o [đường dẫn] [dòng]: mở bằng IDE hợp với dự án (Gradle/Maven → IDEA, .NET → Rider, còn lại → VS Code)
o() { "$_open_in_ide" "${1:-.}" "$2" }

# ff [từ khoá]: tìm file theo tên, xem trước bằng bat, Enter mở bằng IDE
ff() {
  local f; f=$(fd --type f --hidden --follow --exclude .git | fzf --query "${*:-}" \
    --preview 'bat --color=always --style=numbers --line-range=:200 {}') && [[ -n $f ]] && o "$f"
}

# rgf [từ khoá]: tìm nội dung bằng ripgrep, kết quả cập nhật theo từng phím, Enter mở đúng dòng bằng IDE
rgf() {
  local rg='rg --column --line-number --no-heading --color=always --smart-case'
  local sel; sel=$(fzf --ansi --disabled --query "${*:-}" \
    --bind "start:reload:$rg {q} || true" \
    --bind "change:reload:sleep 0.1; $rg {q} || true" \
    --delimiter : \
    --preview 'bat --color=always --highlight-line {2} {1}' \
    --preview-window 'up,60%,border-bottom,+{2}+3/3,~3') && [[ -n $sel ]] || return
  local -a p=("${(@s/:/)sel}")
  o "${p[1]}" "${p[2]}"
}
