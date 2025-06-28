#!/bin/bash

echo "Monitoring for new tmux sessions..."
echo "Press Ctrl+C to exit"

while true; do
    # Get sessions that have no clients attached
    unattached_session=$(tmux list-sessions -F '#{session_name}:#{session_attached}' 2>/dev/null | grep ':0$' | head -n1 | cut -d: -f1)
    
    if [ -n "$unattached_session" ]; then
        echo "Found unattached session: $unattached_session"
        echo "Attaching..."
        
        # Attach to the session
        tmux attach-session -t "$unattached_session"
        
        # When we detach or session ends, check if session still exists
        if ! tmux has-session -t "$unattached_session" 2>/dev/null; then
            echo "Session '$unattached_session' has ended"
        else
            echo "Detached from session '$unattached_session'"
        fi
        
        echo "Continuing to monitor..."
    fi
    
    # Wait a bit before checking again
    sleep 2
done