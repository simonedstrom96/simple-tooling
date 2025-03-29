#!/bin/zsh

# Creates a new branch with a draft mr for github
function ghbranch(){
    local branch_name=$*

    if [ -z "$branch_name" ]; then
        echo "Usage: ghbranch <branch-name>"
        return 1
    fi

    # Check if gh CLI is installed
    if ! command -v gh &> /dev/null; then
        echo "Error: GitHub CLI 'gh' not found. Please install it to create pull requests."
        read -p "GitHub CLI 'gh' is not installed. Do you want to install it now? (y/n): " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            echo "Installation aborted. Please install GitHub CLI manually to proceed."
            return 1
        fi
        (type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y)) \
	&& sudo mkdir -p -m 755 /etc/apt/keyrings \
        && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        && cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
	&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	&& sudo apt update \
	&& sudo apt install gh -y
        echo "See: https://cli.github.com/"
        return 1
    fi


    # Check if there are uncommitted changes (staged or unstaged)
    # git status --porcelain is faster for checking dirtiness
    if ! git status --porcelain | grep -qE '^[ AMDRCU]'; then
        echo "No changes detected to commit."
        return 0
    fi

    echo "Detected changes. Staging all changes..."
    # Stage everything first to get a consistent diff for the commit
    git add .
    if [ $? -ne 0 ]; then
        echo "Error: Failed to stage changes with 'git add .'."
        return 1
    fi

    # Get the diff of staged changes relative to HEAD
    local diff_output
    diff_output=$(git diff --cached HEAD)

    # Check if staging actually resulted in changes to be committed
    if [ -z "$diff_output" ]; then
        echo "No changes staged for commit after 'git add .'. Unstaging..."
        git reset > /dev/null # Unstage changes added by this script
        return 0 # Exit gracefully, maybe working dir had only untracked files that got ignored
    fi

    echo "Generating commit message via LLM..."
    # Generate commit message using the LLM script
    # Pass the diff as standard input to the script
    local commit_message
    # Provide a clear prompt for the LLM
    commit_types="feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert"

    SYSTEM_PROMPT="You exist in the users terminal as an assistant to create commit messages based on some file changes. Your output is to be the commit message AND NO OTHER TEXT. DO NOT include \`\`\`backticks\`\`\` or anything else, just the commit message. The commit message is to take the form of <type>:<content> where <type> is based on the conventional commit standard and <content> is the content of the commit message that summarises the changes made. You may choose from ONE of the following conventional commit types for the message: $commit_types. You may NOT use any other commit type. Only use the feat type if actual new functionality has been added, not if things have just be reordered or documentation added. The message content should be short but perfectly summarise all changes made. As an example if the commit only contains that the README.md file was created, your full output should be: 'docs: created README file'. The content given from the user below contains a list of files and their git diffs in the commit and you are to base your response on that. $feedback_prompt"

    SCRIPT_DIR="${0:a:h}"
    source $SCRIPT_DIR/../_call_llm.sh

    PROMPT="$(git diff --staged --name-only | xargs -I {} sh -c 'echo -e "\nFile: {}\n"; git diff --staged {}')"

    commit_message="$(_call_llm "$SYSTEM_PROMPT" "$PROMPT")"

    if [ -z "$commit_message" ]; then
        echo "Error: Failed to generate commit message using LLM, or LLM returned empty message."
        echo "Unstaging changes..."
        git reset > /dev/null # Unstage changes added by this script
        return 1
    fi

    # Trim leading/trailing whitespace from commit message
    commit_message=$(echo "$commit_message" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

    if [ -z "$commit_message" ]; then
        echo "Error: LLM returned an empty or whitespace-only commit message."
        echo "Unstaging changes..."
        git reset > /dev/null
        return 1
    fi

    echo "---------------------------"
    echo "Generated Commit Message:"
    echo "$commit_message"
    echo "---------------------------"


    echo "Creating and switching to branch '$branch_name'..."
    # Create the new branch and switch to it
    if ! git checkout -b "$branch_name"; then
        echo "Error: Failed to create or switch to branch '$branch_name'."
        echo "Maybe the branch already exists? Unstaging changes..."
        git reset > /dev/null # Unstage changes added by this script
        return 1
    fi

    # The changes are already staged from before the LLM call

    echo "Committing changes..."
    # Commit the changes with the generated message
    if ! git commit -m "$commit_message"; then
        echo "Error: Failed to commit changes."
        # Attempt to switch back to the previous branch? Difficult to know reliably.
        # User might need to fix the commit manually. The branch exists with staged changes.
        return 1
    fi

    echo "Pushing branch '$branch_name' to origin..."
    # Push the branch to the remote repository and set upstream
    if ! git push --set-upstream origin "$branch_name"; then
        echo "Error: Failed to push branch '$branch_name' to origin."
        # User might need to resolve push issues manually (e.g., auth, conflicts).
        # The commit is local, branch exists.
        # User might need to resolve push issues manually (e.g., auth, conflicts).
        # The commit is local, branch exists.
        return 1
    fi

    # Check GitHub authentication status before creating PR
    echo "Checking GitHub authentication status..."
    if ! gh auth status &> /dev/null; then
        echo "Error: Not logged into GitHub CLI ('gh')."
        echo "Please run 'gh auth login' to authenticate."
        # Don't return error here, as push succeeded. PR creation is skipped.
        echo "Skipping pull request creation."
        echo "---------------------------"
        echo "✅ Branch '$branch_name' created, committed, and pushed."
        echo "⚠️ Could not create PR - please log in with 'gh auth login' and create it manually."
        echo "---------------------------"
        return 0 # Return success as core work done, but indicate PR issue
    fi

    echo "Creating draft pull request..."
    # Create a draft pull request using GitHub CLI
    # Use the first line of the commit message as title, and the full message as body
    local pr_title
    pr_title=$(echo "$commit_message" | head -n 1)
    if ! gh pr create --draft --title "$pr_title" --body "$commit_message"; then
        echo "Warning: Failed to create draft pull request via 'gh pr create'."
        echo "The branch '$branch_name' was pushed successfully. You can create the PR manually."
        # Don't return error code here, as the core work (branch, commit, push) succeeded.
    else
        echo "Successfully created draft pull request."
    fi


    echo "---------------------------"
    echo "✅ Branch '$branch_name' created, committed, pushed, and draft PR initiated."
    echo "---------------------------"
    return 0
}

# Note: To use this function, source this file in your .zshrc:
# source /path/to/zshrc/git/ghbranch.sh
# Then you can run: ghbranch my-new-feature
