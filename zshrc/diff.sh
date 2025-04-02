#!/bin/zsh

# Summarises all unstaged file changes, including new files
function diff(){

    SYSTEM_PROMPT="You exist in the users terminal to help summarise a git diff. The user has entered a git diff (unstaged files) and you are to provide a summary of this diff in order to aid the user in understanding what is going on. Your answer is concise and to the point."

    diff_content="$(git diff)"

    new_files_prompt="\n\n New files: ["
    new_files=$(git ls-files --others --exclude-standard)

    for file in $new_files; do
        if [ -f "$file" ]; then
            new_files_prompt+="File: $file\nContent:\n$(cat "$file")\n\n"
        fi
    done
    new_files_prompt+="]"

    USER_PROMPT="diff: [$diff_content]$new_files_prompt"

    source $SIMPLE_TOOLING_SCRIPT_DIR/_call_llm.sh
    CONTENT="$(_call_llm "$SYSTEM_PROMPT" "$USER_PROMPT")"

    echo "$CONTENT"
    
}
