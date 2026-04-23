#!/bin/bash

# Get battery information from upower
battery_info=$(upower -d | awk '/battery_BAT/,/^$/')

# Extract raw percentage and capacity
raw_percentage=$(echo "$battery_info" | grep "percentage:" | awk '{print $2}' | tr -d '%')
capacity=$(echo "$battery_info" | grep "capacity:" | awk '{print $2}' | tr -d '%')

# Calculate actual percentage based on capacity
if [ -n "$raw_percentage" ] && [ -n "$capacity" ]; then
    percentage=$(awk "BEGIN {printf \"%.0f\", ($raw_percentage / $capacity) * 100}")
else
    percentage=$raw_percentage
fi

# Extract state (charging, discharging, fully-charged)
state=$(echo "$battery_info" | grep "state:" | awk '{print $2}')

# Check if plugged in
plugged_in=$(upower -d | awk '/line_power/,/^$/' | grep "online:" | awk '{print $2}')

# Extract time to empty or time to full
time_info=$(echo "$battery_info" | grep -E "time to empty:|time to full:" | awk '{for(i=3;i<=NF;i++) printf "%s ", $i; print ""}')

# Determine icon based on percentage and state
if [ "$plugged_in" = "yes" ]; then
    icon=$'\uf1e6'  # fa-plug
elif [ "$state" = "charging" ]; then
    icon=$'\uf0e7'  # fa-bolt
elif [ "$state" = "fully-charged" ]; then
    icon=$'\uf240'  # fa-battery-full
elif [ -z "$percentage" ]; then
    icon=$'\uf128'  # fa-question
    percentage="N/A"
else
    if [ "$percentage" -ge 90 ]; then
        icon=$'\uf240'  # fa-battery-full
    elif [ "$percentage" -ge 60 ]; then
        icon=$'\uf241'  # fa-battery-three-quarters
    elif [ "$percentage" -ge 40 ]; then
        icon=$'\uf242'  # fa-battery-half
    elif [ "$percentage" -ge 20 ]; then
        icon=$'\uf243'  # fa-battery-quarter
    else
        icon=$'\uf244'  # fa-battery-empty
    fi
fi

# Build tooltip
tooltip="Battery: ${percentage}%"
if [ "$plugged_in" = "yes" ]; then
    tooltip="${tooltip}\nPlugged in"
fi
if [ -n "$time_info" ]; then
    tooltip="${tooltip}\n${time_info}"
fi
tooltip="${tooltip}\nState: ${state}"
if [ -n "$capacity" ]; then
    tooltip="${tooltip}\nCapacity: ${capacity}%"
fi

# Output JSON for waybar
echo "{\"text\":\"${icon} ${percentage}%\", \"tooltip\":\"${tooltip}\", \"class\":\"${state}\", \"percentage\":${percentage:-0}}"
