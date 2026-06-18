# macOS/zsh equivalents of ALIAS.DAT
# Sourced automatically by .zshrc / .bashrc via DOTFILES glob

# Man pages for local repos: man alias / man mdedit / man deb / man macscp / man dockersource
export MANPATH="$HOME/alias/man:$HOME/mdedit/man:$HOME/deb/man:$HOME/macscp/man:$HOME/dockersource/man${MANPATH:+:$MANPATH}"

# Detect OS once at source time for use in tree functions
[ "$(/usr/bin/uname 2>/dev/null)" = "Darwin" ] && _ALIAS_OS=darwin || _ALIAS_OS=linux

# Navigation
# Go up one directory level
alias up='cd ..'          # up = cd ..
# Go to home directory (equivalent of: home = cd \ on Windows)
alias hom='cd ~'         # home = cd \  (root on Windows = home on Mac)
# Go to home directory (equivalent of: home = cd \ on Windows)
alias home='cd ~'         # home = cd \  (root on Windows = home on Mac)

# Shell
# Exit current shell
alias lo='exit'           # lo = exit

# Open current directory in Finder (equivalent of: x = explorer /e, /root,%_cwd)
alias x='open .'

# Open file in TextEdit (equivalent of: np = notepad.exe)
alias np='open -e'

# Network info (equivalent of: ia = ipconfig /all)
alias ia='ifconfig'

# more ...
# Show current directory path (pwd)
alias sdf='pwd'
# Move file or directory (equivalent of: mov/move on Windows)
alias mov='mv'
# Move file or directory (equivalent of: mov/move on Windows)
alias move='mv'
# Remove directory (equivalent of: rd on Windows)
alias rd='rmdir'
# Make directory (equivalent of: md on Windows)
alias md='mkdir'
# List files only (no directories), including hidden: name, date modified, human-readable size
# Optional arg: filter by name, case-insensitive. No *: exact match. With *: wildcard (quote if needed: d '*py').
# Unquoted wildcards that shell-expands to multiple files are handled automatically.
d() {
  if [[ $# -eq 0 ]]; then
    ls -lpAh | grep -v / | awk 'NR>1 {name=""; for(i=9;i<=NF;i++) name=name (i>9?" ":"") $i; printf "%-30s  %s %s %-7s  %s\n", name, $6, $7, $8, $5}'
  elif [[ $# -eq 1 && "$1" == *\** ]]; then
    local re
    re=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed 's/\./\\./g; s/\*/.*/g')
    ls -lpAh | grep -v / | awk -v pat="^${re}$" 'NR>1 {name=""; for(i=9;i<=NF;i++) name=name (i>9?" ":"") $i; if(tolower(name) ~ pat) printf "%-30s  %s %s %-7s  %s\n", name, $6, $7, $8, $5}'
  else
    local re="" arg esc
    for arg in "$@"; do
      esc=$(printf '%s' "$arg" | tr '[:upper:]' '[:lower:]' | sed 's/\./\\./g')
      [[ -n "$re" ]] && re="${re}|"
      re="${re}^${esc}$"
    done
    ls -lpAh | grep -v / | awk -v pat="$re" 'NR>1 {name=""; for(i=9;i<=NF;i++) name=name (i>9?" ":"") $i; if(tolower(name) ~ pat) printf "%-30s  %s %s %-7s  %s\n", name, $6, $7, $8, $5}'
  fi
}

# Run Claude CLI with --dangerously-skip-permissions (skips all permission prompts)
alias cdsp='claude --dangerously-skip-permissions'
alias cdspr='claude --dangerously-skip-permissions --resume'

# Session report for current project; --no-summaries skips AI descriptions; -d [N] limits to last N days (-d alone = today)
csess() {
    python3 ~/.dotfiles/tools/extract_sessions.py "$@" && \
        open "$(ls -t ~/.dotfiles/sessions/*.html | head -1)"
}
# Session report for all projects; --no-summaries skips AI descriptions; -d [N] limits to last N days (-d alone = today)
csessall() {
    python3 ~/.dotfiles/tools/extract_sessions.py --all "$@" && \
        open "$(ls -t ~/.dotfiles/sessions/*.html | head -1)"
}

# Docker Compose — use plugin (docker compose) when available, fall back to standalone (docker-compose)
_dc() {
    if [ -f /etc/synoinfo.conf ]; then
        sudo /volume1/@appstore/Docker/usr/bin/docker-compose "$@"
    elif docker compose version >/dev/null 2>&1; then
        docker compose "$@"
    else
        docker-compose "$@"
    fi
}
# Resolve the compose file inside a directory (prefers docker-compose.yml, falls back to compose.yml)
_dc_file() {
    local d="${1:-.}"
    if [ -f "$d/docker-compose.yml" ]; then echo "$d/docker-compose.yml"
    elif [ -f "$d/compose.yml" ]; then echo "$d/compose.yml"
    else echo "$d/docker-compose.yml"
    fi
}
# dcu [folder]  — docker compose up
dcu()  { _dc -f "$(_dc_file "${1:-.}")" up; }
# dcud [folder]  — docker compose up -d (detached)
dcud() { _dc -f "$(_dc_file "${1:-.}")" up -d; }
# dcd [folder]  — docker compose down
dcd()  { _dc -f "$(_dc_file "${1:-.}")" down; }
# dcde [folder]  — docker compose down and erase: all images, volumes, networks, orphans
dcde() {
    printf 'This will remove all containers, images, volumes and networks. Are you sure? [yes/N] '
    read _ans
    [ "$_ans" = "yes" ] || { echo "Aborted."; return 1; }
    _dc -f "$(_dc_file "${1:-.}")" down --rmi all --volumes --remove-orphans
}
# dcinfo [-v] [name]  — list containers (all or matching name wildcard)
#   without -v: one line per container: name, status, image, ports
#   with    -v: full docker inspect output for each matched container
dcinfo() {
    local _verbose=0 _name=""
    while [ $# -gt 0 ]; do
        case "$1" in
            -v) _verbose=1 ;;
            *)  _name="$1" ;;
        esac
        shift
    done
    local _filter=""
    [ -n "$_name" ] && _filter="--filter name=${_name}"
    if [ "$_verbose" = "1" ]; then
        docker ps -a $_filter --format '{{.Names}}' | while IFS= read -r _cname; do
            printf '=== %s ===\n' "$_cname"
            docker inspect "$_cname"
        done
    else
        docker ps -a $_filter --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}\t{{.Ports}}'
    fi
}
# dclog [name] [nn]  — show docker logs for containers matching name (all if omitted)
#   nn: number of lines to show (default 10; 0 = entire log)
#   if first arg is an integer, it is treated as nn and all containers are shown
dclog() {
    local _name="" _lines="10"
    if [ $# -ge 1 ]; then
        case "$1" in
            ''|*[!0-9]*) _name="$1"; _lines="${2:-10}" ;;  # non-integer: it's the name
            *)            _lines="$1" ;;                    # integer: it's the line count
        esac
    fi
    local _containers
    if [ -n "$_name" ]; then
        _containers=$(docker ps -a --filter "name=${_name}" --format '{{.Names}}')
        if [ -z "$_containers" ]; then
            printf "dclog: no containers matching '%s'\n" "$_name" >&2; return 1
        fi
    else
        _containers=$(docker ps -a --format '{{.Names}}')
    fi
    printf '%s\n' "$_containers" | while IFS= read -r _cname; do
        printf '=== %s ===\n' "$_cname"
        if [ "$_lines" = "0" ]; then
            docker logs "$_cname" 2>&1
        else
            docker logs --tail "$_lines" "$_cname" 2>&1
        fi
    done
}

# _dr_pick [0|1]  — list containers and prompt for selection; 0=running only, 1=all (default)
_dr_pick() {
    local _all="${1:-1}"
    local _names
    if [ "$_all" = "1" ]; then
        _names=$(docker ps -a --format '{{.Names}}\t{{.Status}}\t{{.Image}}')
    else
        _names=$(docker ps --format '{{.Names}}\t{{.Status}}\t{{.Image}}')
    fi
    [ -z "$_names" ] && { printf 'dr: no containers found\n' >&2; return 1; }
    printf '%s\n' "$_names" | awk '{printf "  %2d)  %s\n", NR, $0}' >&2
    printf 'Pick [1]: ' >&2
    read _sel
    _sel="${_sel:-1}"
    local _picked
    _picked=$(printf '%s\n' "$_names" | sed -n "${_sel}p" | cut -f1)
    [ -z "$_picked" ] && { printf 'dr: invalid selection\n' >&2; return 1; }
    printf '%s' "$_picked"
}
# dru  — docker start (attached): pick container to start in foreground
dru() {
    local _c
    _c=$(_dr_pick 1) || return 1
    docker start -a "$_c"
}
# drud  — docker start (detached): pick container to start in background
drud() {
    local _c
    _c=$(_dr_pick 1) || return 1
    docker start "$_c"
    printf 'Started: %s\n' "$_c"
}
# drd  — docker stop: pick running container to stop
drd() {
    local _c
    _c=$(_dr_pick 0) || return 1
    docker stop "$_c"
}
# drde  — docker stop + remove container, volumes, and image: pick container to erase
drde() {
    local _c _img _ans
    _c=$(_dr_pick 1) || return 1
    _img=$(docker inspect --format '{{.Config.Image}}' "$_c" 2>/dev/null)
    printf 'This will stop and remove container "%s" and its volumes. Are you sure? [yes/N] ' "$_c"
    read _ans
    [ "$_ans" = "yes" ] || { printf 'Aborted.\n'; return 1; }
    docker rm -f -v "$_c"
    if [ -n "$_img" ]; then
        printf 'Also remove image "%s"? [yes/N] ' "$_img"
        read _ans
        [ "$_ans" = "yes" ] && docker rmi "$_img"
    fi
}
# drinfo [-v] [name]  — list containers (all or matching name): same as dcinfo
drinfo() { dcinfo "$@"; }

# Open Visual Studio Code.
# Mac: simple wrapper for the 'code' CLI.
# Pi/Linux: SSH back to the connecting Mac and open VS Code with Remote SSH
#   pointing at this Pi. Requires Mac Remote Login enabled and Pi's key in
#   the Mac user's ~/.ssh/authorized_keys.
if [ "$_ALIAS_OS" = "darwin" ]; then
    alias vsc='code'
else
    vsc() {
        if [ -z "${SSH_CLIENT:-}" ]; then
            echo "vsc: not in an SSH session — use 'vscr <octet>' from your Mac" >&2; return 1
        fi
        local _mac _piip _path _qpath _mac_user
        _mac=$(printf '%s' "$SSH_CLIENT" | awk '{print $1}')
        _piip=$(hostname -I 2>/dev/null | awk '{print $1}')
        _path=$(realpath "${1:-$PWD}" 2>/dev/null || echo "${1:-$PWD}")
        _qpath=$(printf '%q' "$_path")
        # Mac username: use MAC_USER env var (set via raauth, or manually in ~/.bashrc)
        _mac_user="${MAC_USER:-}"
        local _target="${_mac_user:+${_mac_user}@}${_mac}"
        ssh -o BatchMode=yes -o ConnectTimeout=5 "$_target" \
            "PATH=\"\$PATH:/usr/local/bin:/opt/homebrew/bin\" code --remote ssh-remote+pi@${_piip} ${_qpath}" 2>/dev/null \
            || echo "vsc: could not reach Mac at $_target — ensure Remote Login is on and run 'raauth <octet>' from Mac to set MAC_USER on this Pi" >&2
    }
fi

# Clear screen
alias cls='clear'

# List all files/dirs in current directory created/modified today
# Optional arg: filter by name, case-insensitive. No *: exact match. With *: wildcard (quote if needed: dt '*.log').
# Unquoted wildcards that shell-expands to multiple names are handled automatically.
dt() {
  local today
  today="$(date +%Y-%m-%d)"
  if [[ $# -eq 0 ]]; then
    find . -maxdepth 1 -newermt "$today" ! -name "." | sort
  elif [[ $# -eq 1 ]]; then
    find . -maxdepth 1 -newermt "$today" ! -name "." -iname "$1" | sort
  else
    local find_args=( \( ) first=1 arg
    for arg in "$@"; do
      [[ $first -eq 0 ]] && find_args+=( -o )
      find_args+=( -iname "$arg" )
      first=0
    done
    find_args+=( \) )
    find . -maxdepth 1 -newermt "$today" ! -name "." "${find_args[@]}" | sort
  fi
}

# Show alias/function definitions. No arg = show all. Arg = case-insensitive wildcard match.
aalias() {
    if [[ -z "$1" ]]; then
        alias
        typeset -f
    else
        alias | grep -i "$1"
        { [ -n "$ZSH_VERSION" ] && print -l ${(k)functions} || declare -F | awk '{print $3}'; } \
            | grep -i "$1" | while IFS= read -r fn; do
            typeset -f "$fn"
        done
    fi
}

# List only directories in current directory, including hidden
# Optional arg: filter by name, case-insensitive. No *: exact match. With *: wildcard (quote if needed: dd 'ma*').
# Unquoted wildcards that shell-expands to multiple dirs are handled automatically.
dd() {
  if [[ $# -eq 0 ]]; then
    find . -maxdepth 1 -mindepth 1 -type d | sed 's|^\./||' | sort
  elif [[ $# -eq 1 ]]; then
    find . -maxdepth 1 -mindepth 1 -type d -iname "$1" | sed 's|^\./||' | sort
  else
    local find_args=( \( ) first=1 arg
    for arg in "$@"; do
      [[ $first -eq 0 ]] && find_args+=( -o )
      find_args+=( -iname "$arg" )
      first=0
    done
    find_args+=( \) )
    find . -maxdepth 1 -mindepth 1 -type d "${find_args[@]}" | sed 's|^\./||' | sort
  fi
}

# Display folder/file tree rooted at current (or given) directory, like Windows tree
# Pure shell — no external commands (no find, sort, basename, uname)
# Return file size in bytes (cross-platform)
_tree_filesize() {
    if [ "$_ALIAS_OS" = "darwin" ]; then
        stat -f%z "$1" 2>/dev/null || echo 0
    else
        stat -c%s "$1" 2>/dev/null || echo 0
    fi
}
# Format bytes as human-readable string (e.g. 4.2M)
_tree_humansize() {
    local b="$1"
    if [ "$b" -ge 1073741824 ]; then awk "BEGIN{printf \"%.1fG\", $b/1073741824}"
    elif [ "$b" -ge 1048576 ];   then awk "BEGIN{printf \"%.1fM\", $b/1048576}"
    elif [ "$b" -ge 1024 ];      then awk "BEGIN{printf \"%.1fK\", $b/1024}"
    else echo "${b}B"; fi
}
_tree_helper() {
    local dir="$1" prefix="$2" show_usage="${3:-0}" hidden="${4:-0}"
    local entries=() entry i=0 count
    if [ -n "$ZSH_VERSION" ]; then
        if [ "$hidden" = "1" ]; then
            eval 'for entry in "$dir"/*(ND); do entries+=("$entry"); done'
        else
            eval 'for entry in "$dir"/*(N); do entries+=("$entry"); done'
        fi
    else
        local _ng; _ng=$(shopt -p nullglob 2>/dev/null)
        shopt -s nullglob 2>/dev/null
        if [ "$hidden" = "1" ]; then
            local _dg; _dg=$(shopt -p dotglob 2>/dev/null)
            shopt -s dotglob 2>/dev/null
            for entry in "$dir"/*; do entries+=("$entry"); done
            eval "$_dg" 2>/dev/null
        else
            for entry in "$dir"/*; do entries+=("$entry"); done
        fi
        eval "$_ng" 2>/dev/null
    fi
    count=${#entries[@]}
    for entry in "${entries[@]}"; do
        i=$((i+1))
        local name="${entry##*/}"
        local size_tag=""
        if [ "$show_usage" = "1" ]; then
            if [ -d "$entry" ]; then
                local sz; sz=$(du -sk "$entry" 2>/dev/null | awk '{printf "%.0f\n", $1*1024}')
                size_tag="[$(_tree_humansize "${sz:-0}")] "
            else
                size_tag="[$(_tree_humansize "$(_tree_filesize "$entry")")] "
            fi
        fi
        if [ "$i" -eq "$count" ]; then
            echo "${prefix}└── ${size_tag}${name}"
            [ -d "$entry" ] && _tree_helper "$entry" "${prefix}    " "$show_usage" "$hidden"
        else
            echo "${prefix}├── ${size_tag}${name}"
            [ -d "$entry" ] && _tree_helper "$entry" "${prefix}│   " "$show_usage" "$hidden"
        fi
    done
}
# Display folder/file tree; -u sizes on each node; -h hidden files; -t top-level dirs with total recursive size; -z with -t sorts by size ascending (largest last)
tree() {
    local dir="." show_usage=0 hidden=0 show_totals=0 sort_size=0
    for arg in "$@"; do
        case "$arg" in
            -*) case "$arg" in *u*) show_usage=1 ;; esac
                case "$arg" in *h*) hidden=1 ;; esac
                case "$arg" in *t*) show_totals=1 ;; esac
                case "$arg" in *z*) sort_size=1 ;; esac ;;
            *)  dir="$arg" ;;
        esac
    done
    if [ "$show_totals" = "1" ]; then
        local entries=() entry i=0 count
        if [ -n "$ZSH_VERSION" ]; then
            if [ "$hidden" = "1" ]; then
                eval 'for entry in "$dir"/*(ND/); do entries+=("$entry"); done'
            else
                eval 'for entry in "$dir"/*(N/); do entries+=("$entry"); done'
            fi
        else
            local _ng; _ng=$(shopt -p nullglob 2>/dev/null)
            shopt -s nullglob 2>/dev/null
            if [ "$hidden" = "1" ]; then
                local _dg; _dg=$(shopt -p dotglob 2>/dev/null)
                shopt -s dotglob 2>/dev/null
                for entry in "$dir"/*/; do entries+=("${entry%/}"); done
                eval "$_dg" 2>/dev/null
            else
                for entry in "$dir"/*/; do entries+=("${entry%/}"); done
            fi
            eval "$_ng" 2>/dev/null
        fi
        local size_pairs=() _tname _tsz pair
        for entry in "${entries[@]}"; do
            _tsz=$(du -sk "$entry" 2>/dev/null | awk '{printf "%.0f\n", $1*1024}')
            size_pairs+=("${_tsz:-0}	${entry}")
        done
        if [ "$sort_size" = "1" ]; then
            local sorted=()
            while IFS= read -r pair; do sorted+=("$pair"); done \
                < <(printf '%s\n' "${size_pairs[@]}" | sort -t$'\t' -k1 -n)
            size_pairs=("${sorted[@]}")
        fi
        echo "$dir"
        count=${#size_pairs[@]}
        i=0
        for pair in "${size_pairs[@]}"; do
            i=$((i+1))
            _tsz="${pair%%	*}"
            _tname="${pair##*	}"
            _tname="${_tname##*/}"
            if [ "$i" -eq "$count" ]; then
                echo "└── [$(_tree_humansize "${_tsz:-0}")] ${_tname}"
            else
                echo "├── [$(_tree_humansize "${_tsz:-0}")] ${_tname}"
            fi
        done
        return
    fi
    if [ "$show_usage" = "1" ]; then
        local total; total=$(du -sk "$dir" 2>/dev/null | awk '{printf "%.0f\n", $1*1024}')
        echo "$dir  [$(_tree_humansize "${total:-0}")]"
    else
        echo "$dir"
    fi
    _tree_helper "$dir" "" "$show_usage" "$hidden"
}

# Like tree but directories only; -j/--jumplocations adds all dirs to ~/.jumplocations
_treed_in_jump() {
    local entry="$1" cache="$HOME/.jumplocations" line
    [ -f "$cache" ] || return 1
    while IFS= read -r line; do [ "$line" = "$entry" ] && return 0; done < "$cache"
    return 1
}
_treed_helper() {
    local dir="$1" prefix="$2" jump="${3:-0}" hidden="${4:-0}"
    local entries=() entry i=0 count
    if [ -n "$ZSH_VERSION" ]; then
        if [ "$hidden" = "1" ]; then
            eval 'for entry in "$dir"/*(ND/); do entries+=("$entry"); done'
        else
            eval 'for entry in "$dir"/*(N/); do entries+=("$entry"); done'
        fi
    else
        local _ng; _ng=$(shopt -p nullglob 2>/dev/null)
        shopt -s nullglob 2>/dev/null
        if [ "$hidden" = "1" ]; then
            local _dg; _dg=$(shopt -p dotglob 2>/dev/null)
            shopt -s dotglob 2>/dev/null
            for entry in "$dir"/*; do [ -d "$entry" ] && entries+=("$entry"); done
            eval "$_dg" 2>/dev/null
        else
            for entry in "$dir"/*; do [ -d "$entry" ] && entries+=("$entry"); done
        fi
        eval "$_ng" 2>/dev/null
    fi
    count=${#entries[@]}
    for entry in "${entries[@]}"; do
        i=$((i+1))
        local name="${entry##*/}"
        [ "$jump" = "1" ] && { _treed_in_jump "$entry" || echo "$entry" >> "$HOME/.jumplocations"; }
        if [ "$i" -eq "$count" ]; then
            echo "${prefix}└── $name"
            _treed_helper "$entry" "${prefix}    " "$jump" "$hidden"
        else
            echo "${prefix}├── $name"
            _treed_helper "$entry" "${prefix}│   " "$jump" "$hidden"
        fi
    done
}
treed() {
    local dir="." jump=0 hidden=0
    for arg in "$@"; do
        case "$arg" in
            --jumplocations) jump=1 ;;
            -*) case "$arg" in *j*) jump=1 ;; esac
                case "$arg" in *h*) hidden=1 ;; esac ;;
            *) dir="$arg" ;;
        esac
    done
    # Resolve to absolute path so jump entries are always absolute
    local abs_dir
    case "$dir" in
        /*) abs_dir="$dir" ;;
        .)  abs_dir="$PWD" ;;
        *)  abs_dir="$PWD/$dir" ;;
    esac
    [ "$jump" = "1" ] && { _treed_in_jump "$abs_dir" || echo "$abs_dir" >> "$HOME/.jumplocations"; }
    echo "$abs_dir"
    _treed_helper "$abs_dir" "" "$jump" "$hidden"
    [ "$jump" = "1" ] && echo "Directories added to ~/.jumplocations"
}

# Show free disk space on the filesystem containing the current directory
fr() { df -h "$PWD" | awk 'NR==2 {printf "Free: %s  Used: %s  Total: %s  (%s used)\n", $4, $3, $2, $5}'; }

# Find file recursively from current directory (ff <partial name> [dir])
ff()  { find "${2:-.}" -not -path "*/.*" -iname "*$1*" 2>/dev/null; }   # skips hidden files/dirs
fff() { find "${2:-.}" -iname "*$1*" 2>/dev/null; }                      # includes hidden (dot) files/dirs

# Show fingerprints of all keys in ~/.ssh (private + public, to verify they match)
sshfp() {
    for pub in ~/.ssh/id_*.pub; do
        pri="${pub%.pub}"
        echo "--- $(basename $pri) ---"
        [[ -f "$pri" ]] && echo "  private: $(ssh-keygen -lf "$pri" 2>/dev/null | awk '{print $1, $2}')" || echo "  private: not found"
        echo "  public:  $(ssh-keygen -lf "$pub" | awk '{print $1, $2}')"
    done
}


# Open file/folder/URL in default app (equivalent of Windows start/ShellExecute)
alias w='open'
[ -n "$BASH_VERSION" ] && complete -o default -o filenames w

# System dashboard — run on Raspberry Pi after SSH'ing in
# Usage: cpu [-b|--brief]  (default)   compact one-screen summary
#        cpu [-v|--verbose]            full section-by-section view
cpu() {
    local _mode=brief
    case "${1:-}" in
        -v|--verbose) _mode=verbose ;;
        -b|--brief|'') _mode=brief ;;
        *) echo "Usage: cpu [-b|--brief] [-v|--verbose]" >&2; return 1 ;;
    esac

    local _model _cores _os _docker
    _model=$(grep -m1 "Model" /proc/cpuinfo 2>/dev/null | sed 's/.*: //' || \
             grep -m1 "model name" /proc/cpuinfo 2>/dev/null | sed 's/.*: //' || echo "(unknown)")
    _cores=$(nproc 2>/dev/null || grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo '?')
    _os=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || echo "(unknown)")
    _docker=$(docker --version 2>/dev/null | sed 's/Docker version \(.*\),.*/\1/' || echo "(not installed)")

    if [ "$_mode" = "brief" ]; then
        local _mem _swap _disk _since
        _mem=$(free -m 2>/dev/null | awk '/^Mem:/ {printf "%dM / %dM", $3, $2}')
        _swap=$(free -m 2>/dev/null | awk '/^Swap:/{printf "%dM / %dM", $3, $2}')
        _disk=$(df -h / 2>/dev/null | awk 'NR==2{printf "%s / %s (%s)", $3, $2, $5}')
        _since=$(uptime -s 2>/dev/null || who -b 2>/dev/null | awk '{print $3,$4}' || uptime)
        printf "CPU:    %s (%s cores)\n" "$_model" "$_cores"
        printf "OS:     %s\n" "$_os"
        printf "Mem:    %s   swap: %s\n" "$_mem" "$_swap"
        printf "Disk:   %s [/]\n" "$_disk"
        ip -brief addr 2>/dev/null | grep -v '^lo\|^veth\|^br-\|^docker' | \
            awk 'NR==1{printf "Net:    %s\n",$0} NR>1{printf "        %s\n",$0}' || \
            echo "Net:    (unavailable)"
        printf "Docker: %s\n" "$_docker"
        printf "Since:  %s\n" "$_since"
        echo "(use cpu -v for full details)"
    else
        echo "=== CPU ==="
        echo "$_model"
        echo "Cores: $_cores"
        echo ""
        echo "=== OS ==="
        echo "$_os"
        echo ""
        echo "=== Memory ==="
        free -h 2>/dev/null || echo "(free not available)"
        echo ""
        echo "=== Storage ==="
        df -h 2>/dev/null || echo "(df not available)"
        echo ""
        echo "=== Network ==="
        ip -brief addr 2>/dev/null || ip addr 2>/dev/null || echo "(ip not available)"
        echo ""
        echo "=== Docker ==="
        echo "$_docker"
        echo ""
        echo "=== Last Reboot ==="
        uptime -s 2>/dev/null || who -b 2>/dev/null || uptime
    fi
}

# Run htop; auto-install via apt-get on Linux if missing (never installs on macOS)
htop() {
    if ! command -v htop >/dev/null 2>&1; then
        if [ "$_ALIAS_OS" = "darwin" ]; then
            echo "htop is not installed. Install it manually (e.g. brew install htop)." >&2
            return 1
        else
            echo "htop not found -- installing via apt-get..." >&2
            sudo apt-get install -y -qq htop
        fi
    fi
    command htop "$@"
}

# Count all files in current directory tree, grouped by extension; optional start dir
# Output: extension (left-aligned) + count (right-aligned), sorted by count desc
psfe() {
    find "${1:-.}" -type f | awk -F/ '{n=$NF; d=index(n,"."); if(d>1){e=substr(n,d)}else{e="(none)"}; c[e]++} END{for(e in c) print c[e],e}' | sort -rn | awk '{printf "%-16s %5d\n", $2, $1}'
}

# Find empty directories; -d: delete leaves; -dr: delete recursively until none remain; optional start dir
psfed() {
    local dir="." flag=""
    for arg in "$@"; do
        case "$arg" in
            -d|-dr) flag="$arg" ;;
            *) dir="$arg" ;;
        esac
    done
    case "$flag" in
        -dr)
            local result
            while result=$(find "$dir" -mindepth 1 -depth -type d -empty 2>/dev/null) && [ -n "$result" ]; do
                echo "$result"
                find "$dir" -mindepth 1 -depth -type d -empty -delete 2>/dev/null
            done
            ;;
        -d)
            find "$dir" -mindepth 1 -depth -type d -empty -delete 2>/dev/null
            ;;
        "")
            find "$dir" -mindepth 1 -type d -empty 2>/dev/null
            ;;
        *)
            echo "Usage: psfed [-d|-dr] [dir]" >&2
            return 1
            ;;
    esac
}

# Pull latest alias repo (shallow, strips old history) and re-run deploy.sh
alu() {
    local dir="${DOTFILES:-$HOME/alias}"
    git -C "$dir" fetch --depth=1 origin master || return 1
    local _ahead
    if [ ! -f "$dir/.git/shallow" ]; then
        _ahead=$(git -C "$dir" log origin/master..HEAD --oneline 2>/dev/null)
        if [[ -n "$_ahead" ]]; then
            echo "alu: WARNING — these local commits will be lost:"
            echo "$_ahead" | sed 's/^/  /'
            printf "Continue? [y/N] "
            read -r _r
            [[ "${_r:0:1}" == [yY] ]] || { echo "Aborted."; return 1; }
        fi
    fi
    git -C "$dir" reset --hard origin/master &&
    git -C "$dir" gc --prune=all --quiet &&
    bash "$dir/deploy.sh"
}

# Show Mac-to-Mac alias reference
mch() {
    echo "Mac aliases  (user: rainers, key: ~/.ssh/id_rsa, host: <name>.local)"
    echo "  mcp <name>               — SSH              (e.g. mcp mm)"
    echo "  mcw <name>               — SFTP             (e.g. mcw mb)"
    echo "  mcc <name[,name]> <cmd>  — run command      (e.g. mcc mm,mb uptime)"
    echo "  mcv <name>               — Screen Sharing   (e.g. mcv mm)"
}

# Open Screen Sharing (VNC) to <name>.local (e.g. mcv mm)
mcv() { open "vnc://${1}.local"; }

# Connect via SSH to rainers@<name>.local using private key (e.g. mcp mm)
mcp() { ssh -i ~/.ssh/id_rsa "rainers@${1}.local"; }

# Connect via SFTP to rainers@<name>.local using private key (e.g. mcw mm)
mcw() { sftp -i ~/.ssh/id_rsa "rainers@${1}.local"; }

# Run a command on one or more Macs by .local name (comma-separated) (e.g. mcc mm ls -la)
mcc() {
    local _cmd; _cmd=$(printf 'shopt -s expand_aliases; %s' "${@:2}")
    case "$1" in
        *,*)
            local h
            for h in $(printf '%s' "$1" | tr ',' ' '); do
                printf '\n-- %s --\n' "$h"
                printf '%s\n' "$_cmd" | ssh -i ~/.ssh/id_rsa "rainers@${h}.local" bash -i 2>/dev/null
            done
            ;;
        *)
            printf '%s\n' "$_cmd" | ssh -i ~/.ssh/id_rsa "rainers@${1}.local" bash -i 2>/dev/null
            ;;
    esac
}

# Disk speed test (read/write benchmark on current directory)
alias dst='~/deb/disk_speed_test'

# Open deb interactive menu (~/deb/menu); optional choice arg (e.g. db b); skipped if not installed
db() { [ -x "$HOME/deb/menu" ] && "$HOME/deb/menu" "$@" || echo "db: ~/deb/menu not found or not executable" >&2; }

# Terminal ping monitor (pinginfoview); auto-detects site from local DNS
piv() {
    if [ ! -x "$HOME/deb/pinginfoview" ]; then
        echo "piv: deb repo not installed. Install with:" >&2
        echo "  bash <(curl -fsSL https://raw.githubusercontent.com/refap3/deb/master/install.sh)" >&2
        return 1
    fi
    if [ -n "$1" ]; then
        "$HOME/deb/pinginfoview" "$1"
    else
        # Query each site's nameserver directly — fallback chain: dig → nslookup → /dev/tcp
        _site_resolves() {
            local ns="$1" domain="$2"
            if command -v dig >/dev/null 2>&1; then
                dig "@$ns" "$domain" +short +time=1 +tries=1 2>/dev/null | grep -v '^;' | grep -q .
            elif command -v nslookup >/dev/null 2>&1; then
                nslookup "$domain" "$ns" 2>/dev/null | grep -q "^Name:"
            else
                (echo >/dev/tcp/"$ns"/53) 2>/dev/null
            fi
        }
        local hosts_file
        if _site_resolves 192.168.1.203 ssb8.local; then
            hosts_file="$HOME/deb/hosts-vienna.txt"
        elif _site_resolves 192.168.1.198 pi.hole; then
            hosts_file="$HOME/deb/hosts-aigen.txt"
        else
            hosts_file="$HOME/deb/hosts.txt"
        fi
        unset -f _site_resolves
        "$HOME/deb/pinginfoview" "$hosts_file"
    fi
}

# Interactive network troubleshooting menu (ipconfig/arp/dns/ping/bw)
alias nw='~/alias/nwtools'

# Pull latest deb repo (shallow, strips old history)
dbu() {
    local dir="${DEB_DIR:-$HOME/deb}"
    git -C "$dir" fetch --depth=1 origin master || return 1
    local _ahead
    # Skip check on shallow clones — grafted history causes false diverge
    if [ ! -f "$dir/.git/shallow" ]; then
        _ahead=$(git -C "$dir" log origin/master..HEAD --oneline 2>/dev/null)
        if [[ -n "$_ahead" ]]; then
            echo "dbu: WARNING — these local commits will be lost:"
            echo "$_ahead" | sed 's/^/  /'
            printf "Continue? [y/N] "
            read -r _r
            [[ "${_r:0:1}" == [yY] ]] || { echo "Aborted."; return 1; }
        fi
    fi
    git -C "$dir" reset --hard origin/master &&
    git -C "$dir" gc --prune=all --quiet
}

# Update all repos (alias, deb, dockersource, macscp, mdedit) and run install steps [-full|-shallow]
superup() {
    local _pass=0 _skip=0 _fail=0 _mode=""

    for _a in "$@"; do
        case "$_a" in
            -full)    _mode=full   ;;
            -shallow) _mode=shallow ;;
        esac
    done

    # Plain git-only update helper
    _sup() {
        local _n="$1" _d="$2" _cmd="$3"
        if [ ! -d "$_d/.git" ]; then
            printf '  %-14s skipped\n' "$_n"; _skip=$((_skip+1)); return 0
        fi
        printf '\n--- %s\n' "$_n"
        if eval "$_cmd"; then _pass=$((_pass+1))
        else printf '%s: FAILED\n' "$_n" >&2; _fail=$((_fail+1)); fi
    }

    # Python repo update: git pull, then pip only if requirements.txt changed
    # $3 = mode (full|shallow|"")
    _sup_py() {
        local _n="$1" _d="$2" _m="${3:-}"
        if [ ! -d "$_d/.git" ]; then
            printf '  %-14s skipped\n' "$_n"; _skip=$((_skip+1)); return 0
        fi
        printf '\n--- %s\n' "$_n"
        local _req="$_d/requirements.txt" _h0="" _h1="" _pulled=0
        [ -f "$_req" ] && _h0=$(cksum "$_req" 2>/dev/null)
        if [ "$_m" = full ]; then
            git -C "$_d" fetch --unshallow origin 2>/dev/null || true
            git -C "$_d" pull && _pulled=1
        elif [ "$_m" = shallow ]; then
            git -C "$_d" fetch --depth=1 origin \
                && git -C "$_d" reset --hard FETCH_HEAD && _pulled=1
        else
            git -C "$_d" pull && _pulled=1
        fi
        if [ "$_pulled" = 1 ]; then
            [ -f "$_req" ] && _h1=$(cksum "$_req" 2>/dev/null)
            if [ "$_h0" != "$_h1" ] || [ -z "$_h0" ]; then
                printf 'requirements changed -- updating pip deps\n'
                "$_d/.venv/bin/pip" install -q --upgrade pip
                "$_d/.venv/bin/pip" install -q -r "$_req"
            else
                printf 'requirements unchanged -- pip skipped\n'
            fi
            _pass=$((_pass+1))
        else
            printf '%s: FAILED\n' "$_n" >&2; _fail=$((_fail+1))
        fi
    }

    local _label=""
    [ -n "$_mode" ] && _label=" ($_mode)"
    printf 'superup%s -- updating installed repos ...\n' "$_label"

    local _al="${DOTFILES:-$HOME/alias}"
    local _db="${DEB_DIR:-$HOME/deb}"
    local _ds="$HOME/dockersource"
    local _ms="${MACSCP_DIR:-$HOME/macscp}"
    local _md="${MDEDIT_DIR:-$HOME/mdedit}"

    if [ "$_mode" = full ]; then
        _sup  alias        "$_al" "git -C '$_al' fetch --unshallow origin master 2>/dev/null || git -C '$_al' fetch origin master; git -C '$_al' reset --hard origin/master && bash '$_al/deploy.sh'"
        _sup  deb          "$_db" "git -C '$_db' fetch --unshallow origin master 2>/dev/null || git -C '$_db' fetch origin master; git -C '$_db' reset --hard origin/master"
        _sup  dockersource "$_ds" "{ git -C '$_ds' fetch --unshallow origin 2>/dev/null || true; } && git -C '$_ds' pull --ff-only"
    elif [ "$_mode" = shallow ]; then
        _sup  alias        "$_al" "git -C '$_al' fetch --depth=1 origin master && git -C '$_al' reset --hard origin/master && git -C '$_al' gc --prune=all --quiet && bash '$_al/deploy.sh'"
        _sup  deb          "$_db" "git -C '$_db' fetch --depth=1 origin master && git -C '$_db' reset --hard origin/master && git -C '$_db' gc --prune=all --quiet"
        _sup  dockersource "$_ds" "git -C '$_ds' fetch --depth=1 origin && git -C '$_ds' reset --hard FETCH_HEAD"
    else
        _sup  alias        "$_al" "git -C '$_al' fetch --depth=1 origin master && git -C '$_al' reset --hard origin/master && git -C '$_al' gc --prune=all --quiet && bash '$_al/deploy.sh'"
        _sup  deb          "$_db" "git -C '$_db' fetch --depth=1 origin master && git -C '$_db' reset --hard origin/master && git -C '$_db' gc --prune=all --quiet"
        _sup  dockersource "$_ds" "git -C '$_ds' pull --ff-only"
    fi
    _sup_py macscp "$_ms" "$_mode"
    _sup_py mdedit "$_md" "$_mode"

    unset -f _sup _sup_py 2>/dev/null || true
    printf '\nsuperup: updated %d  skipped %d  failed %d\n' "$_pass" "$_skip" "$_fail"
    [ "$_fail" -eq 0 ]
}

# Open man page for a local repo; partial match for repo and section. -l lists sections. e.g. manr de nw  manr dock -l
manr() {
    local _repos=(alias deb dockersource macscp mdedit)
    local _q="${1:-}" _sec="${2:-}" _match="" _r _n=0
    if [ -z "$_q" ]; then
        printf 'Usage: manr <repo> [section]\nRepos: %s\n' "${_repos[*]}" >&2; return 1
    fi
    for _r in "${_repos[@]}"; do
        case "$_r" in *"$_q"*) _match="$_r"; _n=$((_n+1)) ;; esac
    done
    if [ "$_n" -eq 0 ]; then
        printf 'manr: no repo matches "%s". Valid: %s\n' "$_q" "${_repos[*]}" >&2; return 1
    elif [ "$_n" -gt 1 ]; then
        printf 'manr: "%s" is ambiguous — be more specific\n' "$_q" >&2; return 1
    fi
    if [ "$_sec" = "-l" ]; then
        local _f="$HOME/$_match/man/man1/$_match.1"
        awk '/^\.SH / { print substr($0,5) } /^\.SS / { print "  " substr($0,5) }' "$_f"
        return 0
    fi
    if [ -n "$_sec" ]; then
        MANPAGER="less +/$(printf '%s' "$_sec" | tr '[:lower:]' '[:upper:]')" man "$_match"
    else
        man "$_match"
    fi
}

# Show one-line help for every alias and function (from source-file comments); optional filter string
alh() {
    local out
    out=$(awk '
        /^[ \t]*#/ {
            sub(/^[ \t]*#[ \t]?/, ""); last_comment = $0; next
        }
        /^alias [a-zA-Z]/ {
            name = $2; sub(/=.*/, "", name)
            if (name != "" && last_comment != "") print name "\t" last_comment
            last_comment = ""; next
        }
        /^[a-zA-Z][a-zA-Z0-9_]*[ \t]*\(\)/ {
            name = $1; sub(/[ \t]*\(\).*/, "", name)
            if (name != "" && last_comment != "") print name "\t" last_comment
            last_comment = ""; next
        }
        { last_comment = "" }
    ' "$DOTFILES"/*alias*.zsh "$DOTFILES"/jump.sh | sort | awk -F'\t' '{printf "%-20s %s\n", $1, $2}')
    if [ -n "${1:-}" ]; then
        echo "$out" | grep -i "$1"
    else
        echo "$out"
    fi
}

# Repeatedly run a command (or commands), clearing the screen between runs (ESC or Ctrl-C to stop)
# Optional first arg: wait time as <n>s (e.g. 5s); default 2s.
# Use + to separate multiple commands. Example: loop ls   loop 5s ls + pwd
loop() {
    local _wait=2
    case "${1:-}" in
        [0-9]*s) _wait="${1%s}"; shift ;;
    esac

    # Build command string; '+' acts as ';' separator so no shell quoting needed
    local _cmd="" _arg
    for _arg in "$@"; do
        case "$_arg" in
            "+") _cmd="${_cmd% }; " ;;
            *)   _cmd="${_cmd}${_arg} " ;;
        esac
    done
    _cmd="${_cmd% }"

    local _old_tty _key
    _old_tty=$(stty -g 2>/dev/null)
    stty cbreak -echo 2>/dev/null
    trap 'stty "$_old_tty" 2>/dev/null; trap - INT TERM; return' INT TERM

    while true; do
        clear
        eval "$_cmd"
        local _i=0
        while [ "$_i" -lt "$((_wait * 10))" ]; do
            _key=""
            if [ -n "$ZSH_VERSION" ]; then
                read -t 0.1 -k 1 _key 2>/dev/null || true
            else
                read -t 0.1 -n 1 _key 2>/dev/null || true
            fi
            [ "$_key" = $'\e' ] && { stty "$_old_tty" 2>/dev/null; trap - INT TERM; return; }
            _i=$((_i + 1))
        done
    done

    stty "$_old_tty" 2>/dev/null
    trap - INT TERM
}

# Like loop but keeps output — no clear screen between runs (ESC or Ctrl-C to stop)
# Same syntax as loop: loopk [<n>s] <cmd> [+ <cmd> ...]
loopk() {
    local _wait=2
    case "${1:-}" in
        [0-9]*s) _wait="${1%s}"; shift ;;
    esac

    local _cmd="" _arg
    for _arg in "$@"; do
        case "$_arg" in
            "+") _cmd="${_cmd% }; " ;;
            *)   _cmd="${_cmd}${_arg} " ;;
        esac
    done
    _cmd="${_cmd% }"

    local _old_tty _key
    _old_tty=$(stty -g 2>/dev/null)
    stty cbreak -echo 2>/dev/null
    trap 'stty "$_old_tty" 2>/dev/null; trap - INT TERM; return' INT TERM

    while true; do
        eval "$_cmd"
        local _i=0
        while [ "$_i" -lt "$((_wait * 10))" ]; do
            _key=""
            if [ -n "$ZSH_VERSION" ]; then
                read -t 0.1 -k 1 _key 2>/dev/null || true
            else
                read -t 0.1 -n 1 _key 2>/dev/null || true
            fi
            [ "$_key" = $'\e' ] && { stty "$_old_tty" 2>/dev/null; trap - INT TERM; return; }
            _i=$((_i + 1))
        done
    done

    stty "$_old_tty" 2>/dev/null
    trap - INT TERM
}
