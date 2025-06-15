#!/bin/bash

SESSION_NAME=$1
FEATURE=$2
PROMPT=$3

# if SESSION_NAME, FEATURE or PROMPT is not provided, display usage, then exit
if [ -z "$SESSION_NAME" ] || [ -z "$FEATURE" ] || [ -z "$PROMPT" ]; then
    echo "Usage: $0 SESSION_NAME FEATURE PROMPT"
    exit 1
fi

# Load environment variables from .env file if it exists
ENV_VARS=""
if [ -f ".env" ]; then
    echo "Loading environment variables from .env file..."
    # Read .env file, skip comments and empty lines, export variables
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and empty lines
        if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "${line// }" ]]; then
            continue
        fi
        # Export the variable
        export "$line"
        # Build tmux -e arguments dynamically
        VAR_NAME=$(echo "$line" | cut -d'=' -f1)
        ENV_VARS="$ENV_VARS -e $VAR_NAME=\"\${$VAR_NAME}\""
    done < ".env"
fi

# Verify essential environment variables are set
if [ -z "$ANTHROPIC_AUTH_TOKEN" ]; then
    echo "Warning: ANTHROPIC_AUTH_TOKEN not set. Make sure to set it in .env file or as environment variable."
fi

echo "Starting session '${SESSION_NAME}' in 'worktrees/${FEATURE}'"

# Pass through all environment variables dynamically to tmux session
eval "tmux new-session -d -s \"$SESSION_NAME\" $ENV_VARS \"cd worktrees/$FEATURE && claude config set hasTrustDialogAccepted true && claude '$PROMPT' --allowedTools 'Edit,Write,Bash,Replace,Read,Glob,Grep,LS,MultiEdit'\""