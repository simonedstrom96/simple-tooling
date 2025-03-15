#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Generic terminal helpers

source $SCRIPT_DIR/wat.sh

source $SCRIPT_DIR/doit.sh


# Git related commands

source $SCRIPT_DIR/push.sh

source $SCRIPT_DIR/diff.sh


# Generic fun stuff

source $SCRIPT_DIR/celebrate.sh