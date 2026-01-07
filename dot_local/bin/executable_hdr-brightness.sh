#!/bin/bash

STATE_FILE="/tmp/hypr_sdr_brightness"
[ ! -f "$STATE_FILE" ] && echo "1.2" > "$STATE_FILE"

VAL=$(cat "$STATE_FILE")
STEP=0.1

if [ "$1" == "up" ]; then
    # Cap at 2.0
    NEW_VAL=$(echo "$VAL + $STEP" | bc)
    if (( $(echo "$NEW_VAL > 2.0" | bc -l) )); then NEW_VAL=2.0; fi
elif [ "$1" == "down" ]; then
    # Cap at 0.1
    NEW_VAL=$(echo "$VAL - $STEP" | bc)
    if (( $(echo "$NEW_VAL < 0.1" | bc -l) )); then NEW_VAL=0.1; fi
elif [ "$1" == "set" ]; then
    NEW_VAL=$VAL
else
    echo "Usage: $0 {up|down|set <value>}"
    exit 1
fi

echo "$NEW_VAL" > "$STATE_FILE"

# Get the currently focused monitor
MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name')

# Apply the change
hyprctl keyword "monitorv2[$MONITOR]:sdrbrightness" "$NEW_VAL"

# Signal Waybar to refresh (RTMIN+8 corresponds to signal: 8)
pkill -RTMIN+8 waybar