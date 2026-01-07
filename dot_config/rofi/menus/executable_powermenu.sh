#!/usr/bin/env bash

# Options with Font Awesome Icons
lock=' Lock [L]'
suspend=' Suspend [U]'
logout=' Logout [E]'
reboot=' Reboot [R]'
shutdown=' Shutdown [S]'
yes=' Yes'
no=' No'

# Rofi Command
rofi_cmd() {
    rofi -dmenu \
        -p "Power" \
        -mesg "Uptime: $(uptime -p | sed -e 's/up //g')" \
        -theme ~/.config/rofi/menus/powermenu.rasi
}

# Confirmation Command (Inline theme-str for simplicity)
confirm_cmd() {
    rofi -dmenu \
        -p 'Confirmation' \
        -mesg 'Are you Sure?' \
        -theme-str 'window {width: 250px;} mainbox {children: ["message", "listview"];} listview {columns: 2; lines: 1;}' \
        -kb-select-1 "y" -kb-select-2 "n"
}

# Actions
chosen="$(echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | rofi_cmd)"

# Helper function to dry up the confirmation logic
confirm_and_run() {
    local cmd=$1
    local selected="$(echo -e "$yes\n$no" | confirm_cmd)"
    if [[ "$selected" == "$yes" ]]; then
        eval "$cmd"
    fi
}

case "${chosen}" in
    *"$lock"*)
        sleep 0.1 && hyprlock ;;
    *"$suspend"*)
        confirm_and_run "systemctl suspend" ;;
    *"$logout"*)
        confirm_and_run "hyprctl dispatch exit" ;;
    *"$reboot"*)
        confirm_and_run "systemctl reboot" ;;
    *"$shutdown"*)
        confirm_and_run "systemctl poweroff" ;;
    *)
        # If nothing matches, or user hits Esc, just exit
        exit 0 ;;
esac