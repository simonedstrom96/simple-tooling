#!/bin/bash

function wat() {
    SYSTEM_PROMPT="You exist in the users terminal as an assistant that answers general questions related to code and programming. Your answers need to be short, consise and to the point."

    PROMPT="$*"
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source $SCRIPT_DIR/call_llm.sh

    CONTENT="$(call_llm "$SYSTEM_PROMPT" "$PROMPT")"

    # Print the content to the terminal without executing it
    echo "$CONTENT"

}
