# Git, GitHub, cổng mạng, Docker, Postgres — nạp bởi ~/.zshrc (mọi *.zsh trong ~/.config/zsh)

# ── Git ─────────────────────────────────────────────────────────────────────
# fbr: chuyển nhánh bằng fzf (nhánh dùng gần nhất lên đầu, gồm cả nhánh remote chưa có local)
fbr() {
  git rev-parse --git-dir >/dev/null 2>&1 || { echo "không phải repo git"; return 1 }
  local pick; pick=$(git for-each-ref --sort=-committerdate \
      --format='%(refname:short)%09%(committerdate:relative)%09%(subject)' refs/heads refs/remotes \
    | awk -F'\t' '$1 !~ /\/HEAD$/ && $1 != "origin"' \
    | fzf --delimiter '\t' --header 'Chuyển nhánh' \
      --preview 'git log --oneline --graph --color=always -15 {1}') || return
  local name=${pick%%$'\t'*}
  git switch "${name#origin/}"
}

# flog: duyệt lịch sử commit (xem bằng delta); Enter in hash, Ctrl-Y chép hash
flog() {
  git log --color=always --format='%C(yellow)%h%C(reset) %C(green)%ar%C(reset) %s %C(blue)%an%C(reset)' "$@" \
    | fzf --ansi --no-sort --header 'Enter: lấy hash · Ctrl-Y: chép' \
      --preview 'git show --color=always {1} | delta' \
      --bind 'ctrl-y:execute-silent(echo -n {1} | wl-copy)' | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1}'
}

# ── GitHub ──────────────────────────────────────────────────────────────────
# ghpr: danh sách PR đang mở, Enter checkout, Ctrl-O mở trình duyệt
ghpr() {
  local n; n=$(gh pr list --limit 50 --json number,title,headRefName,author \
      -q '.[] | "#\(.number)\t\(.title)\t\(.headRefName)\t@\(.author.login)"' \
    | fzf --delimiter '\t' --header 'PR đang mở · Enter: checkout · Ctrl-O: web' \
      --preview 'gh pr view {1} | head -60' \
      --bind 'ctrl-o:execute-silent(gh pr view {1} --web)' | cut -f1 | tr -d '#') || return
  [[ -n $n ]] && gh pr checkout "$n"
}

# ghci: theo dõi lần chạy CI mới nhất của nhánh hiện tại
ghci() {
  local id; id=$(gh run list --branch "$(git branch --show-current)" --limit 1 --json databaseId -q '.[0].databaseId')
  [[ -n $id ]] && gh run watch "$id" --exit-status || echo "không có lần chạy CI nào cho nhánh này"
}

alias ghweb='gh browse'

# ── Cổng mạng ───────────────────────────────────────────────────────────────
# Cột: cổng, pid, tên tiến trình (chỉ thấy tiến trình của chính bạn)
_ports() {
  ss -H -tlnp 2>/dev/null | awk '{
    n = split($4, a, ":"); port = a[n]; pid = "-"; name = "-"
    if (match($0, /users:\(\("[^"]*",pid=[0-9]+/)) {
      s = substr($0, RSTART, RLENGTH); sub(/users:\(\("/, "", s)
      split(s, b, "\",pid="); name = b[1]; pid = b[2]
    }
    print port "\t" pid "\t" name }' | sort -nu
}

# ports: các cổng đang lắng nghe
ports() { { printf 'PORT\tPID\tPROCESS\n'; _ports } | column -t -s $'\t' }

# killport [cổng]: tắt tiến trình đang giữ cổng (không có đối số thì chọn bằng fzf)
killport() {
  local line
  if [[ -n $1 ]]; then
    line=$(_ports | awk -F'\t' -v p="$1" '$1 == p && $2 != "-"')
  else
    line=$(_ports | awk -F'\t' '$2 != "-"' | fzf --delimiter '\t' --header 'Chọn cổng để tắt')
  fi
  [[ -n $line ]] || { echo "không có tiến trình của bạn ở cổng ${1:-đã chọn}"; return 1 }
  local -a f=("${(@ps:\t:)line}")
  kill "${f[2]}" && echo "đã tắt ${f[3]} (pid ${f[2]}, cổng ${f[1]})"
}

# ── Docker ──────────────────────────────────────────────────────────────────
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f --tail 100'
alias dps="docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'"
command -v lazydocker >/dev/null && alias lzd='lazydocker'

# Chọn container bằng fzf; đối số "all" gồm cả container đã dừng
_docker_pick() {
  local flag=(); [[ $1 == all ]] && flag=(-a)
  docker ps "${flag[@]}" --format '{{.Names}}\t{{.Image}}\t{{.Status}}' \
    | fzf --delimiter '\t' --header 'Container' --select-1 --exit-0 | cut -f1
}

# dlogs: log của container (làm nổi bật bằng tailspin nếu có)
dlogs() {
  local c; c=$(_docker_pick all) && [[ -n $c ]] || return
  if command -v tspin >/dev/null; then docker logs -f --tail 200 "$c" 2>&1 | tspin; else docker logs -f --tail 200 "$c"; fi
}

# dsh: vào shell của container đang chạy
dsh() {
  local c; c=$(_docker_pick) && [[ -n $c ]] || return
  docker exec -it "$c" bash 2>/dev/null || docker exec -it "$c" sh
}

# ── Postgres trong Docker ───────────────────────────────────────────────────
# pgsh: chọn container Postgres đang chạy, lấy user/db/mật khẩu từ biến môi trường của nó rồi vào pgcli (hoặc psql)
pgsh() {
  local c; c=$(docker ps --format '{{.Names}}\t{{.Image}}' \
    | awk -F'\t' 'tolower($2) ~ /postgres|pgvector|timescale/ {print $1}' \
    | fzf --select-1 --exit-0 --header 'Container Postgres') || return
  local env user db pw port
  env=$(docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' "$c")
  user=$(sed -n 's/^POSTGRES_USER=//p' <<<"$env"); user=${user:-postgres}
  db=$(sed -n 's/^POSTGRES_DB=//p' <<<"$env");     db=${db:-$user}
  pw=$(sed -n 's/^POSTGRES_PASSWORD=//p' <<<"$env")
  port=$(docker port "$c" 5432/tcp 2>/dev/null | head -1 | sed 's/.*://')
  if command -v pgcli >/dev/null && [[ -n $port ]]; then
    PGPASSWORD=$pw pgcli -h localhost -p "$port" -U "$user" -d "$db"
  else
    docker exec -it "$c" psql -U "$user" -d "$db"
  fi
}

# ── HTTP ────────────────────────────────────────────────────────────────────
command -v xh >/dev/null && alias http='xh' && alias https='xh --https'
