#!/bin/bash

#
# i.MX8MM RDC (Resource Domain Controller) Control Script
# Provides runtime control over peripheral domain assignments
#

SCRIPT_NAME="rdc-control"
LOG_TAG="[$SCRIPT_NAME]"

# RDC sysfs paths (may vary depending on kernel implementation)
RDC_SYSFS_BASE="/sys/devices/platform/rdc"
RDC_DEBUGFS_BASE="/sys/kernel/debug/rdc"

# Function to log messages
log_info() {
    echo "$LOG_TAG INFO: $1"
    logger -t "$SCRIPT_NAME" "INFO: $1"
}

log_error() {
    echo "$LOG_TAG ERROR: $1" >&2
    logger -t "$SCRIPT_NAME" "ERROR: $1"
}

# Function to check if RDC driver is loaded
check_rdc_driver() {
    if [ -d "$RDC_SYSFS_BASE" ] || [ -d "$RDC_DEBUGFS_BASE" ]; then
        return 0
    fi
    
    # Check if RDC module is loaded
    if lsmod | grep -q rdc; then
        return 0
    fi
    
    # Check dmesg for RDC driver messages
    if dmesg | grep -qi rdc; then
        return 0
    fi
    
    return 1
}

# Function to show RDC status
show_rdc_status() {
    log_info "Checking RDC driver status..."
    
    if ! check_rdc_driver; then
        log_error "RDC driver not found or not loaded"
        echo "Possible solutions:"
        echo "1. Check if CONFIG_IMX_RDC is enabled in kernel"
        echo "2. Load RDC module: modprobe imx-rdc"
        echo "3. Check dmesg for RDC-related errors"
        return 1
    fi
    
    log_info "RDC driver appears to be loaded"
    
    # Show available RDC interfaces
    echo "Available RDC interfaces:"
    if [ -d "$RDC_SYSFS_BASE" ]; then
        echo "  sysfs: $RDC_SYSFS_BASE"
        ls -la "$RDC_SYSFS_BASE" 2>/dev/null || echo "    (no files found)"
    fi
    
    if [ -d "$RDC_DEBUGFS_BASE" ]; then
        echo "  debugfs: $RDC_DEBUGFS_BASE"
        ls -la "$RDC_DEBUGFS_BASE" 2>/dev/null || echo "    (no files found)"
    fi
    
    # Show kernel modules
    echo ""
    echo "RDC-related kernel modules:"
    lsmod | grep -i rdc || echo "  (none found)"
    
    # Show dmesg RDC messages
    echo ""
    echo "Recent RDC kernel messages:"
    dmesg | grep -i rdc | tail -10 || echo "  (none found)"
}

# Function to assign UART4 to Linux domain and enable it
assign_uart4_to_linux() {
    log_info "Attempting to assign UART4 to Linux domain and enable it..."
    
    if ! check_rdc_driver; then
        log_error "RDC driver not available"
        return 1
    fi
    
    # Try different methods to assign UART4 to domain 0 (Linux)
    local success=0
    
    # Method 1: sysfs interface
    if [ -f "$RDC_SYSFS_BASE/uart4_domain" ]; then
        echo 0 > "$RDC_SYSFS_BASE/uart4_domain" 2>/dev/null && success=1
        log_info "Attempted sysfs assignment: uart4_domain = 0"
    fi
    
    # Method 2: debugfs interface
    if [ -f "$RDC_DEBUGFS_BASE/uart4" ]; then
        echo "domain=0" > "$RDC_DEBUGFS_BASE/uart4" 2>/dev/null && success=1
        log_info "Attempted debugfs assignment: uart4 domain = 0"
    fi
    
    # Method 3: Direct register access (if available)
    if command -v devmem >/dev/null 2>&1; then
        # This is a placeholder - actual register addresses would need to be determined
        # from the i.MX8MM reference manual
        log_info "Direct register access would require specific RDC register addresses"
    fi
    
    # Method 4: Enable UART4 via device tree overlay or sysfs
    log_info "Attempting to enable UART4 device..."
    
    # Try to enable UART4 via configfs device tree overlay
    if [ -d "/sys/kernel/config/device-tree/overlays" ]; then
        log_info "Device tree overlay support available"
        # This would require a pre-built overlay - placeholder for now
    fi
    
    # Try to bind UART4 driver manually
    if [ -f "/sys/bus/platform/drivers/imx-uart/bind" ]; then
        echo "30a60000.serial" > /sys/bus/platform/drivers/imx-uart/bind 2>/dev/null
        log_info "Attempted to bind UART4 driver to 30a60000.serial"
    fi
    
    # Check if UART4 device node exists
    if [ -c "/dev/ttymxc3" ]; then
        log_info "✓ UART4 device node /dev/ttymxc3 is available"
        success=1
    else
        log_info "UART4 device node /dev/ttymxc3 not yet available"
    fi
    
    if [ $success -eq 1 ]; then
        log_info "UART4 domain assignment and enablement attempted successfully"
        log_info "Check dmesg for confirmation and try accessing /dev/ttymxc3"
        
        # Test UART4 functionality
        if [ -c "/dev/ttymxc3" ]; then
            log_info "Testing UART4 accessibility..."
            if stty -F /dev/ttymxc3 115200 2>/dev/null; then
                log_info "✓ UART4 is accessible and configured"
            else
                log_info "⚠ UART4 device exists but may not be fully functional"
            fi
        fi
    else
        log_error "Could not find RDC control interface for UART4"
        echo "This may indicate:"
        echo "1. RDC driver doesn't support runtime configuration"
        echo "2. UART4 is already assigned correctly"
        echo "3. RDC configuration is handled by ATF/U-Boot only"
        echo "4. Device tree has UART4 disabled (expected with new configuration)"
    fi
}

# Function to show help
show_help() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  status      - Show RDC driver status and available interfaces"
    echo "  uart4       - Assign UART4 to Linux domain and enable it"
    echo "  enable-uart4 - Alias for uart4 command"
    echo "  help        - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 status   - Check if RDC driver is loaded"
    echo "  $0 uart4    - Enable UART4 for Linux use after boot"
    echo "  $0 enable-uart4 - Same as uart4 command"
    echo ""
    echo "Note: UART4 is disabled in device tree to prevent boot failures."
    echo "      Use this script to enable it after the system has booted."
}

# Main function
main() {
    case "${1:-status}" in
        "status")
            show_rdc_status
            ;;
        "uart4"|"enable-uart4")
            assign_uart4_to_linux
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            echo "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
