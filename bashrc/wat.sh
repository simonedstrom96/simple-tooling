#!/bin/bash

function wat() {
    SYSTEM_PROMPT="You exist in the users terminal as an assistant that answers general questions related to code and programming. Your answers need to be short, concise and to the point."

    PROMPT="$*"
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source $SCRIPT_DIR/_call_llm.sh

    CONTENT="$(_call_llm "$SYSTEM_PROMPT" "$PROMPT")"

    echo "$CONTENT"

}
