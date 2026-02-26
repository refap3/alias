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

# Clear screen
alias cls='clear'

# List all files in current directory created/modified today
dt() { find . -maxdepth 1 -newermt "$(date +%Y-%m-%d)" ! -name "." | sort; }

# Show alias/function definitions. No arg = show all. Arg = case-insensitive wildcard match.
aalias() {
    if [[ -z "$1" ]]; then
        alias
        declare -f
    else
        alias | grep -i "$1"
        declare -F 2>/dev/null | awk '{print $NF}' | grep -i "$1" | while IFS= read -r fn; do
            declare -f "$fn"
        done
    fi
}

# List only directories in current directory
alias ddd='ls -d */'

# Display folder/file tree rooted at current (or given) directory, like Windows tree
# Pure shell — no external commands (no find, sort, basename, uname)
_tree_helper() {
    local dir="$1" prefix="$2"
    local entries=() entry i=0 count
    if [ -n "$ZSH_VERSION" ]; then
        for entry in "$dir"/*(N); do entries+=("$entry"); done
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

# Like tree but directories only
_treed_helper() {
    local dir="$1" prefix="$2"
    local entries=() entry i=0 count
    if [ -n "$ZSH_VERSION" ]; then
        for entry in "$dir"/*(N/); do entries+=("$entry"); done
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
        if [ "$i" -eq "$count" ]; then
            echo "${prefix}└── $name"
            _treed_helper "$entry" "${prefix}    "
        else
            echo "${prefix}├── $name"
            _treed_helper "$entry" "${prefix}│   "
        fi
    done
}
treed() {
    local dir="${1:-.}"
    echo "$dir"
    _treed_helper "$dir" ""
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

