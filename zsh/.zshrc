# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="" # prompt do starship vẽ (eval cuối file)

# fzf-tab phải đứng trước zsh-autosuggestions / zsh-syntax-highlighting (chúng bọc widget)
plugins=(git fzf-tab zsh-autosuggestions zsh-syntax-highlighting)

# Màu syntax-highlighting/autosuggest theo bảng màu chung (sinh bởi theme-mode); nạp trước plugin
[[ -r ~/.cache/theme/zsh.zsh ]] && source ~/.cache/theme/zsh.zsh

# fzf: key-binding (Ctrl-R / Ctrl-T / Alt-C) phải nạp trước oh-my-zsh để fzf-tab giữ được phím Tab.
# Màu và kiểu nằm trong ~/.cache/theme/fzf (sinh bởi theme-mode), fzf đọc lại ở mỗi lần chạy.
if command -v fzf >/dev/null; then
  export FZF_DEFAULT_OPTS_FILE="$HOME/.cache/theme/fzf"
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:200 {}'"
  export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons --color=always {}'"
  export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window=up:3:hidden:wrap"
  source <(fzf --zsh)
fi

source $ZSH/oh-my-zsh.sh
bindkey '^R' fzf-history-widget # oh-my-zsh key-bindings.zsh gắn lại Ctrl-R sau khi fzf đã gắn

# fzf-tab: Tab mở menu fzf, có preview thư mục khi cd
zstyle ':completion:*' menu no
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':fzf-tab:complete:(cd|z|zoxide):*' fzf-preview 'eza -1 --icons --color=always $realpath'
zstyle ':fzf-tab:*' switch-group '<' '>'

export PATH=$PATH:/home/ha/.local/share/JetBrains/Toolbox/scripts

# fnm
FNM_PATH="/home/ha/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  # --use-on-cd: vào thư mục có .nvmrc / .node-version / engines trong package.json thì tự đổi phiên bản Node
  eval "$(fnm env --use-on-cd --version-file-strategy=recursive --shell zsh)"
fi
export PATH="$HOME/.local/bin:$PATH"

# Công cụ CLI hiện đại (chỉ bật khi đã cài)
if command -v eza >/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -l --icons --git --group-directories-first'
  alias la='eza -la --icons --git --group-directories-first'
  alias lt='eza --tree --level=2 --icons'
fi
if command -v bat >/dev/null; then
  alias cat='bat --paging=never --style=plain'
  export BAT_THEME=ansi # theo bảng ANSI của Ghostty nên tự khớp màu
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  export MANROFFOPT=-c
fi
command -v zoxide >/dev/null && eval "$(zoxide init zsh --cmd cd)"
# direnv: nạp .envrc khi vào thư mục (phải `direnv allow` mới chạy); tắt log "loading/unloading" cho yên
if command -v direnv >/dev/null; then
  export DIRENV_LOG_FORMAT=
  eval "$(direnv hook zsh)"
fi
# atuin thay Ctrl-R bằng lịch sử có ngữ cảnh (thư mục, mã thoát, thời gian); giữ phím ↑ của zsh
command -v atuin >/dev/null && eval "$(atuin init zsh --disable-up-arrow)"

command -v lazygit >/dev/null && alias lg='lazygit'
command -v zellij >/dev/null && alias zj='zellij attach -c main'
# y: mở yazi, thoát thì cd về thư mục đang đứng trong yazi
if command -v yazi >/dev/null; then
  y() {
    local tmp="$(mktemp -t yazi-cwd.XXXXXX)" cwd
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [[ -n $cwd && $cwd != $PWD && -d $cwd ]] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
  }
fi

fastfetch

# starship terminal
eval "$(starship init zsh)"

# Transient prompt: khi nhấn Enter, khối prompt nhiều dòng thu lại thành "❯ lệnh" cho scrollback gọn.
# Starship đặt PROMPT một lần lúc init (nó tự chạy lại mỗi lần vẽ), nên lưu bản đầy đủ để khôi phục ở precmd.
_tp_full_prompt=$PROMPT
_tp_full_rprompt=$RPROMPT
_tp_precmd() { PROMPT=$_tp_full_prompt; RPROMPT=$_tp_full_rprompt }
_tp_line_finish() {
  # \e[1A\e[J: lên một dòng (dòng viên thuốc) rồi xoá từ đó xuống, để "❯ " thế chỗ cả hai dòng
  PROMPT=$'%{\e[1A\e[J%}'"%B%F{${_TP_COLOR:-blue}}❯%f%b "
  RPROMPT=''
  zle reset-prompt
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd _tp_precmd
zle -N zle-line-finish _tp_line_finish

# Hàm và alias cho công việc dev: ~/.config/zsh/*.zsh (nav: pj/zp/o/ff/rgf, dev: git/gh/docker/ports/pg, notify: báo lệnh dài).
# Nạp cuối cùng để notify.zsh đăng ký precmd sau starship (cần STARSHIP_CMD_STATUS).
for _f in ~/.config/zsh/*.zsh(N); do source "$_f"; done; unset _f
