#!/bin/bash

function doit() {
    SYSTEM_PROMPT="You exist in the users terminal as an assistant that creates a shell script line of code. The user will ask you for help in creating a shell command and you will respond with absolutely nothing but the shell command itself. This is so that the user can execute the script directly if they so choose. DO NOT RESPOND WITH ANY TEXT OTHER THAN THE SHELL COMMAND ITSELF. For example, if a user says 'script that prints hello world' you will respond with nothing but 'echo \"Hello, world!\"'. Do NOT encapsulate the script with \`\`\`backticks\`\`\` or anything else, just provide the script text and make sure everything is written on one single line."

    PROMPT="$*"

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source $SCRIPT_DIR/call_llm.sh

    CONTENT="$(call_llm "$SYSTEM_PROMPT" "$PROMPT")"

    inject() {
        (python3 -c "import fcntl; import termios; import sys
with open('/dev/stdout', 'w') as fd:
  for c in ' '.join(sys.argv[1:]): fcntl.ioctl(fd, termios.TIOCSTI, c)" "$@" &)
    }

    # Print the content to the terminal without executing it
    inject "$CONTENT"
}
