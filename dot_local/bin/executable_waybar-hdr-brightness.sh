#!/bin/bash
# Read current value, default to 1.2 if file missing
VAL=$(cat /tmp/hypr_sdr_brightness 2>/dev/null || echo "1.2")

# Calculate percentage for display (e.g., 1.2 -> 120%)
PERCENT=$(echo "$VAL * 100 / 1" | bc)

# Output JSON for Waybar
echo "{\"text\": \"$PERCENT%\", \"percentage\": $PERCENT}"
