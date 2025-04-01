#!/bin/zsh

# Get the directory of this script in zsh
SIMPLE_TOOLING_SCRIPT_DIR="$(cd "$(dirname "${(%):-%N}")" && pwd)"
export SIMPLE_TOOLING_SCRIPT_DIR="$SIMPLE_TOOLING_SCRIPT_DIR"

# Generic terminal helpers

source $SIMPLE_TOOLING_SCRIPT_DIR/wat.sh

source $SIMPLE_TOOLING_SCRIPT_DIR/doit.sh


# Git related commands

source $SIMPLE_TOOLING_SCRIPT_DIR/push.sh

source $SIMPLE_TOOLING_SCRIPT_DIR/diff.sh

source $SIMPLE_TOOLING_SCRIPT_DIR/git/ghbranch.sh
source $SIMPLE_TOOLING_SCRIPT_DIR/git/main.sh

# Generic fun stuff

source $SIMPLE_TOOLING_SCRIPT_DIR/halleluja.sh
