#!/bin/bash

SESSION_NAME=$1
PROMPT=$2

# if SESSION_NAME or PROMPT is not provided, display usage, then exit
if [ -z "$SESSION_NAME" ]  || [ -z "$PROMPT" ]; then
    echo "Usage: $0 SESSION_NAME PROMPT"
    exit 1
fi

echo "Starting session '${SESSION_NAME}' in 'worktrees/${SESSION_NAME}'"

# Create the tmux session
TMUX= tmux new-session -d -s "$SESSION_NAME" sh -c "
# Source environment files before changing directory
[ -f .env ] && source .env
[ -f .env.claude ] && source .env.claude

# Change to the worktree directory
[ ! -d worktrees/$SESSION_NAME ] && git worktree add worktrees/$SESSION_NAME -b $SESSION_NAME && cp .env .env.claude worktrees/$SESSION_NAME && cp foundation-test-*.md worktrees/$SESSION_NAME
cd worktrees/$SESSION_NAME || { echo 'Failed to change to worktree directory'; exit 1; }

# Export the session variables
export SESSION_NAME=$SESSION_NAME
export FEATURE=$SESSION_NAME

# Run claude with the prompt (tools configured in .claude/settings.json)
claude '$PROMPT' --allowedTools 'Edit, Write, Bash, Replace, Read, Glob, Grep, LS'
"
sleep 2 && tmux send-keys -t $SESSION_NAME Enter

echo "Claude tmux session '$SESSION_NAME' started"