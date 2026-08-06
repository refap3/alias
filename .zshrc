unsetopt SHARE_HISTORY
unsetopt INC_APPEND_HISTORY
setopt APPEND_HISTORY

export PATH="$HOME/.local/bin:$PATH"
# Secrets live outside the repo in ~/.secrets (mode 600, untracked).
[ -f "$HOME/.secrets" ] && source "$HOME/.secrets"

# Exported so scripts and subshells can find the dotfiles too.
export DOTFILES="${${:-$HOME/.zshrc}:A:h}"

# Aliases — load all *alias*.zsh files
for _f in "$DOTFILES"/*alias*.zsh; do [[ -f "$_f" ]] && source "$_f"; done
unset _f

# Delayed Git Alias Loader
function gital() {
    source $DOTFILES/gitalias.zsh
    echo "Git aliases loaded! List them with 'gal'."
}

# List the git aliases from gitalias.zsh.
# Named 'gal', not 'gh' — 'gh' belongs to the GitHub CLI.
function gal() {
    grep '^alias' "$DOTFILES/gitalias.zsh" | sort
}
# Reload all aliases fresh
function allal() {
    unalias -a
    source ~/.zshrc
    echo "All aliases reloaded."
}

# Cleanup Function (Equivalent to your PowerShell 'sl')
function sl() {
    # 1. Reload profile (reloads all aliases including gitalias.zsh)
    source ~/.zshrc

    # 2. AGGRESSIVE CLEANUP (must happen AFTER source, not before)
    unalias -m 'g[a-z]'
    unalias -m 'g[a-z][a-z]'
    unalias -m 'g[a-z][a-z][a-z]'

    # 3. Unfunction specific git functions (like gs)
    unfunction gs 2>/dev/null

    echo ". sl executed! (Profile reloaded, Git aliases unloaded)"
}

source ~/.jump.sh

export EDITOR="code --wait"

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

