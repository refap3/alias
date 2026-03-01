# macOS/zsh equivalents of ALIAS.DAT
# Sourced automatically by .zshrc / .bashrc via DOTFILES glob

# Detect OS once at source time for use in tree functions
[ "$(/usr/bin/uname 2>/dev/null)" = "Darwin" ] && _ALIAS_OS=darwin || _ALIAS_OS=linux

# Navigation
alias up='cd ..'          # up = cd ..
alias hom='cd ~'         # home = cd \  (root on Windows = home on Mac)
alias home='cd ~'         # home = cd \  (root on Windows = home on Mac)

# Shell
alias lo='exit'           # lo = exit

# Open current directory in Finder (equivalent of: x = explorer /e, /root,%_cwd)
alias x='open .'

# Open file in TextEdit (equivalent of: np = notepad.exe)
alias np='open -e'

# Network info (equivalent of: ia = ipconfig /all)
alias ia='ifconfig'

# more ...
alias sdf='pwd'
alias mov='mv'
alias move='mv'
alias rd='rmdir'
alias md='mkdir'

# claude
alias cdsp='claude --dangerously-skip-permissions'

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
        local _mac _piip _path _qpath
        _mac=$(printf '%s' "$SSH_CLIENT" | awk '{print $1}')
        _piip=$(hostname -I 2>/dev/null | awk '{print $1}')
        _path=$(realpath "${1:-$PWD}" 2>/dev/null || echo "${1:-$PWD}")
        _qpath=$(printf '%q' "$_path")
        ssh -o BatchMode=yes -o ConnectTimeout=5 "$_mac" \
            "code --remote ssh-remote+pi@${_piip} ${_qpath}" 2>/dev/null \
            || echo "vsc: could not reach Mac at $_mac — enable System Settings > Sharing > Remote Login and add Pi's key to authorized_keys" >&2
    }
fi

# Clear screen
alias cls='clear'

# List all files in current directory created/modified today
dt() { find . -maxdepth 1 -newermt "$(date +%Y-%m-%d)" ! -name "." | sort; }

# Show alias/function definitions. No arg = show all. Arg = case-insensitive wildcard match.
aalias() {
    if [[ -z "$1" ]]; then
        alias
        typeset -f
    else
        alias | grep -i "$1"
        print -l ${(k)functions} | grep -i "$1" | while IFS= read -r fn; do
            typeset -f "$fn"
        done
    fi
}

# List only directories in current directory
alias dd='ls -d */'

# Display folder/file tree rooted at current (or given) directory, like Windows tree
# Pure shell — no external commands (no find, sort, basename, uname)
_tree_helper() {
    local dir="$1" prefix="$2"
    local entries=() entry i=0 count
    if [ -n "$ZSH_VERSION" ]; then
        eval 'for entry in "$dir"/*(N); do entries+=("$entry"); done'
    else
        local _ng; _ng=$(shopt -p nullglob 2>/dev/null)
        shopt -s nullglob 2>/dev/null
        for entry in "$dir"/*; do entries+=("$entry"); done
        eval "$_ng" 2>/dev/null
    fi
    count=${#entries[@]}
    for entry in "${entries[@]}"; do
        i=$((i+1))
        local name="${entry##*/}"
        if [ "$i" -eq "$count" ]; then
            echo "${prefix}└── $name"
            [ -d "$entry" ] && _tree_helper "$entry" "${prefix}    "
        else
            echo "${prefix}├── $name"
            [ -d "$entry" ] && _tree_helper "$entry" "${prefix}│   "
        fi
    done
}
tree() {
    local dir="${1:-.}"
    echo "$dir"
    _tree_helper "$dir" ""
}

# Like tree but directories only; -j/--jumplocations adds all dirs to ~/.jumplocations
_treed_in_jump() {
    local entry="$1" cache="$HOME/.jumplocations" line
    [ -f "$cache" ] || return 1
    while IFS= read -r line; do [ "$line" = "$entry" ] && return 0; done < "$cache"
    return 1
}
_treed_helper() {
    local dir="$1" prefix="$2" jump="${3:-0}"
    local entries=() entry i=0 count
    if [ -n "$ZSH_VERSION" ]; then
        eval 'for entry in "$dir"/*(N/); do entries+=("$entry"); done'
    else
        local _ng; _ng=$(shopt -p nullglob 2>/dev/null)
        shopt -s nullglob 2>/dev/null
        for entry in "$dir"/*; do [ -d "$entry" ] && entries+=("$entry"); done
        eval "$_ng" 2>/dev/null
    fi
    count=${#entries[@]}
    for entry in "${entries[@]}"; do
        i=$((i+1))
        local name="${entry##*/}"
        [ "$jump" = "1" ] && { _treed_in_jump "$entry" || echo "$entry" >> "$HOME/.jumplocations"; }
        if [ "$i" -eq "$count" ]; then
            echo "${prefix}└── $name"
            _treed_helper "$entry" "${prefix}    " "$jump"
        else
            echo "${prefix}├── $name"
            _treed_helper "$entry" "${prefix}│   " "$jump"
        fi
    done
}
treed() {
    local dir="." jump=0
    for arg in "$@"; do
        case "$arg" in
            -j|--jumplocations) jump=1 ;;
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
    _treed_helper "$abs_dir" "" "$jump"
    [ "$jump" = "1" ] && echo "Directories added to ~/.jumplocations"
}

# Find file recursively from current directory (ff <partial name>)
ff()  { find . -not -path "*/.*" -iname "*$1*" 2>/dev/null; }   # skips hidden files/dirs
fff() { find . -iname "*$1*" 2>/dev/null; }                      # includes hidden (dot) files/dirs

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

# Count all files in current directory tree, grouped by extension
# Output: extension (left-aligned) + count (right-aligned), sorted by count desc
psfe() {
    find . -type f | awk -F/ '{n=$NF; d=index(n,"."); if(d>1){e=substr(n,d)}else{e="(none)"}; c[e]++} END{for(e in c) print c[e],e}' | sort -rn | awk '{printf "%-16s %5d\n", $2, $1}'
}

# Find empty directories; -d: delete leaves; -dr: delete recursively until none remain
psfed() {
    case "$1" in
        -dr)
            local result
            while result=$(find . -mindepth 1 -depth -type d -empty 2>/dev/null) && [ -n "$result" ]; do
                echo "$result"
                find . -mindepth 1 -depth -type d -empty -delete 2>/dev/null
            done
            ;;
        -d)
            find . -mindepth 1 -depth -type d -empty -delete 2>/dev/null
            ;;
        "")
            find . -mindepth 1 -type d -empty 2>/dev/null
            ;;
        *)
            echo "Usage: psfed [-d|-dr]" >&2
            echo "  (no args) -- list empty directories" >&2
            echo "  -d        -- delete empty leaf directories" >&2
            echo "  -dr       -- delete empty directories recursively until none remain" >&2
            return 1
            ;;
    esac
}
