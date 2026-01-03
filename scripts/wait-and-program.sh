#!/bin/bash

#
# Wait for USB Device and Program Script
# 
# Handles quick USB disconnects by waiting for device and starting UUU immediately
# This solves the issue where devices disconnect before UUU can connect
#

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS] <uuu-script> [uuu-args...]

Wait for NXP USB device to appear and immediately start UUU programming.

This script solves the issue where devices disconnect quickly before UUU can connect.
It monitors for the device and starts UUU within milliseconds of detection.

OPTIONS:
    -v, --vendor-id ID     USB vendor ID to wait for (default: 1fc9 for NXP)
    -p, --product-id ID    USB product ID to wait for (default: any)
    -t, --timeout SECONDS  Maximum time to wait for device (default: 60)
    -r, --retries NUM      Number of retry attempts if device disconnects (default: 3)
    -w, --wait-ms MS       Wait milliseconds after detection before starting UUU (default: 100)
    -h, --help            Show this help message

EXAMPLES:
    # Wait for device and program with UUU script
    $0 full_image.uuu
    
    # Wait for specific device and program
    $0 --vendor-id 1fc9 --product-id 0134 full_image.uuu
    
    # With retries and custom timeout
    $0 --retries 5 --timeout 120 full_image.uuu

TROUBLESHOOTING:
    If device keeps disconnecting:
    1. Try USB 2.0 port instead of USB 3.0
    2. Use high-quality USB-C data cable
    3. Try powered USB hub
    4. Verify boot mode switches are correctly set
    5. Check board power supply (needs 5V 2A minimum)

EOF
}

# Default values
VENDOR_ID="1fc9"
PRODUCT_ID=""
TIMEOUT=60
RETRIES=3
WAIT_MS=100

# Parse arguments
UUU_SCRIPT=""
UUU_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--vendor-id)
            VENDOR_ID="$2"
            shift 2
            ;;
        -p|--product-id)
            PRODUCT_ID="$2"
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -r|--retries)
            RETRIES="$2"
            shift 2
            ;;
        -w|--wait-ms)
            WAIT_MS="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            if [[ -z "$UUU_SCRIPT" ]]; then
                UUU_SCRIPT="$1"
            else
                UUU_ARGS+=("$1")
            fi
            shift
            ;;
    esac
done

# Validate UUU script
if [[ -z "$UUU_SCRIPT" ]]; then
    log_error "UUU script not specified"
    usage
    exit 1
fi

if [[ ! -f "$UUU_SCRIPT" ]]; then
    log_error "UUU script not found: $UUU_SCRIPT"
    exit 1
fi

# Find UUU tool
UUU_CMD=""
if command -v uuu &> /dev/null; then
    UUU_CMD="uuu"
elif [[ -f "$(dirname "$UUU_SCRIPT")/uuu" ]]; then
    UUU_CMD="$(dirname "$UUU_SCRIPT")/uuu"
    chmod +x "$UUU_CMD"
else
    log_error "UUU tool not found. Install UUU or ensure it's in the same directory as the script."
    exit 1
fi

log_info "Waiting for NXP USB device (vendor: $VENDOR_ID)..."
log_info "Put your board in download mode and connect USB cable"
log_info "Timeout: ${TIMEOUT}s, Retries: $RETRIES"
echo ""

# Function to check if device is present
check_device() {
    if command -v lsusb &> /dev/null; then
        if [[ -n "$PRODUCT_ID" ]]; then
            lsusb | grep -qi "${VENDOR_ID}:${PRODUCT_ID}" && return 0
        else
            lsusb | grep -qi "${VENDOR_ID}:" && return 0
        fi
    fi
    
    # Fallback: check /sys/bus/usb/devices
    for dev in /sys/bus/usb/devices/*/idVendor; do
        if [[ -f "$dev" ]]; then
            vendor=$(cat "$dev" 2>/dev/null | tr '[:upper:]' '[:lower:]' || echo "")
            if [[ "$vendor" == "$VENDOR_ID" ]]; then
                if [[ -n "$PRODUCT_ID" ]]; then
                    prod_file="$(dirname "$dev")/idProduct"
                    if [[ -f "$prod_file" ]]; then
                        product=$(cat "$prod_file" 2>/dev/null | tr '[:upper:]' '[:lower:]' || echo "")
                        if [[ "$product" == "$PRODUCT_ID" ]]; then
                            return 0
                        fi
                    fi
                else
                    return 0
                fi
            fi
        fi
    done
    
    return 1
}

# Function to wait for device
wait_for_device() {
    local start_time=$(date +%s)
    local elapsed=0
    
    while [[ $elapsed -lt $TIMEOUT ]]; do
        if check_device; then
            log_success "Device detected!"
            return 0
        fi
        
        sleep 0.1
        elapsed=$(($(date +%s) - start_time))
        
        # Show progress every 2 seconds
        if [[ $((elapsed % 2)) -eq 0 ]] && [[ $elapsed -gt 0 ]]; then
            echo -ne "\r${BLUE}[INFO]${NC} Waiting for device... (${elapsed}s/${TIMEOUT}s) "
        fi
    done
    
    return 1
}

# Main programming loop with retries
attempt=0
while [[ $attempt -lt $RETRIES ]]; do
    attempt=$((attempt + 1))
    
    if [[ $attempt -gt 1 ]]; then
        log_warn "Retry attempt $attempt of $RETRIES"
        log_info "Disconnect and reconnect your board in download mode"
        sleep 2
    fi
    
    # Wait for device
    if ! wait_for_device; then
        log_error "Device not detected within ${TIMEOUT} seconds"
        if [[ $attempt -lt $RETRIES ]]; then
            log_info "Will retry..."
            continue
        else
            log_error "All retry attempts exhausted"
            exit 1
        fi
    fi
    
    # Small delay to ensure device is stable
    if [[ $WAIT_MS -gt 0 ]]; then
        sleep 0.$((WAIT_MS / 100))
    fi
    
    # Start UUU immediately
    log_info "Starting UUU programming..."
    echo ""
    
    if "$UUU_CMD" "$UUU_SCRIPT" "${UUU_ARGS[@]}"; then
        log_success "Programming completed successfully!"
        exit 0
    else
        local exit_code=$?
        log_warn "UUU exited with code $exit_code"
        
        # Check if device is still connected
        if check_device; then
            log_info "Device still connected - may have succeeded"
            log_info "Check your board to verify programming"
            exit 0
        else
            log_warn "Device disconnected during programming"
            if [[ $attempt -lt $RETRIES ]]; then
                log_info "Will retry..."
                continue
            else
                log_error "Programming failed after $RETRIES attempts"
                exit 1
            fi
        fi
    fi
done

log_error "Programming failed"
exit 1




