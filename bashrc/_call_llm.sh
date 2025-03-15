#!/bin/bash

# Exports variables from ../.env as local variables
function dotenv() {
    # Load environment variables from ../.env file
    # Get the directory where the script is located
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # Construct the full path to the .env file in the parent directory
    ENV_FILE="$SCRIPT_DIR/../.env"

    # Check if the .env file exists
    if [ ! -f "$ENV_FILE" ]; then
        echo "Error: $ENV_FILE file not found!"
        exit 1
    fi

    # Export all variables from the .env file
    source "$ENV_FILE"
}

# Calls openai with a system prompt and a human message prompt using curl and python3
function call_openai() {
    dotenv

    local SYSTEM_PROMPT="$1"
    local PROMPT="$2"

    if [[ -z "$OPENAI_API_KEY" || -z "$OPENAI_MODEL" ]]; then
        echo "Error: OPENAI_API_KEY is not set. Please set your API key."
        return 1
    fi

    if [[ -z "$SYSTEM_PROMPT" || -z "$PROMPT" ]]; then
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

    # Define the request payload
    DATA=$(python3 -c "
import json, sys
data = {
    \"model\": \"$OPENAI_MODEL\",
    \"messages\": [
        {\"role\": \"system\", \"content\": sys.argv[1]},
        {\"role\": \"user\", \"content\": sys.argv[2]}
    ]
}
print(json.dumps(data))
" "$SYSTEM_PROMPT" "$PROMPT")

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
function call_azure_openai() {
    dotenv

    local SYSTEM_PROMPT="$1"
    local PROMPT="$2"

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

    if [[ -z "$SYSTEM_PROMPT" || -z "$PROMPT" ]]; then
        echo "Error: System prompt and user prompt are required."
        return 1
    fi

    URL="$AZURE_OPENAI_ENDPOINT/openai/deployments/$AZURE_OPENAI_DEPLOYMENT/chat/completions?api-version=$AZURE_API_VERSION"

    # Construct the JSON payload using Python to ensure proper JSON formatting
    DATA=$(python3 -c '
import json, sys
data = {
    "messages": [
        {"role": "system", "content": sys.argv[1]},
        {"role": "user", "content": sys.argv[2]}
    ]
}
print(json.dumps(data))
' "$SYSTEM_PROMPT" "$PROMPT")

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
    dotenv
    local SYSTEM_PROMPT="$1"
    local PROMPT="$2"

    if [[ -n "$AZURE_OPENAI_API_KEY" ]]; then
        (call_azure_openai "$SYSTEM_PROMPT" "$PROMPT")
    else
        (call_openai "$SYSTEM_PROMPT" "$PROMPT")
    fi
}
