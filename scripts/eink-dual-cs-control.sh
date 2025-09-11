#!/bin/bash
# SPDX-License-Identifier: GPL-2.0+
# E-Ink Dual Chip Select Control
# Handles CS0 and CS1 GPIO control for left/right display halves

set -euo pipefail

# GPIO mappings for i.MX93 E-Ink board
CS0_GPIO=529    # GPIO2_IO17 (512 + 17) - Left half
CS1_GPIO=619    # GPIO1_IO11 (608 + 11) - Right half

# Colors for output
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

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Initialize CS GPIOs
init_cs_gpios() {
    log_info "Initializing E-Ink CS GPIOs..."
    
    # Export GPIOs if not already exported
    for gpio in $CS0_GPIO $CS1_GPIO; do
        if [ ! -d "/sys/class/gpio/gpio$gpio" ]; then
            echo $gpio | sudo tee /sys/class/gpio/export >/dev/null 2>&1 || {
                log_error "Failed to export GPIO $gpio"
                return 1
            }
        fi
    done
    
    # Set both as outputs
    echo out | sudo tee /sys/class/gpio/gpio${CS0_GPIO}/direction >/dev/null || {
        log_error "Failed to set CS0 (GPIO $CS0_GPIO) as output"
        return 1
    }
    
    echo out | sudo tee /sys/class/gpio/gpio${CS1_GPIO}/direction >/dev/null || {
        log_error "Failed to set CS1 (GPIO $CS1_GPIO) as output"
        return 1
    }
    
    # Set both HIGH (inactive - not selected) initially
    echo 1 | sudo tee /sys/class/gpio/gpio${CS0_GPIO}/value >/dev/null
    echo 1 | sudo tee /sys/class/gpio/gpio${CS1_GPIO}/value >/dev/null
    
    log_success "CS GPIOs initialized - both deselected (HIGH)"
}

# Select left half (CS0 active, CS1 inactive)
select_left() {
    log_info "Selecting left display half (CS0 active)"
    
    echo 0 | sudo tee /sys/class/gpio/gpio${CS0_GPIO}/value >/dev/null  # CS0 LOW (active)
    echo 1 | sudo tee /sys/class/gpio/gpio${CS1_GPIO}/value >/dev/null  # CS1 HIGH (inactive)
    
    # Verify the selection
    cs0_val=$(cat /sys/class/gpio/gpio${CS0_GPIO}/value)
    cs1_val=$(cat /sys/class/gpio/gpio${CS1_GPIO}/value)
    
    if [ "$cs0_val" = "0" ] && [ "$cs1_val" = "1" ]; then
        log_success "Left half selected (CS0=$cs0_val, CS1=$cs1_val)"
        return 0
    else
        log_error "Failed to select left half (CS0=$cs0_val, CS1=$cs1_val)"
        return 1
    fi
}

# Select right half (CS0 inactive, CS1 active)
select_right() {
    log_info "Selecting right display half (CS1 active)"
    
    echo 1 | sudo tee /sys/class/gpio/gpio${CS0_GPIO}/value >/dev/null  # CS0 HIGH (inactive)
    echo 0 | sudo tee /sys/class/gpio/gpio${CS1_GPIO}/value >/dev/null  # CS1 LOW (active)
    
    # Verify the selection
    cs0_val=$(cat /sys/class/gpio/gpio${CS0_GPIO}/value)
    cs1_val=$(cat /sys/class/gpio/gpio${CS1_GPIO}/value)
    
    if [ "$cs0_val" = "1" ] && [ "$cs1_val" = "0" ]; then
        log_success "Right half selected (CS0=$cs0_val, CS1=$cs1_val)"
        return 0
    else
        log_error "Failed to select right half (CS0=$cs0_val, CS1=$cs1_val)"
        return 1
    fi
}

# Deselect both halves (both CS lines HIGH)
deselect_all() {
    log_info "Deselecting both display halves"
    
    echo 1 | sudo tee /sys/class/gpio/gpio${CS0_GPIO}/value >/dev/null  # CS0 HIGH (inactive)
    echo 1 | sudo tee /sys/class/gpio/gpio${CS1_GPIO}/value >/dev/null  # CS1 HIGH (inactive)
    
    # Verify deselection
    cs0_val=$(cat /sys/class/gpio/gpio${CS0_GPIO}/value)
    cs1_val=$(cat /sys/class/gpio/gpio${CS1_GPIO}/value)
    
    if [ "$cs0_val" = "1" ] && [ "$cs1_val" = "1" ]; then
        log_success "Both halves deselected (CS0=$cs0_val, CS1=$cs1_val)"
        return 0
    else
        log_error "Failed to deselect both halves (CS0=$cs0_val, CS1=$cs1_val)"
        return 1
    fi
}

# Get current CS status
get_cs_status() {
    if [ ! -d "/sys/class/gpio/gpio${CS0_GPIO}" ] || [ ! -d "/sys/class/gpio/gpio${CS1_GPIO}" ]; then
        log_warning "CS GPIOs not initialized"
        return 1
    fi
    
    cs0_val=$(cat /sys/class/gpio/gpio${CS0_GPIO}/value)
    cs1_val=$(cat /sys/class/gpio/gpio${CS1_GPIO}/value)
    
    echo "CS Status: CS0=$cs0_val, CS1=$cs1_val"
    
    if [ "$cs0_val" = "0" ] && [ "$cs1_val" = "1" ]; then
        echo "Active: Left half (CS0)"
    elif [ "$cs0_val" = "1" ] && [ "$cs1_val" = "0" ]; then
        echo "Active: Right half (CS1)"
    elif [ "$cs0_val" = "1" ] && [ "$cs1_val" = "1" ]; then
        echo "Active: None (both deselected)"
    else
        echo "ERROR: Invalid state (both selected)"
    fi
}

# Test CS functionality
test_cs_switching() {
    log_info "Testing CS switching functionality..."
    
    # Initialize
    if ! init_cs_gpios; then
        return 1
    fi
    
    # Test deselect all
    log_info "=== Testing deselect all ==="
    if ! deselect_all; then
        return 1
    fi
    sleep 1
    
    # Test left selection
    log_info "=== Testing left half selection ==="
    if ! select_left; then
        return 1
    fi
    sleep 1
    
    # Test right selection
    log_info "=== Testing right half selection ==="
    if ! select_right; then
        return 1
    fi
    sleep 1
    
    # Test rapid switching
    log_info "=== Testing rapid switching ==="
    for i in {1..5}; do
        log_info "Switch cycle $i/5"
        select_left
        sleep 0.1
        select_right
        sleep 0.1
    done
    
    # Return to deselected state
    deselect_all
    
    log_success "CS switching test completed successfully!"
}

# Cleanup function
cleanup_cs_gpios() {
    log_info "Cleaning up CS GPIO exports..."
    
    # Deselect both before cleanup
    if [ -d "/sys/class/gpio/gpio${CS0_GPIO}" ] && [ -d "/sys/class/gpio/gpio${CS1_GPIO}" ]; then
        deselect_all 2>/dev/null || true
    fi
    
    # Unexport GPIOs
    for gpio in $CS0_GPIO $CS1_GPIO; do
        if [ -d "/sys/class/gpio/gpio$gpio" ]; then
            echo $gpio | sudo tee /sys/class/gpio/unexport >/dev/null 2>&1 || true
        fi
    done
    
    log_success "CS GPIO cleanup completed"
}

# Set up cleanup trap
trap cleanup_cs_gpios EXIT

# Main function
main() {
    case "${1:-}" in
        "init")
            init_cs_gpios
            ;;
        "left")
            init_cs_gpios && select_left
            ;;
        "right")
            init_cs_gpios && select_right
            ;;
        "deselect"|"none")
            init_cs_gpios && deselect_all
            ;;
        "status")
            get_cs_status
            ;;
        "test")
            test_cs_switching
            ;;
        "cleanup")
            cleanup_cs_gpios
            ;;
        *)
            echo "Usage: $0 {init|left|right|deselect|status|test|cleanup}"
            echo ""
            echo "Commands:"
            echo "  init      - Initialize CS GPIOs (both deselected)"
            echo "  left      - Select left display half (CS0 active)"
            echo "  right     - Select right display half (CS1 active)"
            echo "  deselect  - Deselect both halves (both inactive)"
            echo "  status    - Show current CS status"
            echo "  test      - Run comprehensive CS switching test"
            echo "  cleanup   - Clean up GPIO exports"
            echo ""
            echo "GPIO Mappings:"
            echo "  CS0 (Left):  GPIO $CS0_GPIO (GPIO2_IO17)"
            echo "  CS1 (Right): GPIO $CS1_GPIO (GPIO1_IO11)"
            echo ""
            echo "CS Logic: Active LOW (0=selected, 1=deselected)"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
