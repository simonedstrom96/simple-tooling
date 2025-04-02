#!/bin/zsh

# Exports variables from ../.env as local variables
function _dotenv() {
    # Load environment variables from ../.env file

    # Construct the full path to the .env file in the parent directory
    ENV_FILE="$SIMPLE_TOOLING_SCRIPT_DIR/../.env"

    # Check if the .env file exists
    if [ ! -f "$ENV_FILE" ]; then
        echo "Error: $ENV_FILE file not found!"
        exit 1
    fi

    # Export all variables from the .env file
    source "$ENV_FILE"
}

# Calls openai with a system prompt and a human message prompt using curl and python3
function _call_openai() {
    _dotenv

    local SYSTEM_PROMPT="$1"
    local USER_PROMPT="$2"

    if [[ -z "$OPENAI_API_KEY" || -z "$OPENAI_MODEL" ]]; then
        echo "Error: OPENAI_API_KEY is not set. Please set your API key."
        return 1
    fi

    if [[ -z "$SYSTEM_PROMPT" || -z "$USER_PROMPT" ]]; then
        echo "Error: System prompt and user prompt are required."
        return 1
    fi
    # Check if python3 is installed
    if ! command -v python3 &>/dev/null; then
        echo "Error: python3 is not installed. Please install python3 before running this script."
        return 1
    fi

    # Define the API endpoint
    API_URL="https://api.openai.com/v1/chat/completions"

    reasoning_effort_input=''
    if [[ -n "$OPENAI_REASONING_EFFORT" ]]; then
        reasoning_effort_input="\"reasoning_effort\":\"$OPENAI_REASONING_EFFORT\""
    fi

    # Define the request payload
    DATA=$(python3 -c "
import json, sys
data = {
    \"model\": \"$OPENAI_MODEL\",
    \"messages\": [
        {\"role\": \"system\", \"content\": sys.argv[1]},
        {\"role\": \"user\", \"content\": sys.argv[2]}
    ],
    $reasoning_effort_input
}
print(json.dumps(data))
" "$SYSTEM_PROMPT" "$USER_PROMPT")

    # Call the API using curl
    RESPONSE=$(curl -s -X POST "$API_URL" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "$DATA")

    # Extract the content using jq
    CONTENT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content')

    # Check if content is empty
    if [[ -z "$CONTENT" || "$CONTENT" == "null" ]]; then
        echo "Error: OpenAI API error"
        echo "Response:"
        echo "$RESPONSE"
        return 1
    fi
    echo "$CONTENT"
}

# Calls azure openai with a system prompt and a human message prompt using curl and python3
function _call_azure_openai() {
    _dotenv

    local SYSTEM_PROMPT="$1"
    local USER_PROMPT="$2"

    local AZURE_OPENAI_ENDPOINT="https://$AZURE_OPENAI_DOMAIN.openai.azure.com"

    # Check if required environment variables are set
    if [[ -z "$AZURE_OPENAI_ENDPOINT" || -z "$AZURE_OPENAI_API_KEY" || -z "$AZURE_OPENAI_DEPLOYMENT" || -z "$AZURE_API_VERSION" ]]; then
        echo "Please set the following environment variables before running the script:"
        echo "  AZURE_OPENAI_ENDPOINT"
        echo "  AZURE_OPENAI_API_KEY"
        echo "  AZURE_OPENAI_DEPLOYMENT"
        echo "  AZURE_API_VERSION"
        return 1
    fi
    # Check if python3 is installed
    if ! command -v python3 &>/dev/null; then
        echo "Error: python3 is not installed. Please install python3 before running this script."
        return 1
    fi

    if [[ -z "$SYSTEM_PROMPT" || -z "$USER_PROMPT" ]]; then
        echo "Error: System prompt and user prompt are required."
        return 1
    fi

    URL="$AZURE_OPENAI_ENDPOINT/openai/deployments/$AZURE_OPENAI_DEPLOYMENT/chat/completions?api-version=$AZURE_API_VERSION"

    # Construct the JSON payload using Python to ensure proper JSON formatting
    # reasoning_effort will set reasoning models such as o3-mini to low, medium or high. Will not impact non-reasoning models.
    DATA=$(python3 -c '
import json, sys
data = {
    "messages": [
        {"role": "system", "content": sys.argv[1]},
        {"role": "user", "content": sys.argv[2]}
    ]
}
print(json.dumps(data))
' "$SYSTEM_PROMPT" "$USER_PROMPT")

    # Make the API call
    RESPONSE=$(curl -sS -X POST "$URL" \
        -H "Content-Type: application/json" \
        -H "api-key: $AZURE_OPENAI_API_KEY" \
        -d "$DATA")

    # Check if the API call was successful
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to call Azure OpenAI API."
        return 1
    fi

    # Extract the content using jq
    CONTENT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content')

    # Check if content is empty
    if [[ -z "$CONTENT" || "$CONTENT" == "null" ]]; then
        echo "Error: No content received from Azure OpenAI API."
        echo "Response:"
        echo "$RESPONSE"
        return 1
    fi
    echo "$CONTENT"
}

# Routes between LLM providers depending on what env variables are set
function _call_llm() {
    _dotenv
    local SYSTEM_PROMPT="$1"
    local USER_PROMPT="$2"

    if [[ -n "$AZURE_OPENAI_API_KEY" ]]; then
        (_call_azure_openai "$SYSTEM_PROMPT" "$USER_PROMPT")
    else
        (_call_openai "$SYSTEM_PROMPT" "$USER_PROMPT")
    fi
}
