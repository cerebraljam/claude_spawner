#!/bin/bash

SESSION_NAME=$1
FEATURE=$2
PROMPT=$3

# if SESSION_NAME, FEATURE or PROMPT is not provided, display usage, then exit
if [ -z "$SESSION_NAME" ] || [ -z "$FEATURE" ] || [ -z "$PROMPT" ]; then
    echo "Usage: $0 SESSION_NAME FEATURE PROMPT"
    exit 1
fi

echo "Starting session '${SESSION_NAME}' in 'worktrees/${FEATURE}'"

# Create the tmux session
TMUX= tmux new-session -d -s "$SESSION_NAME" sh -c "
# Source environment files before changing directory
[ -f .env ] && source .env
[ -f .env.claude ] && source .env.claude

# Change to the worktree directory
cd worktrees/$FEATURE || { echo 'Failed to change to worktree directory'; exit 1; }

# Export the session variables
export SESSION_NAME='$SESSION_NAME'
export FEATURE='$FEATURE'

# Run claude with the prompt (tools configured in .claude/settings.json)
claude '$PROMPT'
"

echo "Session '$SESSION_NAME' started. Attach with: tmux attach-session -t '$SESSION_NAME'"