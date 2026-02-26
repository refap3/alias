export PATH="$HOME/.local/bin:$PATH"

DOTFILES="${${:-$HOME/.zshrc}:A:h}"

# Aliases — load all *alias*.zsh files
for _f in "$DOTFILES"/*alias*.zsh; do [[ -f "$_f" ]] && source "$_f"; done
unset _f

# Delayed Git Alias Loader
function gital() {
    source $DOTFILES/gitalias.zsh
    echo "Git aliases loaded! (Use 'gh' for help if you have a helper function, or just use the aliases)"
}

# Optional: Helper function to list these specific aliases (similar to your 'gh')
function gh() {
    cat $DOTFILES/gitalias.zsh | grep '^alias' | sort
}
# Reload all aliases fresh
function allal() {
    unalias -a
    for _f in "$DOTFILES"/*alias*.zsh; do source "$_f"; done
    unset _f
    echo "All aliases reloaded."
}

# Cleanup Function (Equivalent to your PowerShell 'sl')
function sl() {
    # 1. Reload profile (this re-sources gitalias.zsh via the *alias*.zsh glob)
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
