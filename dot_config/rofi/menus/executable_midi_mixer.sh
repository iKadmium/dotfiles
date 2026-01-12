#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# State file location
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/midi_mixer"
STATE_FILE="$STATE_DIR/state.json"

# Ensure state directory exists
mkdir -p "$STATE_DIR"

# Initialize state file if it doesn't exist
if [ ! -f "$STATE_FILE" ]; then
    echo '{"cc_values":{},"cc_bool_states":{},"pc_values":{}}' > "$STATE_FILE"
fi

# Load state
load_state() {
    jq -r "$1" "$STATE_FILE" 2>/dev/null || echo ""
}

# Save state
save_state() {
    local key="$1"
    local value="$2"
    local tmp_file="${STATE_FILE}.tmp"
    jq "$key = $value" "$STATE_FILE" > "$tmp_file" && mv "$tmp_file" "$STATE_FILE"
}

# Send MIDI message
send_midi() {
    local channel="$1"
    local attr_name="$2"
    local value="$3"
    
    # Get device and MIDI parameters for this attribute
    local device=$(jq -r ".channels[\"$channel\"][\"$attr_name\"].device" "$SCRIPT_DIR/midi_mixer.json")
    local midi_channel=$(jq -r ".channels[\"$channel\"][\"$attr_name\"].channel" "$SCRIPT_DIR/midi_mixer.json")
    local attr_type=$(jq -r ".channels[\"$channel\"][\"$attr_name\"].type // \"cc\"" "$SCRIPT_DIR/midi_mixer.json")
    
    # Get device output name
    local output_device=$(jq -r ".devices[\"$device\"].output_device" "$SCRIPT_DIR/midi_mixer.json")
    
    # Find the hardware port for this device
    local hw_port=$(amidi -l | grep "$output_device" | grep -o "hw:[0-9,]*" | head -n1)
    
    if [ -z "$hw_port" ]; then
        echo "Error: Could not find hardware port for $output_device"
        return 1
    fi
    
    if [ "$attr_type" = "pc" ]; then
        # Program Change: Cn pp (where n is channel, pp is program number)
        local status=$(printf "%02x" $((0xC0 + midi_channel)))
        local program=$(printf "%02x" "$value")
        amidi -p "$hw_port" --send-hex="$status $program"
    else
        # Control Change: Bn cc vv (where n is channel, cc is control number, vv is value)
        local cc=$(jq -r ".channels[\"$channel\"][\"$attr_name\"].cc" "$SCRIPT_DIR/midi_mixer.json")
        local status=$(printf "%02x" $((0xB0 + midi_channel)))
        local cc_hex=$(printf "%02x" "$cc")
        local value_hex=$(printf "%02x" "$value")
        amidi -p "$hw_port" --send-hex="$status $cc_hex $value_hex"
    fi
}

# Validate MIDI devices
validate_midi_devices() {
    # Get list of available MIDI devices
    midi_devices=$(amidi -l 2>/dev/null)
    
    if [ -z "$midi_devices" ]; then
        rofi -e "Error: Cannot access MIDI devices.
Is amidi installed?"
        exit 1
    fi
    
    # Get all configured devices that need output capability
    configured_devices=$(jq -r '.devices | to_entries[] | select(.value.type == "midi") | .value.output_device' "$SCRIPT_DIR/midi_mixer.json")
    
    not_found_devices=""
    no_output_devices=""
    
    while IFS= read -r device_name; do
        # Search for this device in the amidi output
        # amidi -l format: "IO  hw:X,Y DeviceName"
        if echo "$midi_devices" | grep -q "$device_name"; then
            # Device found, check if it has output capability (O in the first column)
            if ! echo "$midi_devices" | grep -q "O.*$device_name"; then
                no_output_devices+="  • $device_name
"
            fi
        else
            # Device not found at all
            not_found_devices+="  • $device_name
"
        fi
    done <<< "$configured_devices"
    
    if [ -n "$not_found_devices" ] || [ -n "$no_output_devices" ]; then
        error_msg="MIDI Device Error

"
        
        if [ -n "$not_found_devices" ]; then
            error_msg+="The following devices were not found:
$not_found_devices
"
        fi
        
        if [ -n "$no_output_devices" ]; then
            error_msg+="The following devices lack output capability:
$no_output_devices
"
        fi
        
        error_msg+="Available MIDI devices:
$(amidi -l | tail -n +2 | sed 's/^[IO ]*hw:[0-9,]* */  • /')

Please connect the required devices and try again."
        
        rofi -e "$error_msg"
        exit 1
    fi
}

# Validate MIDI devices before proceeding
validate_midi_devices

# Read the JSON file and extract channel names (preserve order)
channel_list=$(jq -r '.channels | to_entries | .[].key' "$SCRIPT_DIR/midi_mixer.json")

# Show channel selection menu
selected_channel=$(echo "$channel_list" | rofi -dmenu -i -no-sort -p "Select Channel")

# Exit if no channel was selected
if [ -z "$selected_channel" ]; then
    exit 0
fi

# Get all attributes for this channel with their keys (preserve order)
attributes=$(jq -r ".channels[\"$selected_channel\"] | to_entries | .[].key" "$SCRIPT_DIR/midi_mixer.json")

# Find and set default selected attribute (first CC type attribute)
current_attribute=""
while IFS= read -r attr; do
    attr_type=$(jq -r ".channels[\"$selected_channel\"][\"$attr\"].type // \"cc\"" "$SCRIPT_DIR/midi_mixer.json")
    if [ "$attr_type" = "cc" ]; then
        current_attribute="$attr"
        # Ensure default value exists in state
        current_value=$(load_state ".cc_values[\"$selected_channel\"][\"$current_attribute\"]")
        if [ -z "$current_value" ]; then
            save_state ".cc_values[\"$selected_channel\"][\"$current_attribute\"]" "0"
        fi
        break
    fi
done <<< "$attributes"

# Submenu loop - continue until user presses Esc
while true; do
    # Build the submenu options with hotkeys and current values
    submenu_options=""
    while IFS= read -r attr; do
        # Get the key binding for this attribute
        key=$(jq -r ".channels[\"$selected_channel\"][\"$attr\"].key // empty" "$SCRIPT_DIR/midi_mixer.json")
        attr_type=$(jq -r ".channels[\"$selected_channel\"][\"$attr\"].type // \"cc\"" "$SCRIPT_DIR/midi_mixer.json")
        
        # Get current value/state for this attribute
        state_key="$selected_channel.$attr"
        if [ "$attr_type" = "cc-bool" ]; then
            current_state=$(load_state ".cc_bool_states[\"$state_key\"]")
            
            # Check for custom glyphs
            custom_glyph_on=$(jq -r ".channels[\"$selected_channel\"][\"$attr\"].glyphs.on // empty" "$SCRIPT_DIR/midi_mixer.json")
            custom_glyph_off=$(jq -r ".channels[\"$selected_channel\"][\"$attr\"].glyphs.off // empty" "$SCRIPT_DIR/midi_mixer.json")
            
            if [ "$current_state" = "true" ]; then
                if [ -n "$custom_glyph_on" ]; then
                    value_display="$custom_glyph_on"
                else
                    value_display="✓"  # Unicode check mark
                fi
            else
                if [ -n "$custom_glyph_off" ]; then
                    value_display="$custom_glyph_off"
                else
                    value_display="✗"  # Unicode X mark
                fi
            fi
        elif [ "$attr_type" = "pc" ]; then
            value_display=$(load_state ".pc_values[\"$state_key\"]")
            [ -z "$value_display" ] && value_display="-"
        else
            # CC type
            value_display=$(load_state ".cc_values[\"$selected_channel\"][\"$attr\"]")
            [ -z "$value_display" ] && value_display="0"
        fi
        
        # Add selection indicator for current attribute
        selection_indicator=""
        if [ "$attr" = "$current_attribute" ]; then
            selection_indicator="▶ "  # Unicode right-pointing triangle
        fi
        
        # Format with key binding, value, and selection indicator
        if [ -n "$key" ]; then
            submenu_options+="$selection_indicator$attr [$key]: $value_display\n"
        else
            submenu_options+="$selection_indicator$attr: $value_display\n"
        fi
    done <<< "$attributes"
    
    # Build status message showing selected channel and current value
    current_value=""
    if [ -n "$current_attribute" ]; then
        current_value=$(load_state ".cc_values[\"$selected_channel\"][\"$current_attribute\"]")
        [ -z "$current_value" ] && current_value="0"
    fi
    status_msg="Channel: $selected_channel"
    if [ -n "$current_attribute" ]; then
        status_msg+=" | Selected: $current_attribute = $current_value"
    fi
    status_msg+="
Home: Min | PgUp: -10 | Left: -1 | Right: +1 | PgDn: +10 | End: Max"
    
    # Build rofi args with key bindings
    rofi_args=(
        -dmenu
        -i
        -no-sort
        -p "$selected_channel"
        -mesg "$status_msg"
        -no-custom
        -theme-str "mainbox {children: [\"message\", \"listview\"];} listview { columns: 5;lines: 1;} #element.selected.normal {background-color: inherit; }"
        -kb-move-front ""
        -kb-move-end ""
        -kb-page-prev ""
        -kb-page-next ""
        -kb-row-up ""
        -kb-row-down ""
        -kb-row-first ""
        -kb-row-last ""
        -kb-move-char-back ""
        -kb-move-char-forward ""
        -kb-custom-1 "Home"
        -kb-custom-2 "Prior"
        -kb-custom-3 "Left"
        -kb-custom-4 "Right"
        -kb-custom-5 "Next"
        -kb-custom-6 "End"
    )
    
    # Add custom key bindings for each attribute
    custom_slot=7
    while IFS= read -r attr; do
        key=$(jq -r ".channels[\"$selected_channel\"][\"$attr\"].key // empty" "$SCRIPT_DIR/midi_mixer.json")
        if [ -n "$key" ]; then
            rofi_args+=("-kb-custom-$custom_slot" "$key")
            ((custom_slot++))
        fi
    done <<< "$attributes"
    
    # Show submenu
    selected_option=$(echo -e "${submenu_options%\\n}" | rofi "${rofi_args[@]}")
    exit_code=$?
    
    # Exit code 1 means Esc was pressed
    if [ $exit_code -eq 1 ]; then
        break
    fi
    
    # Handle custom key presses (attribute hotkeys start at exit code 16)
    if [ $exit_code -ge 16 ]; then
        # Map exit code to attribute
        attr_index=$((exit_code - 16))
        selected_attr=$(echo "$attributes" | sed -n "$((attr_index + 1))p")
        
        # Get attribute type
        attr_type=$(jq -r ".channels[\"$selected_channel\"][\"$selected_attr\"].type // \"cc\"" "$SCRIPT_DIR/midi_mixer.json")
        
        if [ "$attr_type" = "cc-bool" ]; then
            # Toggle cc-bool state
            state_key="$selected_channel.$selected_attr"
            current_state=$(load_state ".cc_bool_states[\"$state_key\"]")
            if [ "$current_state" = "true" ]; then
                new_state="false"
            else
                new_state="true"
            fi
            save_state '.cc_bool_states' "$(jq -n --arg k "$state_key" --argjson v $new_state '.[$k] = $v')"
            echo "Toggle $selected_attr to $new_state"
            # Send MIDI CC (127 for true, 0 for false)
            midi_value=0
            [ "$new_state" = "true" ] && midi_value=127
            send_midi "$selected_channel" "$selected_attr" "$midi_value"
        elif [ "$attr_type" = "pc" ]; then
            # Show program selection submenu
            programs=$(jq -r ".channels[\"$selected_channel\"][\"$selected_attr\"].programs[]" "$SCRIPT_DIR/midi_mixer.json")
            
            # Load last selected program for this control
            state_key="$selected_channel.$selected_attr"
            last_program=$(load_state ".pc_values[\"$state_key\"]")
            
            selected_program=$(echo "$programs" | rofi -dmenu -i -no-sort -p "$selected_attr" -select "$last_program")
            if [ -n "$selected_program" ]; then
                # Get program index (0-based)
                program_index=$(echo "$programs" | grep -nx "$selected_program" | cut -d: -f1)
                program_index=$((program_index - 1))
                
                # Save selected program
                save_state '.pc_values' "$(jq -n --arg k "$state_key" --arg v "$selected_program" '.[$k] = $v')"
                echo "Set $selected_attr to $selected_program (program $program_index)"
                # Send MIDI program change
                send_midi "$selected_channel" "$selected_attr" "$program_index"
            fi
        else
            # CC control - set as current attribute
            current_attribute="$selected_attr"
            echo "Selected attribute: $current_attribute"
        fi
        continue
    fi
    
    # Ignore Enter key (exit code 0) - only respond to hotkeys
    if [ $exit_code -eq 0 ]; then
        continue
    fi
    
    # Exit code 10-15 correspond to custom-1 through custom-6 (hotkeys for cc controls)
    # Only apply if we have a current CC attribute selected
    if [ -n "$current_attribute" ]; then
        # Get current value
        current_value=$(load_state ".cc_values[\"$selected_channel\"][\"$current_attribute\"]")
        if [ -z "$current_value" ]; then
            current_value=0
        fi
        
        case $exit_code in
            10)
                # Set to minimum (0)
                new_value=0
                ;;
            11)
                # Decrease by 10
                new_value=$((current_value - 10))
                [ $new_value -lt 0 ] && new_value=0
                ;;
            12)
                # Decrease by 1
                new_value=$((current_value - 1))
                [ $new_value -lt 0 ] && new_value=0
                ;;
            13)
                # Increase by 1
                new_value=$((current_value + 1))
                [ $new_value -gt 127 ] && new_value=127
                ;;
            14)
                # Increase by 10
                new_value=$((current_value + 10))
                [ $new_value -gt 127 ] && new_value=127
                ;;
            15)
                # Set to maximum (127)
                new_value=127
                ;;
            *)
                new_value=$current_value
                ;;
        esac
        
        # Save new value if changed
        if [ "$new_value" != "$current_value" ] && [ -n "$new_value" ]; then
            save_state ".cc_values[\"$selected_channel\"][\"$current_attribute\"]" "$new_value"
            echo "Set $current_attribute to $new_value"
            # Send MIDI CC
            send_midi "$selected_channel" "$current_attribute" "$new_value"
        fi
    fi
done
