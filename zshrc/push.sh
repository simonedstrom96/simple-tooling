#!/bin/zsh

# Stages all files at current location, comes up with a good commit message based on conventional commits, commits it, pushes

function push() {

    # Generates a commit message (optionally based on feedback)
    function _generate_commit_message(){
        feedback_message="$1"
        feedback_prompt=""
        if [[ -z "$rejected_commit_message" ]]; then
            feedback_prompt="Additionally, the user has given you the following instructions/feedback: $feedback_message"
        fi
        
        commit_types="feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert"

        SYSTEM_PROMPT="You exist in the users terminal as an assistant to create commit messages based on some file changes. Your output is to be the commit message AND NO OTHER TEXT. DO NOT include \`\`\`backticks\`\`\` or anything else, just the commit message. The commit message is to take the form of <type>:<content> where <type> is based on the conventional commit standard and <content> is the content of the commit message that summarises the changes made. You may choose from ONE of the following conventional commit types for the message: $commit_types. You may NOT use any other commit type. Only use the feat type if actual new functionality has been added, not if things have just be reordered or documentation added. The message content should be short but perfectly summarise all changes made. As an example if the commit only contains that the README.md file was created, your full output should be: 'docs: created README file'. The content given from the user below contains a list of files and their git diffs in the commit and you are to base your response on that. $feedback_prompt"

        USER_PROMPT="$(git diff --staged --name-only | xargs -I {} sh -c 'echo -e "\nFile: {}\n"; git diff --staged {}')"

        source $SIMPLE_TOOLING_SCRIPT_DIR/_call_llm.sh
        CONTENT="$(_call_llm "$SYSTEM_PROMPT" "$USER_PROMPT")"

        # Check if content starts with an accepted commit type
        valid_type=false
        IFS=',' read -rA types <<< "$commit_types"
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

            CONTENT="$(_call_llm "$SYSTEM_PROMPT_HEALING" "$CONTENT")"
        fi

        echo "$CONTENT"
    }

    # Recursively generates a commit message based on diffs and feedback
    function _recursive_push() {
        CONTENT="$(_generate_commit_message "$*")"

        echo "$CONTENT"

        while true; do
            echo -n "Above commit message ok? (press enter to accept, write message for feedback): "
            read -r input
            if [ "$input" = "" ]; then
                echo
                git commit -m "$CONTENT"
                git push
                return 0
            else
                echo # echo out a new line for better readability
                rejected_commit_prompt="You generated this commit message for me before and I did not approve it: $CONTENT."
                _recursive_push "$input. $rejected_commit_prompt"
                return $?
            fi
        done
    }

    ORIGINAL_SET=$(set +o)
    set -e

    git add .

    _recursive_push

    eval "$ORIGINAL_SET"
}
