#!/bin/bash

# Stages all files at current location, comes up with a good commit message based on conventional commits, commits it, pushes
function push() {
    git add .

    commit_types="feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert"

    SYSTEM_PROMPT="You exist in the users terminal as an assistant to create commit messages based on some file changes. Your output is to be the commit message AND NO OTHER TEXT. DO NOT include \`\`\`backticks\`\`\` or anything else, just the commit message. The commit message is to take the form of <type>:<content> where <type> is based on the conventional commit standard and <content> is the content of the commit message that summarises the changes made. You may choose from ONE of the following conventional commit types for the message: $commit_types. You may NOT use any other commit type. As an example if the commit only contains that the README.md file was created your full output should be: 'docs: created README file'. The content given from the user below contains a list of files and their git diffs in the commit and you are to base your response on that."

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source $SCRIPT_DIR/call_llm.sh

    PROMPT="$(git diff --staged --name-only | xargs -I {} sh -c 'echo -e "\nFile: {}\n"; git diff --staged {}')"

    CONTENT="$(call_llm "$SYSTEM_PROMPT" "$PROMPT")"

    # Check if content starts with an accepted commit type
    valid_type=false
    IFS=',' read -ra types <<< "$commit_types"
    for type in "${types[@]}"; do
        type=$(echo "$type" | tr -d ' ')
        if [[ "$CONTENT" == "$type:"* ]]; then
            valid_type=true
            break
        fi
    done

    if [ "$valid_type" = false ]; then
        echo "Error: Commit message must start with one of these types: $commit_types"
        
        SYSTEM_PROMPT_HEALING="The following commit message is incorrectly formatted. The conventional commit type is incorrect, it MUST be exactly one of the following types: $commit_types. Rewrite the commit message so that it conforms to the form of <type>:<content> where <type> is one of the aforementioned types and <content> is the content of the commit message.  Do NOT encapsulate the script with \`\`\`backticks\`\`\` or anything else, just provide the commit message directly."

        CONTENT="$(call_llm "$SYSTEM_PROMPT_HEALING" "$CONTENT")"
    fi

    echo $CONTENT

    read -p "Above commit message ok? (press enter to accept): " input; if [ "$input" = "" ]; then
        git commit -m "$CONTENT"
        git push
        return 0
    else
        return 0
    fi

}