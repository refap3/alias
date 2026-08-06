export PATH="$HOME/.local/bin:$PATH"

# Resolve DOTFILES to the directory where this file actually lives,
# following the symlink if one exists. readlink is available on macOS
# without any extra tools; dirname handles the rest.
# Exported so scripts and subshells can find the dotfiles too.
_t=$(readlink "$HOME/.bashrc" 2>/dev/null)
export DOTFILES=$(dirname "${_t:-$HOME/.bashrc}")
unset _t

# Aliases — load all *alias*.zsh files
for _f in "$DOTFILES"/*alias*.zsh; do [ -f "$_f" ] && source "$_f"; done
unset _f

gital() {
    source $DOTFILES/gitalias.zsh
    echo "Git aliases loaded! List them with 'gal'."
}

# List the git aliases from gitalias.zsh.
# Named 'gal', not 'gh' — 'gh' belongs to the GitHub CLI.
gal() {
    grep '^alias' "$DOTFILES/gitalias.zsh" | sort
}

# Reload all aliases fresh
allal() {
    unalias -a
    source ~/.bashrc
    echo "All aliases reloaded."
}

# Unload git aliases and reload profile
sl() {
    source ~/.bashrc
    # Bash lacks unalias -m; parse gitalias.zsh and unalias each entry
    grep '^alias ' "$DOTFILES/gitalias.zsh" | sed 's/alias \([^=]*\)=.*/\1/' | while read -r name; do
        unalias "$name" 2>/dev/null
    done
    unset -f gs _git_default_branch 2>/dev/null
    echo ". sl executed! (Profile reloaded, Git aliases unloaded)"
}

source ~/.jump.sh
export MAC_USER=rainers
