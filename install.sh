#!/usr/bin/env bash
# One-line install:
#   curl -fsSL https://raw.githubusercontent.com/refap3/alias/master/install.sh | bash
set -euo pipefail

DEST="${ALIAS_DIR:-$HOME/alias}"

if [ -d "$DEST/.git" ]; then
    echo "Already installed at $DEST"
    echo "To update: git -C \"$DEST\" pull"
    exit 0
fi

echo "Cloning alias repo into $DEST ..."
git clone --depth 1 https://github.com/refap3/alias "$DEST"

echo "Running deploy.sh ..."
bash "$DEST/deploy.sh" --shell "$(basename "$SHELL")"
