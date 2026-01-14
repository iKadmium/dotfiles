#!/bin/bash
# Read current value, default to 1.2 if file missing
STATE_FILE="/tmp/hypr_sdr_brightness"
[ ! -f "$STATE_FILE" ] && echo "1.2" > "$STATE_FILE"

VAL=$(cat "$STATE_FILE")

# Calculate percentage for display (e.g., 1.2 -> 120%)
PERCENT=$(echo "$VAL * 100 / 1" | bc)

# Output JSON for Waybar
echo "{\"text\": \"$PERCENT%\", \"percentage\": $PERCENT}"
