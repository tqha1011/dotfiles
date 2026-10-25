# Sinh tự động bởi theme-render.py — đừng sửa tay. .zshrc source file này trước khi nạp plugin
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg={{accent}}'
ZSH_HIGHLIGHT_STYLES[builtin]='fg={{accent}}'
ZSH_HIGHLIGHT_STYLES[alias]='fg={{accent}}'
ZSH_HIGHLIGHT_STYLES[function]='fg={{accent}}'
ZSH_HIGHLIGHT_STYLES[precommand]='fg={{accent2}},italic'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg={{accent2}}'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg={{red}}'
ZSH_HIGHLIGHT_STYLES[path]='fg={{cyan}},underline'
ZSH_HIGHLIGHT_STYLES[globbing]='fg={{orange}}'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg={{green}}'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg={{green}}'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg={{orange}}'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg={{orange}}'
ZSH_HIGHLIGHT_STYLES[comment]='fg={{muted}}'
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg={{muted}}'
_TP_COLOR='{{accent}}' # màu ❯ của transient prompt (.zshrc)
