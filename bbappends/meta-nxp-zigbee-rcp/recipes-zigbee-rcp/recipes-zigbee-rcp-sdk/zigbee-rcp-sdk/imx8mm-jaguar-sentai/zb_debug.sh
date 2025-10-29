#!/bin/bash
# ZBOSS 019.240 Advanced Debug Helper Script
# Provides comprehensive debugging capabilities for Zigbee SPI communication

set -e

SCRIPT_NAME="$(basename "$0")"
ZBOSS_VERSION="019.240"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[${SCRIPT_NAME}]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[${SCRIPT_NAME}]${NC} WARNING: $1"
}

error() {
    echo -e "${RED}[${SCRIPT_NAME}]${NC} ERROR: $1"
}

info() {
    echo -e "${BLUE}[${SCRIPT_NAME}]${NC} INFO: $1"
}

# Function to enable full debug mode
enable_full_debug() {
    log "Enabling full debug mode for ZBOSS ${ZBOSS_VERSION}"
    
    # Update zb_mux.env for full debugging
    sed -i 's/^mux_trace=.*/mux_trace=4:0xffffffff/' /etc/default/zb_mux.env
    sed -i 's/^DUMP_SPI=.*/DUMP_SPI=3/' /etc/default/zb_mux.env
    sed -i 's/^DUMP_SPINEL=.*/DUMP_SPINEL=3/' /etc/default/zb_mux.env
    sed -i 's/^ZB_PERF_MON=.*/ZB_PERF_MON=1/' /etc/default/zb_mux.env
    
    # Update zb_app.env for full debugging
    sed -i 's/^ZB_TRACE_MASK=.*/ZB_TRACE_MASK=0xffffffff/' /etc/default/zb_app.env
    sed -i 's/^DUMP_TTY=.*/DUMP_TTY=3/' /etc/default/zb_app.env
    sed -i 's/^ZB_APP_PERF_MON=.*/ZB_APP_PERF_MON=1/' /etc/default/zb_app.env
    
    log "Full debug mode enabled. Restart services with: systemctl restart zb_mux zb_app"
}

# Function to enable production mode
enable_production_mode() {
    log "Enabling production mode for ZBOSS ${ZBOSS_VERSION}"
    
    # Update zb_mux.env for production
    sed -i 's/^mux_trace=.*/mux_trace=0:0x00000000/' /etc/default/zb_mux.env
    sed -i 's/^DUMP_SPI=.*/DUMP_SPI=0/' /etc/default/zb_mux.env
    sed -i 's/^DUMP_SPINEL=.*/DUMP_SPINEL=0/' /etc/default/zb_mux.env
    sed -i 's/^ZB_PERF_MON=.*/ZB_PERF_MON=0/' /etc/default/zb_mux.env
    
    # Update zb_app.env for production
    sed -i 's/^ZB_TRACE_MASK=.*/ZB_TRACE_MASK=0x00000000/' /etc/default/zb_app.env
    sed -i 's/^DUMP_TTY=.*/DUMP_TTY=0/' /etc/default/zb_app.env
    sed -i 's/^ZB_APP_PERF_MON=.*/ZB_APP_PERF_MON=0/' /etc/default/zb_app.env
    
    log "Production mode enabled. Restart services with: systemctl restart zb_mux zb_app"
}

# Function to show current debug status
show_debug_status() {
    info "Current ZBOSS ${ZBOSS_VERSION} Debug Status:"
    echo
    
    echo "=== ZB_MUX Configuration ==="
    if [ -f /etc/default/zb_mux.env ]; then
        grep -E "^(mux_trace|DUMP_SPI|DUMP_SPINEL|ZB_PERF_MON)" /etc/default/zb_mux.env || true
    else
        warn "zb_mux.env not found"
    fi
    
    echo
    echo "=== ZB_APP Configuration ==="
    if [ -f /etc/default/zb_app.env ]; then
        grep -E "^(ZB_TRACE_MASK|DUMP_TTY|ZB_APP_PERF_MON)" /etc/default/zb_app.env || true
    else
        warn "zb_app.env not found"
    fi
    
    echo
    echo "=== Service Status ==="
    systemctl is-active zb_config.service zb_mux.service zb_app.service 2>/dev/null || true
}

# Function to collect debug information
collect_debug_info() {
    local output_dir="/tmp/zboss_debug_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$output_dir"
    
    log "Collecting ZBOSS ${ZBOSS_VERSION} debug information to: $output_dir"
    
    # System information
    uname -a > "$output_dir/system_info.txt"
    cat /etc/os-release > "$output_dir/os_release.txt"
    
    # ZBOSS configuration
    cp /etc/default/zb_*.env "$output_dir/" 2>/dev/null || true
    
    # Service status
    systemctl status zb_config.service zb_mux.service zb_app.service > "$output_dir/service_status.txt" 2>&1 || true
    
    # Recent logs
    journalctl -u zb_config.service --since "1 hour ago" > "$output_dir/zb_config.log" 2>/dev/null || true
    journalctl -u zb_mux.service --since "1 hour ago" > "$output_dir/zb_mux.log" 2>/dev/null || true
    journalctl -u zb_app.service --since "1 hour ago" > "$output_dir/zb_app.log" 2>/dev/null || true
    
    # Hardware information
    ls -la /dev/spidev* > "$output_dir/spi_devices.txt" 2>/dev/null || true
    ls -la /dev/gpiochip* > "$output_dir/gpio_devices.txt" 2>/dev/null || true
    
    # Process information
    ps aux | grep -E "(zb_|zboss)" > "$output_dir/zboss_processes.txt" || true
    
    # Network information
    if [ -e /tmp/ttyZigbee ]; then
        ls -la /tmp/ttyZigbee > "$output_dir/spinel_interface.txt"
    fi
    
    log "Debug information collected in: $output_dir"
    log "Archive with: tar -czf zboss_debug.tar.gz -C /tmp $(basename $output_dir)"
}

# Function to test SPI communication
test_spi_communication() {
    log "Testing SPI communication for ZBOSS ${ZBOSS_VERSION}"
    
    if [ ! -e /dev/spidev3.0 ]; then
        error "SPI device /dev/spidev3.0 not found"
        return 1
    fi
    
    # Test basic SPI communication
    if command -v spidev_test >/dev/null 2>&1; then
        info "Running SPI loopback test..."
        spidev_test -D /dev/spidev3.0 -s 1000000 -b 8 || warn "SPI test failed"
    else
        warn "spidev_test not available"
    fi
    
    # Check GPIO access
    info "Checking GPIO access..."
    if command -v gpioget >/dev/null 2>&1; then
        gpioget /dev/gpiochip3 22 >/dev/null 2>&1 && log "GPIO interrupt line accessible" || warn "GPIO interrupt line not accessible"
        gpioget /dev/gpiochip1 11 >/dev/null 2>&1 && log "GPIO reset line accessible" || warn "GPIO reset line not accessible"
    else
        warn "gpioget not available"
    fi
}

# Function to show help
show_help() {
    echo "ZBOSS ${ZBOSS_VERSION} Debug Helper Script"
    echo
    echo "Usage: $SCRIPT_NAME [COMMAND]"
    echo
    echo "Commands:"
    echo "  debug-on      Enable full debug mode"
    echo "  debug-off     Enable production mode (disable debug)"
    echo "  status        Show current debug configuration"
    echo "  collect       Collect debug information"
    echo "  test-spi      Test SPI communication"
    echo "  help          Show this help message"
    echo
    echo "Examples:"
    echo "  $SCRIPT_NAME debug-on    # Enable full debugging"
    echo "  $SCRIPT_NAME status      # Check current configuration"
    echo "  $SCRIPT_NAME collect     # Collect debug logs"
}

# Main script logic
case "${1:-help}" in
    debug-on|enable-debug|full-debug)
        enable_full_debug
        ;;
    debug-off|disable-debug|production)
        enable_production_mode
        ;;
    status|show|config)
        show_debug_status
        ;;
    collect|gather|dump)
        collect_debug_info
        ;;
    test-spi|spi-test|test)
        test_spi_communication
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        error "Unknown command: $1"
        echo
        show_help
        exit 1
        ;;
esac
