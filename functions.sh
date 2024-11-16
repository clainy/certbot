#!/bin/bash

send_notification() {
    if [ "$SLACK_WEBHOOK" = "" ]; then
        # Add SLACK_WEBHOOK=xxx to /etc/environment
        echo "Missing SLACK_WEBHOOK"
        return 1
    fi

    local message="$1"
    local username="$(hostname -f)"

    # Escape special characters
    message=$(echo "$message" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')

    # Send message to Slack with hostname as username
    local response=$(curl -s -X POST -H 'Content-type: application/json' --data "{
        \"username\": \"$username\",
        \"text\": \"${message}\"
    }" "$SLACK_WEBHOOK")

    if [ "$response" != "ok" ]; then
        echo "$response"
    fi
}