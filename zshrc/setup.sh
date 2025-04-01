#!/bin/bash

# Find path to the current script
SIMPLE_TOOLING_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Add the alias to .zshrc
echo "Adding tools to shell - $HOME/.zshrc"
echo "" >> "$HOME/.zshrc"
echo "# CLI with AI - Added by simple-tooling" >> "$HOME/.zshrc"
echo "source '$SIMPLE_TOOLING_SCRIPT_DIR/index.sh'" >> "$HOME/.zshrc"

echo "Reloading shell"
source "$HOME/.zshrc"
