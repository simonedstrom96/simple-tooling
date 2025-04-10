#!/bin/bash

# Answers generic questions in the terminal
function wat() {
    SYSTEM_PROMPT="You exist in the users terminal as an assistant that answers general questions related to code and programming. Your answers need to be short, concise and to the point."

    # Start the input with a 1 to include the previous response for quick conversation-like behavior
    if [[ "$1" == "1" ]]; then
        SYSTEM_PROMPT+=" The previous conversation is included the users prompt, please produce the next AI response."
        PROMPT="Human: $PROMPT. \n\n AI: $CONTENT \n\n Human: ${*:2}". 
    else
        PROMPT="$*"
    fi
    
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source $SCRIPT_DIR/_call_llm.sh

    CONTENT="$(_call_llm "$SYSTEM_PROMPT" "$PROMPT")"

    echo "$CONTENT"

}
