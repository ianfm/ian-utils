#!/usr/bin/env bash
set -euo pipefail

# serial_console.sh
# - Finds all serial devices with 'FTDI' in their by-id path
# - Lets the user select one
# - Prints the device output to the terminal
# - Optional: --log <filename> to save output
# - Gracefully handles Ctrl+C

# Based on simple tty monitoring operation:
# ls /dev/serial/by-id/
#     usb-FTDI_FT232R_USB_UART_B0009XMI-if00-port0  usb-FTDI_TTL232RG-VIP_FTWSBATX-if00-port0  usb-SEGGER_J-Link_000069654637-if00
# stty -F /dev/serial/by-id/usb-FTDI_TTL232RG-VIP_FTWSBATX-if00-port0 9600
# cat /dev/serial/by-id/usb-FTDI_TTL232RG-VIP_FTWSBATX-if00-port0 

usage() {
  cat <<'EOF'
Usage: scripts/serial_console.sh [--log <filename>] [--baud <rate>]

Options:
  --log <filename>   Save output to the specified file (off by default)
  --baud <rate>      Serial baud rate (default: 9600; example used in repo)
  -h, --help         Show this help

This script searches /dev/serial/by-id for entries containing 'FTDI'.
EOF
}

LOG_FILE=""
BAUD=9600

# Parse args
while [[ $# -gt 0 ]]; do
  case "${1}" in
    --log)
      shift
      [[ $# -gt 0 ]] || { echo "Error: --log requires a filename" >&2; exit 2; }
      LOG_FILE="$1"; shift ;;
    --baud)
      shift
      [[ $# -gt 0 ]] || { echo "Error: --baud requires a rate" >&2; exit 2; }
      BAUD="$1"; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2 ;;
  esac
done

# Find FTDI devices in by-id path
mapfile -t DEVICES < <(ls -1 /dev/serial/by-id/*FTDI* 2>/dev/null | sort || true)

if [[ ${#DEVICES[@]} -eq 0 ]]; then
  echo "No FTDI serial devices found under /dev/serial/by-id." >&2
  echo "Tip: Check 'ls -l /dev/serial/by-id' or ensure your adapter is connected." >&2
  exit 1
fi

DEVICE=""
if [[ ${#DEVICES[@]} -eq 1 ]]; then
  DEVICE="${DEVICES[0]}"
  echo "Found one device: ${DEVICE}"
else
  echo "Select a device:";
  i=1
  for d in "${DEVICES[@]}"; do
    real=$(readlink -f "$d" || true)
    printf "  [%d] %s -> %s\n" "$i" "$d" "${real:-unknown}"
    ((i++))
  done
  while true; do
    read -r -p "Enter selection [1-${#DEVICES[@]}]: " sel
    if [[ "$sel" =~ ^[0-9]+$ ]] && (( sel >= 1 && sel <= ${#DEVICES[@]} )); then
      DEVICE="${DEVICES[sel-1]}"
      break
    fi
    echo "Invalid selection."
  done
fi

if [[ ! -e "$DEVICE" ]]; then
  echo "Selected device does not exist: $DEVICE" >&2
  exit 1
fi

REAL_TTY=$(readlink -f "$DEVICE" || echo "")
[[ -n "$REAL_TTY" ]] || REAL_TTY="$DEVICE"

echo "Using device: $DEVICE (real: $REAL_TTY)"
echo "Configuring baud: $BAUD"

# Configure the serial port. Use raw mode; fall back to basic if raw not supported.
if ! stty -F "$DEVICE" "$BAUD" raw -echo -icrnl -ixon 2>/dev/null; then
  stty -F "$DEVICE" "$BAUD" 2>/dev/null || true
fi

READER_PID=""
cleanup() {
  echo
  echo "Stopping..."
  if [[ -n "$READER_PID" ]]; then
    kill "$READER_PID" 2>/dev/null || true
    wait "$READER_PID" 2>/dev/null || true
  fi
}
trap cleanup INT TERM

# Start reading
if [[ -n "$LOG_FILE" ]]; then
  echo "Logging to: $LOG_FILE"
  mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
  # Use tee as the reader process directly bound to the device to avoid pipeline PID issues
  tee -a "$LOG_FILE" < "$DEVICE" &
  READER_PID=$!
else
  cat "$DEVICE" &
  READER_PID=$!
fi

echo "Printing output. Press Ctrl+C to stop."

# Wait for reader to exit (Ctrl+C or device unplugged)
wait "$READER_PID"

# If we reach here without a signal, perform cleanup explicitly
cleanup

