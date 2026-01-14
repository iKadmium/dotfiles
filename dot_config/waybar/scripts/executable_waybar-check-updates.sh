#!/bin/bash

# Get the formatted string
LAST_RUN_STR=$(systemctl show rpm-ostreed-automatic.timer --property=LastTriggerUSec --value)

if [ -z "$LAST_RUN_STR" ] || [ "$LAST_RUN_STR" == "n/a" ]; then
    TIME_MSG="Never"
else
    # This trims "Thu 2026-01-15 09:09:07 AEDT" -> "Jan 15 09:09"
    TIME_MSG=$(date -d "$LAST_RUN_STR" "+%b %d %H:%M")
fi

# Check for staged updates
STAGED=$(rpm-ostree status --json 2>/dev/null | jq '.deployments[] | select(.staged == true)')

if [ -n "$STAGED" ]; then
    echo "{\"text\": \"\", \"tooltip\": \"Update staged! Reboot to apply.\nLast check: $TIME_MSG\", \"class\": \"pending\"}"
else
    echo "{\"text\": \"\", \"tooltip\": \"System up to date.\nLast check: $TIME_MSG\", \"class\": \"updated\"}"
fi

