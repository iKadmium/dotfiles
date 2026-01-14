#!/bin/bash

# Check if a deployment is staged (Update ready)
STAGED=$(rpm-ostree status --json | jq '.deployments[] | select(.staged == true)')

# Get the last time the timer successfully ran
LAST_RUN=$(systemctl show rpm-ostreed-automatic.timer --property=LastTriggerUSecMonotonic --value)

# Format the time (Simple version)
if [ "$LAST_RUN" == "0" ]; then
    TIME_MSG="Never"
else
    TIME_MSG="Recently" # Or use 'uptime' logic for more precision
fi

if [ -n "$STAGED" ]; then
    echo "{\"text\": \"\", \"tooltip\": \"Update staged! Reboot to apply.\nLast check: $TIME_MSG\", \"class\": \"pending\"}"
else
    echo "{\"text\": \"\", \"tooltip\": \"System up to date.\nLast check: $TIME_MSG\", \"class\": \"updated\"}"
fi