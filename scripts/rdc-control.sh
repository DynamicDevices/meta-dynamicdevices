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

# Function to assign UART4 to Linux domain
assign_uart4_to_linux() {
    log_info "Attempting to assign UART4 to Linux domain..."
    
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
    
    if [ $success -eq 1 ]; then
        log_info "UART4 domain assignment attempted successfully"
        log_info "Check dmesg for confirmation and try accessing /dev/ttymxc3"
    else
        log_error "Could not find RDC control interface for UART4"
        echo "This may indicate:"
        echo "1. RDC driver doesn't support runtime configuration"
        echo "2. UART4 is already assigned correctly"
        echo "3. RDC configuration is handled by ATF/U-Boot only"
    fi
}

# Function to show help
show_help() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  status      - Show RDC driver status and available interfaces"
    echo "  uart4       - Assign UART4 to Linux domain (domain 0)"
    echo "  help        - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 status   - Check if RDC driver is loaded"
    echo "  $0 uart4    - Try to assign UART4 to Linux"
}

# Main function
main() {
    case "${1:-status}" in
        "status")
            show_rdc_status
            ;;
        "uart4")
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
