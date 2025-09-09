#!/bin/bash
# Test E-Ink Demo Application on Target Board
# Deploys and runs el133uf1_demo with proper hardware configuration

set -euo pipefail

# Configuration
TARGET_IP="${TARGET_IP:-192.168.0.36}"
TARGET_USER="${TARGET_USER:-fio}"
MACHINE="${MACHINE:-imx93-jaguar-eink}"
BUILD_DIR="build"

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

# Help function
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Test E-Ink Demo Application on Target Board

OPTIONS:
    -t, --target IP     Target board IP address (default: $TARGET_IP)
    -u, --user USER     SSH user (default: $TARGET_USER)
    -m, --machine MACHINE  Machine type (default: $MACHINE)
    --setup-ssh         Setup SSH keys and passwordless sudo
    --hardware-check    Check hardware configuration only
    --demo-only         Run demo application only (skip deployment)
    -h, --help          Show this help message

EXAMPLES:
    # Deploy and run demo with default settings
    $0

    # Use custom target IP
    $0 --target 192.168.1.100

    # Setup SSH access first
    $0 --setup-ssh

    # Check hardware configuration
    $0 --hardware-check

    # Run demo only (assume binary already deployed)
    $0 --demo-only

HARDWARE CONFIGURATION (i.MX93 Jaguar EInk):
    SPI Device: /dev/spidev0.0 (LPSPI1)
    Reset GPIO: 558 (GPIO2_IO14)
    Busy GPIO:  561 (GPIO2_IO17)
    DC GPIO:    559 (GPIO2_IO15)
    L/R GPIO:   560 (GPIO2_IO16)
    Power GPIO: 555 (GPIO2_IO11)

EOF
}

# Parse command line arguments
SETUP_SSH=false
HARDWARE_CHECK=false
DEMO_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--target)
            TARGET_IP="$2"
            shift 2
            ;;
        -u|--user)
            TARGET_USER="$2"
            shift 2
            ;;
        -m|--machine)
            MACHINE="$2"
            shift 2
            ;;
        --setup-ssh)
            SETUP_SSH=true
            shift
            ;;
        --hardware-check)
            HARDWARE_CHECK=true
            shift
            ;;
        --demo-only)
            DEMO_ONLY=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# SSH setup function
setup_ssh() {
    log_info "Setting up SSH access to target board..."
    
    # Copy SSH public key
    log_info "Copying SSH public key to target..."
    if ssh-copy-id -f "${TARGET_USER}@${TARGET_IP}"; then
        log_success "SSH key copied successfully"
    else
        log_error "Failed to copy SSH key"
        return 1
    fi
    
    # Setup passwordless sudo
    log_info "Configuring passwordless sudo for ${TARGET_USER}..."
    if ssh "${TARGET_USER}@${TARGET_IP}" "echo '${TARGET_USER}' | sudo -S sh -c 'echo \"${TARGET_USER} ALL=(ALL) NOPASSWD: ALL\" > /etc/sudoers.d/${TARGET_USER}'"; then
        log_success "Passwordless sudo configured"
    else
        log_error "Failed to configure passwordless sudo"
        return 1
    fi
    
    log_success "SSH setup completed"
}

# Hardware check function
check_hardware() {
    log_info "Checking hardware configuration on target board..."
    
    # Check SPI device
    log_info "Checking SPI device..."
    if ssh "${TARGET_USER}@${TARGET_IP}" "ls -la /dev/spidev0.0" 2>/dev/null; then
        log_success "SPI device /dev/spidev0.0 found"
    else
        log_error "SPI device /dev/spidev0.0 not found"
        return 1
    fi
    
    # Check GPIO sysfs
    log_info "Checking GPIO sysfs interface..."
    if ssh "${TARGET_USER}@${TARGET_IP}" "ls -la /sys/class/gpio/" 2>/dev/null; then
        log_success "GPIO sysfs interface available"
    else
        log_error "GPIO sysfs interface not available"
        return 1
    fi
    
    # Check if demo binary exists
    log_info "Checking for demo binary on target..."
    if ssh "${TARGET_USER}@${TARGET_IP}" "which el133uf1_demo" 2>/dev/null; then
        log_success "el133uf1_demo binary found in PATH"
    else
        log_warning "el133uf1_demo binary not found in PATH (will deploy from build)"
    fi
    
    # Check if test binary exists
    log_info "Checking for test binary on target..."
    if ssh "${TARGET_USER}@${TARGET_IP}" "which el133uf1_test" 2>/dev/null; then
        log_success "el133uf1_test binary found in PATH"
    else
        log_warning "el133uf1_test binary not found in PATH (will deploy from build)"
    fi
    
    log_success "Hardware check completed"
}

# Find and deploy demo binary
deploy_demo() {
    log_info "Deploying demo application to target board..."
    
    # Find the demo binary in build output
    local demo_binary=""
    local search_paths=(
        "${BUILD_DIR}/tmp/work/cortexa55-lmp-linux/eink-spectra6/*/image/usr/bin/el133uf1_demo"
        "${BUILD_DIR}/tmp/deploy/images/${MACHINE}/el133uf1_demo"
    )
    
    for path in "${search_paths[@]}"; do
        if ls $path 2>/dev/null; then
            demo_binary=$(ls $path | head -1)
            break
        fi
    done
    
    if [[ -z "$demo_binary" ]]; then
        log_error "Demo binary not found in build output"
        log_info "Please build the eink-spectra6 recipe first:"
        log_info "  KAS_MACHINE=${MACHINE} kas shell kas/lmp-dynamicdevices.yml -c 'bitbake eink-spectra6'"
        return 1
    fi
    
    log_info "Found demo binary: $demo_binary"
    
    # Verify binary architecture
    if file "$demo_binary" | grep -q "ARM aarch64"; then
        log_success "Binary architecture verified: ARM aarch64"
    else
        log_error "Binary architecture mismatch - not ARM aarch64"
        file "$demo_binary"
        return 1
    fi
    
    # Deploy to target
    log_info "Copying demo binary to target..."
    if scp "$demo_binary" "${TARGET_USER}@${TARGET_IP}:/tmp/el133uf1_demo"; then
        log_success "Demo binary deployed to /tmp/el133uf1_demo"
    else
        log_error "Failed to deploy demo binary"
        return 1
    fi
    
    # Make executable
    if ssh "${TARGET_USER}@${TARGET_IP}" "chmod +x /tmp/el133uf1_demo"; then
        log_success "Demo binary made executable"
    else
        log_error "Failed to make demo binary executable"
        return 1
    fi
}

# Run demo application
run_demo() {
    log_info "Running E-Ink demo application on target board..."
    
    # E-Ink hardware configuration for i.MX93 Jaguar EInk
    local spi_device="/dev/spidev0.0"
    local reset_gpio="558"
    local busy_gpio="561"
    local dc_gpio="559"
    local lr_gpio="560"
    local power_gpio="555"
    
    log_info "Hardware configuration:"
    log_info "  SPI Device: $spi_device"
    log_info "  Reset GPIO: $reset_gpio (GPIO2_IO14)"
    log_info "  Busy GPIO:  $busy_gpio (GPIO2_IO17)"
    log_info "  DC GPIO:    $dc_gpio (GPIO2_IO15)"
    log_info "  L/R GPIO:   $lr_gpio (GPIO2_IO16)"
    log_info "  Power GPIO: $power_gpio (GPIO2_IO11)"
    
    # Enable display power first
    log_info "Enabling display power..."
    ssh "${TARGET_USER}@${TARGET_IP}" "
        echo $power_gpio | sudo tee /sys/class/gpio/export 2>/dev/null || true
        echo out | sudo tee /sys/class/gpio/gpio${power_gpio}/direction
        echo 1 | sudo tee /sys/class/gpio/gpio${power_gpio}/value
        sleep 1
    "
    
    # Test basic SPI communication first
    log_info "Testing SPI communication..."
    if ssh "${TARGET_USER}@${TARGET_IP}" "cd /tmp && sudo ./el133uf1_demo -d $spi_device -r $reset_gpio -b $busy_gpio -0 $dc_gpio -1 $lr_gpio --test-spi" 2>&1; then
        log_success "SPI communication test passed"
    else
        log_warning "SPI communication test failed - continuing with demo"
    fi
    
    # Run demo with white screen
    log_info "Running demo application (white screen)..."
    if ssh "${TARGET_USER}@${TARGET_IP}" "cd /tmp && sudo ./el133uf1_demo -d $spi_device -r $reset_gpio -b $busy_gpio -0 $dc_gpio -1 $lr_gpio white" 2>&1; then
        log_success "Demo application completed successfully"
    else
        log_error "Demo application failed"
        return 1
    fi
    
    # Try other demo patterns
    log_info "Testing additional demo patterns..."
    
    local patterns=("black" "test" "clear")
    for pattern in "${patterns[@]}"; do
        log_info "Running demo with pattern: $pattern"
        if ssh "${TARGET_USER}@${TARGET_IP}" "cd /tmp && sudo ./el133uf1_demo -d $spi_device -r $reset_gpio -b $busy_gpio -0 $dc_gpio -1 $lr_gpio $pattern" 2>&1; then
            log_success "Demo pattern '$pattern' completed"
        else
            log_warning "Demo pattern '$pattern' failed"
        fi
        sleep 2  # Brief pause between patterns
    done
}

# Main execution
main() {
    log_info "E-Ink Demo Application Target Test"
    log_info "Target: ${TARGET_USER}@${TARGET_IP}"
    log_info "Machine: ${MACHINE}"
    echo
    
    # Setup SSH if requested
    if [[ "$SETUP_SSH" == true ]]; then
        setup_ssh
        echo
    fi
    
    # Hardware check if requested or as part of full test
    if [[ "$HARDWARE_CHECK" == true ]] || [[ "$DEMO_ONLY" == false ]]; then
        check_hardware
        echo
    fi
    
    # Exit if only hardware check requested
    if [[ "$HARDWARE_CHECK" == true ]]; then
        log_success "Hardware check completed successfully"
        exit 0
    fi
    
    # Deploy demo if not demo-only mode
    if [[ "$DEMO_ONLY" == false ]]; then
        deploy_demo
        echo
    fi
    
    # Run the demo
    run_demo
    echo
    
    log_success "E-Ink demo test completed successfully!"
    log_info "The demo application should have displayed patterns on the E-Ink display"
    log_info "Check the display for visual confirmation of the demo patterns"
}

# Run main function
main "$@"
