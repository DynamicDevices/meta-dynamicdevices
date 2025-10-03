#!/bin/bash
# Hardware ID Extraction Script for i.MX93/i.MX8MM Dynamic Devices Boards
# Extracts unique hardware identifiers for device registration and identification
#
# Usage: ./extract-hardware-id.sh [--format json|text|foundries]
#
# This script extracts hardware identifiers from:
# - OCOTP/NVMEM (SOC unique ID)
# - Device tree model information
# - MAC addresses (if available)
# - Serial numbers from various sources

set -e

# Default configuration
DEFAULT_FORMAT="text"
SCRIPT_NAME="$(basename "$0")"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Usage function
usage() {
    cat << EOF
Hardware ID Extraction Script for Dynamic Devices Boards

Usage: $SCRIPT_NAME [OPTIONS]

OPTIONS:
    -f, --format FORMAT     Output format: text, json, foundries (default: $DEFAULT_FORMAT)
    -h, --help              Show this help message
    -v, --verbose           Enable verbose output

FORMATS:
    text        Human-readable text output (default)
    json        JSON format for programmatic use
    foundries   Format suitable for Foundries.io device registration

EXAMPLES:
    # Basic usage
    $SCRIPT_NAME

    # JSON output for scripts
    $SCRIPT_NAME --format json

    # Foundries.io device registration format
    $SCRIPT_NAME --format foundries

The script extracts hardware identifiers from:
- OCOTP/NVMEM (SOC unique ID via EdgeLock Enclave)
- Device tree model and compatible strings
- Network interface MAC addresses
- System serial numbers and UUIDs

EOF
}

# Extract SOC unique ID from OCOTP/NVMEM
extract_soc_uid() {
    local soc_uid=""
    local method=""
    
    # Method 1: ELE-based OCOTP (i.MX93)
    if [[ -f "/sys/bus/nvmem/devices/ELE-OCOTP0/nvmem" ]]; then
        # Read unique ID from ELE OCOTP (typically at offset 0x410-0x420)
        if command -v hexdump >/dev/null 2>&1; then
            soc_uid=$(hexdump -C /sys/bus/nvmem/devices/ELE-OCOTP0/nvmem 2>/dev/null | \
                     grep "00000410\|00000420" | \
                     awk '{print $2$3$4$5$6$7$8$9}' | \
                     tr -d ' ' | head -1)
            method="ELE-OCOTP0"
        fi
    fi
    
    # Method 2: Standard OCOTP (i.MX8MM)
    if [[ -z "$soc_uid" && -f "/sys/bus/nvmem/devices/imx-ocotp0/nvmem" ]]; then
        if command -v hexdump >/dev/null 2>&1; then
            soc_uid=$(hexdump -C /sys/bus/nvmem/devices/imx-ocotp0/nvmem 2>/dev/null | \
                     grep "00000410\|00000420" | \
                     awk '{print $2$3$4$5$6$7$8$9}' | \
                     tr -d ' ' | head -1)
            method="imx-ocotp0"
        fi
    fi
    
    # Method 3: SOC device tree serial number
    if [[ -z "$soc_uid" && -f "/sys/devices/soc0/serial_number" ]]; then
        soc_uid=$(cat /sys/devices/soc0/serial_number 2>/dev/null)
        method="soc0/serial_number"
    fi
    
    # Method 4: Machine ID fallback
    if [[ -z "$soc_uid" && -f "/etc/machine-id" ]]; then
        soc_uid=$(cat /etc/machine-id 2>/dev/null)
        method="machine-id"
    fi
    
    echo "$soc_uid|$method"
}

# Extract device tree model information
extract_device_info() {
    local model=""
    local compatible=""
    
    if [[ -f "/proc/device-tree/model" ]]; then
        model=$(cat /proc/device-tree/model 2>/dev/null | tr -d '\0')
    fi
    
    if [[ -f "/proc/device-tree/compatible" ]]; then
        compatible=$(cat /proc/device-tree/compatible 2>/dev/null | tr '\0' ',' | sed 's/,$//')
    fi
    
    echo "$model|$compatible"
}

# Extract MAC addresses
extract_mac_addresses() {
    local macs=()
    
    # Get all network interfaces with MAC addresses
    for iface in /sys/class/net/*/address; do
        if [[ -f "$iface" ]]; then
            local mac=$(cat "$iface" 2>/dev/null)
            local ifname=$(basename "$(dirname "$iface")")
            
            # Skip loopback and virtual interfaces
            if [[ "$mac" != "00:00:00:00:00:00" && "$ifname" != "lo" && ! "$ifname" =~ ^(docker|br-|veth) ]]; then
                macs+=("$ifname:$mac")
            fi
        fi
    done
    
    printf '%s\n' "${macs[@]}"
}

# Extract system information
extract_system_info() {
    local hostname=$(hostname 2>/dev/null || echo "unknown")
    local kernel=$(uname -r 2>/dev/null || echo "unknown")
    local arch=$(uname -m 2>/dev/null || echo "unknown")
    
    echo "$hostname|$kernel|$arch"
}

# Main extraction function
extract_hardware_id() {
    local format="$1"
    local verbose="$2"
    
    # Extract all information
    local soc_info=$(extract_soc_uid)
    local soc_uid=$(echo "$soc_info" | cut -d'|' -f1)
    local soc_method=$(echo "$soc_info" | cut -d'|' -f2)
    
    local device_info=$(extract_device_info)
    local model=$(echo "$device_info" | cut -d'|' -f1)
    local compatible=$(echo "$device_info" | cut -d'|' -f2)
    
    local mac_addresses=($(extract_mac_addresses))
    
    local system_info=$(extract_system_info)
    local hostname=$(echo "$system_info" | cut -d'|' -f1)
    local kernel=$(echo "$system_info" | cut -d'|' -f2)
    local arch=$(echo "$system_info" | cut -d'|' -f3)
    
    # Generate hardware ID based on available information
    local hardware_id=""
    if [[ -n "$soc_uid" && "$soc_uid" != "unknown" ]]; then
        hardware_id="$soc_uid"
    elif [[ ${#mac_addresses[@]} -gt 0 ]]; then
        # Use first MAC address as fallback
        hardware_id=$(echo "${mac_addresses[0]}" | cut -d':' -f2- | tr -d ':')
    else
        hardware_id="unknown"
    fi
    
    # Output in requested format
    case "$format" in
        "json")
            cat << EOF
{
  "hardware_id": "$hardware_id",
  "soc_uid": "$soc_uid",
  "soc_method": "$soc_method",
  "device_model": "$model",
  "device_compatible": "$compatible",
  "hostname": "$hostname",
  "kernel": "$kernel",
  "architecture": "$arch",
  "mac_addresses": [
$(printf '    "%s"' "${mac_addresses[@]}" | sed 's/$/,/' | sed '$s/,$//')
  ]
}
EOF
            ;;
        "foundries")
            echo "# Foundries.io Device Registration Information"
            echo "DEVICE_ID=$hardware_id"
            echo "DEVICE_NAME=$hostname"
            echo "DEVICE_MODEL=$model"
            if [[ ${#mac_addresses[@]} -gt 0 ]]; then
                echo "PRIMARY_MAC=${mac_addresses[0]#*:}"
            fi
            echo "SOC_UID=$soc_uid"
            ;;
        "text"|*)
            echo "=== Hardware ID Extraction Results ==="
            echo ""
            echo "Hardware ID: $hardware_id"
            echo "SOC UID: $soc_uid"
            if [[ -n "$soc_method" ]]; then
                echo "SOC Method: $soc_method"
            fi
            echo "Device Model: $model"
            echo "Compatible: $compatible"
            echo "Hostname: $hostname"
            echo "Kernel: $kernel"
            echo "Architecture: $arch"
            echo ""
            echo "Network Interfaces:"
            if [[ ${#mac_addresses[@]} -gt 0 ]]; then
                for mac in "${mac_addresses[@]}"; do
                    echo "  $mac"
                done
            else
                echo "  No network interfaces found"
            fi
            ;;
    esac
    
    if [[ "$verbose" == "true" ]]; then
        echo ""
        echo "=== Verbose Information ==="
        echo "Available NVMEM devices:"
        ls -la /sys/bus/nvmem/devices/ 2>/dev/null || echo "  No NVMEM devices found"
        echo ""
        echo "SOC information:"
        ls -la /sys/devices/soc0/ 2>/dev/null || echo "  No SOC information found"
    fi
}

# Parse command line arguments
FORMAT="$DEFAULT_FORMAT"
VERBOSE="false"

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--format)
            FORMAT="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE="true"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate format
case "$FORMAT" in
    "text"|"json"|"foundries")
        ;;
    *)
        log_error "Invalid format: $FORMAT"
        log_info "Supported formats: text, json, foundries"
        exit 1
        ;;
esac

# Check if running on target (has device tree)
if [[ ! -d "/proc/device-tree" ]]; then
    log_error "This script must be run on the target device"
    log_info "Device tree not found - not running on embedded target"
    exit 1
fi

# Extract and display hardware ID
extract_hardware_id "$FORMAT" "$VERBOSE"
