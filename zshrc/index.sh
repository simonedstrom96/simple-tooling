#!/bin/zsh

# Get the directory of this script in zsh
SCRIPT_DIR="${0:a:h}"

# Generic terminal helpers

source $SCRIPT_DIR/wat.sh

source $SCRIPT_DIR/doit.sh


# Git related commands

source $SCRIPT_DIR/push.sh

source $SCRIPT_DIR/diff.sh

source $SCRIPT_DIR/git/ghbranch.sh
source $SCRIPT_DIR/git/main.sh

# Generic fun stuff

source $SCRIPT_DIR/celebrate.sh
