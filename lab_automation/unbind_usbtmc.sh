#!/bin/bash
# WARNING AI/not well tested

# Optional pre-set device, e.g. device='1-1.1:1.0'
device=''

# List devices if not set
if [ -z "$device" ]; then
    echo "Available USBTMC devices:"
    entries=()
    i=1
    for path in /sys/bus/usb/drivers/usbtmc/*:*; do
        [ -e "$path" ] || continue
        name=$(basename "$path")
        echo "  [$i] $name"
        entries+=("$name")
        ((i++))
    done

    if [ ${#entries[@]} -eq 0 ]; then
        echo "No USBTMC devices found."
        exit 1
    fi

    read -p "Select device number to unbind: " selection
    device="${entries[$((selection-1))]}"
fi

# Unbind the device
if [ -n "$device" ]; then
    echo "Unbinding $device from usbtmc..."
    echo "$device" | sudo tee /sys/bus/usb/drivers/usbtmc/unbind
else
    echo "No device selected."
    exit 1
fi