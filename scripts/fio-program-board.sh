#!/bin/bash

#
# Foundries.io Board Programming Tool for Dynamic Devices
#
# Copyright (c) 2024 Dynamic Devices Ltd.
# Licensed under the GNU General Public License v3.0
#
# This script downloads target build files from Foundries.io and optionally
# programs Dynamic Devices boards using fioctl and UUU manufacturing tools.
#
# Author: Dynamic Devices Engineering Team
# Version: 2.0.0
# Repository: https://github.com/dynamic-devices/meta-dynamicdevices
#
# CHANGELOG:
# v2.0.0 (2024-12-19)
#   - Added comprehensive timing for download performance tracking
#   - Added programming time tracking when using --program flag
#   - Added --program flag for automatic board programming after download
#   - Added intelligent caching to avoid re-downloading existing files
#   - Added --force flag to override caching when needed
#   - Added automatic latest target selection when no target specified
#   - Added support for fioctl default factory configuration
#   - Fixed i.MX93 bootloader size issue by using correct MFGTools bootloader
#   - Improved error handling and user feedback
#   - Enhanced logging with color-coded output
#   - Added configuration management for factory/machine defaults
#
# v1.0.0 (2024-12-18)
#   - Initial release with basic download functionality
#   - Support for imx8mm-jaguar-sentai, imx93-jaguar-eink, imx8mm-jaguar-phasora
#   - Automatic MFGTools extraction and programming script generation
#   - fioctl authentication and factory validation
#   - Comprehensive artifact downloading (bootloader, U-Boot, DTB, system image, manifest)
#
# Requirements:
#   - fioctl installed and authenticated (run 'fioctl login' first)
#   - Factory access configured
#   - Valid target number and machine name
#   - sudo access for board programming (when using --program)
#

set -euo pipefail

# Script configuration
SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="2.0.0"
# shellcheck disable=SC2034  # Used in generated programming script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Timing functions
start_timer() {
    TIMER_START=$(date +%s)
}

end_timer() {
    local timer_end
    timer_end=$(date +%s)
    local duration=$((timer_end - TIMER_START))
    echo "$duration"
}

format_duration() {
    local seconds="$1"
    if [[ $seconds -lt 60 ]]; then
        echo "${seconds}s"
    elif [[ $seconds -lt 3600 ]]; then
        local minutes=$((seconds / 60))
        local remaining_seconds=$((seconds % 60))
        echo "${minutes}m ${remaining_seconds}s"
    else
        local hours=$((seconds / 3600))
        local remaining_minutes=$(((seconds % 3600) / 60))
        local remaining_seconds=$((seconds % 60))
        echo "${hours}h ${remaining_minutes}m ${remaining_seconds}s"
    fi
}

# Configuration file path
CONFIG_FILE="$HOME/.config/dd-target-downloader.conf"

# Install fioctl from GitHub releases
install_fioctl_from_github() {
    local arch
    local os
    local download_url
    local temp_file
    local install_path
    
    log_info "Installing fioctl from GitHub releases..."
    log_info "Source: https://github.com/foundriesio/fioctl/releases"
    
    # Detect architecture and OS
    arch=$(uname -m)
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    
    case "$arch" in
        x86_64|amd64) arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
        armv7l) arch="armv7" ;;
        *) 
            log_error "Unsupported architecture: $arch"
            log_info "Supported architectures: amd64, arm64, armv7"
            return 1
            ;;
    esac
    
    case "$os" in
        linux) os="linux" ;;
        darwin) os="darwin" ;;
        *)
            log_error "Unsupported operating system: $os"
            log_info "Supported platforms: Linux, macOS (Darwin)"
            return 1
            ;;
    esac
    
    download_url="https://github.com/foundriesio/fioctl/releases/latest/download/fioctl-${os}-${arch}"
    temp_file="/tmp/fioctl-${os}-${arch}-$$"
    
    log_info "Downloading fioctl-${os}-${arch}..."
    log_info "URL: $download_url"
    
    # Download using curl or wget
    if command -v curl &> /dev/null; then
        if ! curl -L -f -o "$temp_file" "$download_url"; then
            log_error "Failed to download fioctl using curl"
            return 1
        fi
    elif command -v wget &> /dev/null; then
        if ! wget -O "$temp_file" "$download_url"; then
            log_error "Failed to download fioctl using wget"
            return 1
        fi
    else
        log_error "Neither curl nor wget is available for downloading"
        return 1
    fi
    
    # Verify download
    if [[ ! -f "$temp_file" ]] || [[ ! -s "$temp_file" ]]; then
        log_error "Downloaded file is empty or missing"
        rm -f "$temp_file"
        return 1
    fi
    
    # Make executable
    chmod +x "$temp_file"
    
    # Test the binary works
    if ! "$temp_file" version &> /dev/null; then
        log_error "Downloaded fioctl binary is not working"
        rm -f "$temp_file"
        return 1
    fi
    
    # Try to install to /usr/local/bin (preferred)
    if sudo mv "$temp_file" /usr/local/bin/fioctl 2>/dev/null; then
        install_path="/usr/local/bin/fioctl"
        log_success "fioctl installed to $install_path"
    # Fallback to user's home bin directory
    elif mkdir -p "$HOME/bin" && mv "$temp_file" "$HOME/bin/fioctl"; then
        install_path="$HOME/bin/fioctl"
        log_success "fioctl installed to $install_path"
        
        # Add to PATH if not already there
        if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
            export PATH="$HOME/bin:$PATH"
            log_info "Added $HOME/bin to PATH for this session"
            log_info "Add 'export PATH=\"\$HOME/bin:\$PATH\"' to your ~/.bashrc or ~/.zshrc"
        fi
    else
        log_error "Failed to install fioctl - no write permissions"
        rm -f "$temp_file"
        return 1
    fi
    
    # Verify installation
    if command -v fioctl &> /dev/null; then
        local version
        version=$(fioctl version 2>/dev/null | head -n1 || echo "unknown")
        log_success "fioctl installation verified: $version"
        return 0
    else
        log_error "fioctl installation failed - command not found in PATH"
        return 1
    fi
}

# Comprehensive dependency checking
check_all_dependencies() {
    local missing_deps=0
    local missing_tools=()
    
    # Check critical dependencies silently
    if ! command -v fioctl &> /dev/null; then
        missing_deps=$((missing_deps + 1))
        missing_tools+=("fioctl")
        need_fioctl=1
    fi
    
    # Check curl or wget (needed for downloads)
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        missing_deps=$((missing_deps + 1))
        missing_tools+=("curl or wget")
        need_download_tool=1
    fi
    
    # Check for tar (should be available on most Unix systems)
    if ! command -v tar &> /dev/null; then
        missing_deps=$((missing_deps + 1))
        missing_tools+=("tar")
    fi
    
    # Only show output if there are missing dependencies
    if [[ $missing_deps -gt 0 ]]; then
        log_error "Missing critical dependencies: ${missing_tools[*]}"
        echo ""
        
        if [[ -n "${need_fioctl:-}" ]]; then
            log_info "Would you like to install missing dependencies automatically?"
            read -p "Install dependencies? (y/N): " install_deps
            
            if [[ "$install_deps" =~ ^[Yy]$ ]]; then
                install_missing_dependencies
                if [[ $? -ne 0 ]]; then
                    log_error "Dependency installation failed"
                    return 1
                fi
            else
                log_error "Cannot continue without required dependencies"
                show_dependency_install_instructions
                return 1
            fi
        else
            log_error "Cannot continue without required dependencies"
            show_dependency_install_instructions
            return 1
        fi
    fi
    
    return 0
}

# Install missing dependencies
install_missing_dependencies() {
    log_info "Installing missing dependencies..."
    
    if [[ -n "${need_fioctl:-}" ]]; then
        log_info "Installing fioctl..."
        
        log_info "Installing fioctl from GitHub releases..."
        install_fioctl_from_github
        if [[ $? -ne 0 ]]; then
            return 1
        fi
    fi
    
    if [[ -n "${need_download_tool:-}" ]]; then
        log_info "Installing download tool..."
        
        if command -v apt &> /dev/null; then
            log_info "Using apt to install curl..."
            if sudo apt update && sudo apt install -y curl; then
                log_success "curl installed successfully via apt"
            else
                log_warning "Could not install curl automatically"
            fi
        elif command -v yum &> /dev/null; then
            log_info "Using yum to install curl..."
            if sudo yum install -y curl; then
                log_success "curl installed successfully via yum"
            else
                log_warning "Could not install curl automatically"
            fi
        elif command -v dnf &> /dev/null; then
            log_info "Using dnf to install curl..."
            if sudo dnf install -y curl; then
                log_success "curl installed successfully via dnf"
            else
                log_warning "Could not install curl automatically"
            fi
        elif command -v brew &> /dev/null; then
            log_info "Using Homebrew to install curl..."
            if brew install curl; then
                log_success "curl installed successfully via Homebrew"
            else
                log_warning "Could not install curl automatically"
            fi
        else
            log_warning "Could not install curl automatically (no supported package manager)"
            log_info "Please install curl or wget manually"
        fi
    fi
    
    # Verify installations
    log_info "Verifying installations..."
    
    if ! command -v fioctl &> /dev/null; then
        log_error "fioctl installation verification failed"
        return 1
    else
        log_success "fioctl is now available"
    fi
    
    return 0
}

# Show dependency installation instructions
show_dependency_install_instructions() {
    log_info "=== Manual Installation Instructions ==="
    echo ""
    
    if [[ -n "${need_fioctl:-}" ]]; then
        log_info "fioctl (Required) - Install from GitHub Releases:"
        log_info "  1. Visit: https://github.com/foundriesio/fioctl/releases"
        log_info "  2. Download the appropriate release for your platform:"
        log_info "     - Linux x86_64: fioctl-linux-amd64"
        log_info "     - Linux ARM64: fioctl-linux-arm64"
        log_info "     - macOS Intel: fioctl-darwin-amd64"
        log_info "     - macOS Apple Silicon: fioctl-darwin-arm64"
        log_info "  3. Make executable: chmod +x fioctl-*"
        log_info "  4. Install: sudo mv fioctl-* /usr/local/bin/fioctl"
        log_info "  5. Or install to user directory: mv fioctl-* ~/bin/fioctl"
        echo ""
    fi
    
    if [[ -n "${need_download_tool:-}" ]]; then
        log_info "Download Tool (Required - choose one):"
        log_info "  Option 1: curl - Usually pre-installed, or install via package manager"
        log_info "  Option 2: wget - Install via package manager (apt install wget, yum install wget, etc.)"
        echo ""
    fi
    
    log_info "After installing dependencies, run this script again."
}

# Show manual installation instructions
show_manual_install_instructions() {
    log_info "Manual Installation Instructions:"
    echo ""
    log_info "Method 1: Download from GitHub Releases (Recommended)"
    log_info "  1. Visit: https://github.com/foundriesio/fioctl/releases"
    log_info "  2. Download the appropriate release for your platform:"
    log_info "     - Linux: fioctl-linux-amd64"
    log_info "     - macOS: fioctl-darwin-amd64 (Intel) or fioctl-darwin-arm64 (Apple Silicon)"
    log_info "  3. Make executable: chmod +x fioctl-*"
    log_info "  4. Move to PATH: sudo mv fioctl-* /usr/local/bin/fioctl"
    echo ""
    log_info "Method 2: Using Homebrew (macOS)"
    log_info "  brew install foundriesio/foundries/fioctl"
    echo ""
    log_info "Method 3: Using snap (Linux)"
    log_info "  sudo snap install fioctl"
    echo ""
    log_info "Method 4: Build from source"
    log_info "  git clone https://github.com/foundriesio/fioctl.git"
    log_info "  cd fioctl"
    log_info "  make"
    log_info "  sudo cp bin/fioctl /usr/local/bin/"
    echo ""
    log_info "After installation:"
    log_info "  1. Open a new terminal"
    log_info "  2. Run: fioctl login"
    log_info "  3. Follow the authentication prompts"
    log_info "  4. Run this script again"
    echo ""
    log_info "For more help, visit: https://docs.foundries.io/latest/getting-started/install-fioctl/"
}

# Helper function to call fioctl with correct factory parameter
fioctl_with_factory() {
    local factory="$1"
    shift  # Remove factory from arguments
    
    if [[ "$factory" == "<default>" ]]; then
        # Use fioctl without --factory flag (uses default from config)
        fioctl "$@"
    else
        # Use fioctl with explicit --factory flag
        fioctl "$@" --factory "$factory"
    fi
}

# Default configuration
DEFAULT_FACTORY=""
DEFAULT_MACHINE=""

# Load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # shellcheck source=/dev/null
        source "$CONFIG_FILE"
    fi
}

# Save configuration
save_config() {
    local factory="$1"
    local machine="$2"
    
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << EOF
# Dynamic Devices Target Downloader Configuration
# This file is automatically generated and updated

# Default factory name (can be overridden with --factory)
DEFAULT_FACTORY="$factory"

# Default machine name (can be overridden with --machine or positional argument)
DEFAULT_MACHINE="$machine"

# Last updated: $(date)
EOF
    log_info "Configuration saved to $CONFIG_FILE"
}

# Version function
show_version() {
    cat << EOF
$SCRIPT_NAME version $SCRIPT_VERSION

Foundries.io Board Programming Tool for Dynamic Devices
Copyright (c) 2024 Dynamic Devices Ltd.
Licensed under the GNU General Public License v3.0

Repository: https://github.com/dynamic-devices/meta-dynamicdevices
EOF
}

# Usage function
usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS] [target-number] [machine] [output-dir]

Download target build files from Foundries.io and program Dynamic Devices boards.

Arguments:
  target-number    Target number from Foundries.io CI (optional - uses latest if not specified)
  machine          Machine name (optional if --machine or default configured)
  output-dir       Output directory (default: ./downloads/target-<number>-<machine>)

Options:
  -f, --factory FACTORY     Foundries.io factory name (required unless configured)
  -m, --machine MACHINE     Machine/hardware type to download
  -o, --output DIR          Output directory
  -l, --list-targets        List available targets and exit
  -c, --configure           Interactive configuration setup
  --force                   Force re-download even if files exist locally
  --program                 Automatically run programming script after download
  --continuous              Continuous programming mode for multiple boards
  -v, --version            Show version information
  -h, --help               Show this help message

Supported Machines:
  - imx8mm-jaguar-sentai  (Edge AI Board)
  - imx93-jaguar-eink     (Edge EInk Board)
  - imx8mm-jaguar-phasora (Edge EV Board)
  - imx8mm-jaguar-inst    (Edge GW Board)
  - imx93-11x11-lpddr4x-evk (NXP EVK)

Examples:
  # First time setup (interactive configuration)
  $SCRIPT_NAME --configure

  # Download with explicit factory and machine
  $SCRIPT_NAME --factory my-factory --machine imx8mm-jaguar-sentai 1451

  # Use configured defaults (factory and machine)
  $SCRIPT_NAME 1451

  # Use configured factory, specify machine
  $SCRIPT_NAME --machine imx93-jaguar-eink 1451

  # Use latest target (no target number specified)
  $SCRIPT_NAME --machine imx93-jaguar-eink

  # Force re-download even if files exist
  $SCRIPT_NAME --factory my-factory --machine imx93-jaguar-eink 1451 --force

  # Download and automatically program board
  $SCRIPT_NAME --factory my-factory --machine imx93-jaguar-eink 1451 --program

  # Continuous programming mode for multiple boards
  $SCRIPT_NAME --machine imx93-jaguar-eink --continuous

  # List available targets
  $SCRIPT_NAME --factory my-factory --list-targets

Requirements:
  - fioctl installed and authenticated (run 'fioctl login' first)
  - Access to the Foundries.io factory
  - Valid target number (check with 'fioctl targets list')

Configuration:
  The script saves factory and machine defaults to: $CONFIG_FILE
  Use --configure to set up defaults interactively.

The script downloads the following artifacts needed for board programming:
  - lmp-factory-image-<machine>.wic.gz  (Main system image)
  - imx-boot-<machine>                  (Production bootloader)
  - u-boot-<machine>.itb                (Production U-Boot image)
  - Complete MFGTools package with UUU executables and programming scripts
  - <machine>.dtb                       (Device tree blob, if available)

Programming Usage:
  1. Put board in download/recovery mode
  2. Connect USB cable
  3. sudo ./program-<machine>.sh --flash

EOF
}

# Interactive configuration setup
configure_interactive() {
    log_info "Interactive Configuration Setup"
    echo
    
    # Load existing config
    load_config
    
    # Get factory name
    local factory="$DEFAULT_FACTORY"
    echo -n "Enter Foundries.io factory name"
    if [[ -n "$DEFAULT_FACTORY" ]]; then
        echo -n " (current: $DEFAULT_FACTORY)"
    fi
    echo -n ": "
    read -r input_factory
    if [[ -n "$input_factory" ]]; then
        factory="$input_factory"
    fi
    
    if [[ -z "$factory" ]]; then
        log_error "Factory name is required"
        return 1
    fi
    
    # Test factory access
    log_info "Testing factory access..."
    if ! fioctl targets list --factory "$factory" &>/dev/null; then
        log_error "Cannot access factory '$factory'. Check factory name and permissions."
        return 1
    fi
    log_success "Factory '$factory' is accessible"
    
    # Get machine name
    local machine="$DEFAULT_MACHINE"
    echo
    echo "Supported machines:"
    echo "  1) imx8mm-jaguar-sentai  (Edge AI Board)"
    echo "  2) imx93-jaguar-eink     (Edge EInk Board)"
    echo "  3) imx8mm-jaguar-phasora (Edge EV Board)"
    echo "  4) imx8mm-jaguar-inst    (Edge GW Board)"
    echo "  5) imx93-11x11-lpddr4x-evk (NXP EVK)"
    echo "  6) Custom machine name"
    echo
    echo -n "Select default machine (1-6)"
    if [[ -n "$DEFAULT_MACHINE" ]]; then
        echo -n " (current: $DEFAULT_MACHINE)"
    fi
    echo -n ": "
    read -r machine_choice
    
    case "$machine_choice" in
        1) machine="imx8mm-jaguar-sentai" ;;
        2) machine="imx93-jaguar-eink" ;;
        3) machine="imx8mm-jaguar-phasora" ;;
        4) machine="imx8mm-jaguar-inst" ;;
        5) machine="imx93-11x11-lpddr4x-evk" ;;
        6) 
            echo -n "Enter custom machine name: "
            read -r custom_machine
            if [[ -n "$custom_machine" ]]; then
                machine="$custom_machine"
            fi
            ;;
        "")
            # Keep existing default
            ;;
        *)
            log_error "Invalid selection"
            return 1
            ;;
    esac
    
    if [[ -z "$machine" ]]; then
        log_warn "No default machine configured"
        machine=""
    fi
    
    # Save configuration
    save_config "$factory" "$machine"
    
    echo
    log_success "Configuration completed!"
    log_info "Factory: $factory"
    log_info "Default machine: ${machine:-"(none - specify with --machine or as argument)"}"
    echo
    log_info "You can now run: $SCRIPT_NAME <target-number>"
    return 0
}

# List available targets
list_targets() {
    local factory="$1"
    
    if [[ -z "$factory" ]]; then
        log_error "Factory name required for listing targets"
        log_info "Use: $SCRIPT_NAME --factory <factory-name> --list-targets"
        return 1
    fi
    
    log_info "Listing targets for factory: $factory"
    echo
    
    if ! fioctl_with_factory "$factory" targets list; then
        log_error "Failed to list targets for factory '$factory'"
        return 1
    fi
    
    return 0
}

# Validate fioctl installation and authentication
check_fioctl() {
    local factory="$1"
    
    if ! command -v fioctl &> /dev/null; then
        log_error "fioctl is not installed or not in PATH"
        echo ""
        log_info "=== fioctl Installation ==="
        echo ""
        log_info "fioctl is required to download Foundries.io target artifacts."
        echo ""
        read -p "Would you like to install fioctl automatically? (y/N): " install_fioctl
        
        if [[ "$install_fioctl" =~ ^[Yy]$ ]]; then
            log_info "Installing fioctl..."
            
            # Detect platform and install accordingly
            if command -v brew &> /dev/null; then
                log_info "Using Homebrew to install fioctl..."
                if brew install foundriesio/foundries/fioctl; then
                    log_success "fioctl installed successfully via Homebrew"
                else
                    log_warning "Homebrew installation failed, trying manual installation..."
                    install_fioctl_manual
                fi
            elif command -v snap &> /dev/null; then
                log_info "Using snap to install fioctl..."
                if sudo snap install fioctl; then
                    log_success "fioctl installed successfully via snap"
                else
                    log_warning "Snap installation failed, trying manual installation..."
                    install_fioctl_manual
                fi
            else
                log_info "No package manager found, using manual installation..."
                install_fioctl_manual
            fi
            
            # Verify installation
            if command -v fioctl &> /dev/null; then
                log_success "fioctl is now available!"
                log_info "Next step: Run 'fioctl login' to authenticate"
                return 0
            else
                log_error "Installation failed. Please install manually."
                show_manual_install_instructions
                return 1
            fi
        else
            show_manual_install_instructions
            return 1
        fi
    fi

    local version
    version=$(fioctl version 2>/dev/null | head -n1 || echo "unknown")
    log_info "Using fioctl version: $version"

    # Check if fioctl is authenticated by checking config
    if ! fioctl config --help &>/dev/null; then
        log_error "fioctl command failed - may not be properly installed"
        return 1
    fi
    
    # Check if fioctl has valid authentication
    log_info "Checking fioctl authentication..."
    
    # Check if config file exists and has credentials
    local config_file="$HOME/.config/fioctl.yaml"
    if [[ ! -f "$config_file" ]]; then
        log_error "fioctl configuration not found"
        echo
        log_info "To authenticate fioctl:"
        log_info "  1. Visit: https://app.foundries.io/settings/tokens/"
        log_info "  2. Create a new API token"
        log_info "  3. Run: fioctl login"
        log_info "  4. Enter your token when prompted"
        return 1
    fi
    
    # Test authentication with factory access if provided
    if [[ -n "$factory" && "$factory" != "<default>" ]]; then
        log_info "Testing factory access: $factory"
        if ! fioctl targets list --factory "$factory" &>/dev/null; then
            log_error "Cannot access factory '$factory'"
            log_info "Possible issues:"
            log_info "  - Factory name is incorrect"
            log_info "  - No access permissions to this factory"
            log_info "  - fioctl authentication has expired"
            echo
            log_info "To re-authenticate: fioctl login"
            return 1
        fi
        log_success "Factory '$factory' is accessible"
    elif [[ "$factory" == "<default>" ]]; then
        # Test default factory access
        log_info "Testing default factory access..."
        if ! fioctl targets list &>/dev/null; then
            log_error "Cannot access default factory"
            log_info "Possible issues:"
            log_info "  - No default factory configured in ~/.config/fioctl.yaml"
            log_info "  - No access permissions to the default factory"
            log_info "  - fioctl authentication has expired"
            echo
            log_info "To fix:"
            log_info "  1. Set default factory: echo 'factory: your-factory-name' >> ~/.config/fioctl.yaml"
            log_info "  2. Or use --factory <factory-name> explicitly"
            log_info "  3. Re-authenticate: fioctl login"
            return 1
        fi
        log_success "Default factory is accessible"
    else
        # Just check that fioctl config command works (indicates valid auth)
        if ! fioctl config --help &>/dev/null; then
            log_error "fioctl authentication appears to be invalid"
            log_info "Run: fioctl login"
            return 1
        fi
        log_success "fioctl is authenticated"
    fi
    
    return 0
}

# Get the latest target number for a factory and machine
get_latest_target() {
    local factory="$1"
    local machine="$2"
    
    # Get targets list and check only the most recent targets (reverse order for efficiency)
    local latest_target=""
    local latest_created=""
    local targets
    targets=$(fioctl_with_factory "$factory" targets list 2>/dev/null | \
        grep -E "^\s*[0-9]+\s+" | \
        awk '{print $1}' | \
        sort -nr | \
        head -10)  # Check only last 10 targets in reverse order for speed
    
    # Check each target to see if it matches the machine and find the most recent platform target
    for target in $targets; do
        local target_info
        target_info=$(fioctl_with_factory "$factory" targets show "$target" 2>/dev/null | head -15)
        if echo "$target_info" | grep -q "$machine"; then
            # Check if this is a platform target (no "Origin Target" field)
            if ! echo "$target_info" | grep -q "Origin Target:"; then
                # Since we're checking in reverse chronological order, first match is latest
                latest_target="$target"
                break
            fi
        fi
    done
    
    if [[ -n "$latest_target" ]]; then
        echo "$latest_target"
        return 0
    else
        return 1
    fi
}

# Validate target exists
validate_target() {
    local target_number="$1"
    local factory="$2"
    
    log_info "Validating target $target_number exists in factory $factory..."
    
    if ! fioctl_with_factory "$factory" targets show "$target_number" &>/dev/null; then
        log_error "Target $target_number not found in factory $factory"
        if [[ "$factory" == "<default>" ]]; then
            log_info "Use 'fioctl targets list' to see available targets"
        else
            log_info "Use 'fioctl targets list --factory $factory' to see available targets"
        fi
        return 1
    fi
    
    log_success "Target $target_number found in factory $factory"
    return 0
}

# Validate machine name
validate_machine() {
    local machine="$1"
    local supported_machines=(
        "imx8mm-jaguar-sentai"
        "imx93-jaguar-eink"
        "imx8mm-jaguar-phasora"
        "imx8mm-jaguar-inst"
        "imx93-11x11-lpddr4x-evk"
    )
    
    for supported in "${supported_machines[@]}"; do
        if [[ "$machine" == "$supported" ]]; then
            log_success "Machine $machine is supported"
            return 0
        fi
    done
    
    log_error "Unsupported machine: $machine"
    log_info "Supported machines: ${supported_machines[*]}"
    return 1
}

# Check if file exists and is not empty
file_exists_and_valid() {
    local file="$1"
    [[ -f "$file" && -s "$file" ]]
}

# Download artifact with progress and error handling
download_artifact() {
    local target_number="$1"
    local factory="$2"
    local artifact_path="$3"
    local output_file="$4"
    local description="$5"
    
    # Check if file already exists and is valid (unless force flag is set)
    if [[ "$FORCE_DOWNLOAD" != "true" ]] && file_exists_and_valid "$output_file"; then
        local size
        size=$(du -h "$output_file" | cut -f1)
        log_info "$description already exists ($size) - skipping download"
        return 0
    fi
    
    log_info "Downloading $description..."
    log_info "  Artifact: $artifact_path"
    log_info "  Output: $output_file"
    
    start_timer
    if fioctl_with_factory "$factory" targets artifacts "$target_number" "$artifact_path" > "$output_file" 2>/dev/null; then
        local download_time
        download_time=$(end_timer)
        local size
        size=$(du -h "$output_file" | cut -f1)
        local formatted_time
        formatted_time=$(format_duration "$download_time")
        log_success "Downloaded $description ($size in $formatted_time)"
        return 0
    else
        log_warn "Failed to download $description (artifact may not exist)"
        rm -f "$output_file"
        return 1
    fi
}

# Main download function
download_target_artifacts() {
    local target_number="$1"
    local factory="$2"
    local machine="$3"
    local output_dir="$4"
    
    log_info "Starting download for target $target_number, machine $machine"
    log_info "Factory: $factory"
    log_info "Output directory: $output_dir"
    
    # Start overall timing
    start_timer
    
    # Create output directory
    mkdir -p "$output_dir"
    
    # Define artifacts to download
    local artifacts_downloaded=0
    local artifacts_failed=0
    
    # Download mfgtool-files archive (contains complete programming package)
    local mfgtools_archive="$output_dir/mfgtool-files-$machine.tar.gz"
    local mfgtools_dir="$output_dir/mfgtool-files-$machine"
    
    # Check if MFGTools are already extracted (unless force flag is set)
    if [[ "$FORCE_DOWNLOAD" != "true" ]] && [[ -d "$mfgtools_dir" && -f "$mfgtools_dir/uuu" && -f "$mfgtools_dir/full_image.uuu" ]]; then
        log_info "MFGTools programming package already extracted - skipping"
        ((artifacts_downloaded++))
    elif download_artifact "$target_number" "$factory" \
        "$machine-mfgtools/mfgtool-files-$machine.tar.gz" \
        "$mfgtools_archive" \
        "MFGTools programming package"; then
        ((artifacts_downloaded++))
        
        # Extract mfgtool-files archive
        log_info "Extracting MFGTools programming package..."
        if tar -xzf "$mfgtools_archive" -C "$output_dir" 2>/dev/null; then
            log_success "Extracted MFGTools programming package"
            # Remove the archive after extraction
            rm -f "$mfgtools_archive"
        else
            log_error "Failed to extract MFGTools programming package"
            ((artifacts_failed++))
        fi
    else
        ((artifacts_failed++))
        log_error "MFGTools programming package is required for programming"
        
        # Fallback: try individual mfgtool files
        log_info "Trying individual mfgtool files as fallback..."
        
        # Manufacturing bootloader (required for programming)
        if download_artifact "$target_number" "$factory" \
            "$machine-mfgtools/other/mfgtool-files/imx-boot-mfgtool" \
            "$output_dir/imx-boot-mfgtool" \
            "Manufacturing bootloader"; then
            ((artifacts_downloaded++))
        else
            ((artifacts_failed++))
            log_error "Manufacturing bootloader is required for programming"
        fi
        
        # Manufacturing U-Boot (required for programming)
        if download_artifact "$target_number" "$factory" \
            "$machine-mfgtools/other/mfgtool-files/u-boot-mfgtool.itb" \
            "$output_dir/u-boot-mfgtool.itb" \
            "Manufacturing U-Boot image"; then
            ((artifacts_downloaded++))
        else
            ((artifacts_failed++))
            log_error "Manufacturing U-Boot image is required for programming"
        fi
    fi
    
    # Production bootloader (required)
    # For i.MX93 boards, download the correct production bootloader (not manufacturing one)
    if [[ "$machine" == *"imx93"* ]]; then
        if download_artifact "$target_number" "$factory" \
            "$machine/imx-boot" \
            "$output_dir/imx-boot-$machine" \
            "Production bootloader (i.MX93)"; then
            ((artifacts_downloaded++))
        else
            ((artifacts_failed++))
            log_error "Production bootloader is required for programming"
        fi
    # Download individual bootloader files (fallback for other machines)
    elif download_artifact "$target_number" "$factory" \
        "$machine/imx-boot-$machine" \
        "$output_dir/imx-boot-$machine" \
        "Production bootloader"; then
        ((artifacts_downloaded++))
    else
        ((artifacts_failed++))
        log_error "Production bootloader is required for programming"
    fi
    
    # Production U-Boot (required)
    if download_artifact "$target_number" "$factory" \
        "$machine/u-boot-$machine.itb" \
        "$output_dir/u-boot-$machine.itb" \
        "Production U-Boot image"; then
        ((artifacts_downloaded++))
    else
        ((artifacts_failed++))
        log_error "Production U-Boot image is required for programming"
    fi
    
    # Device tree blob (optional)
    if download_artifact "$target_number" "$factory" \
        "$machine-mfgtools/other/devicetree/$machine.dtb" \
        "$output_dir/$machine.dtb" \
        "Device tree blob"; then
        ((artifacts_downloaded++))
    else
        ((artifacts_failed++))
    fi
    
    # SIT file (required for some UUU scripts)
    if download_artifact "$target_number" "$factory" \
        "$machine/sit-$machine.bin" \
        "$output_dir/sit-$machine.bin" \
        "SIT file"; then
        ((artifacts_downloaded++))
    else
        ((artifacts_failed++))
    fi
    
    # Try to get main system image from different possible paths
    local system_image_downloaded=false
    
    # First try the standard path
    if download_artifact "$target_number" "$factory" \
        "$machine/lmp-factory-image-$machine.wic.gz" \
        "$output_dir/lmp-factory-image-$machine.wic.gz" \
        "Main system image"; then
        ((artifacts_downloaded++))
        system_image_downloaded=true
    else
        # Try alternative path structure (for app-only builds)
        local tag_info
        tag_info=$(fioctl_with_factory "$factory" targets show "$target_number" 2>/dev/null | grep "Tags:" | awk '{print $2}')
        if [[ -n "$tag_info" ]]; then
            if download_artifact "$target_number" "$factory" \
                "assemble-system-image/$tag_info/lmp-factory-image-$machine.wic.gz" \
                "$output_dir/lmp-factory-image-$machine.wic.gz" \
                "Main system image (from assemble-system-image)"; then
                ((artifacts_downloaded++))
                system_image_downloaded=true
            fi
        fi
    fi
    
    if [[ "$system_image_downloaded" == false ]]; then
        log_warn "Main system image not available - this may be an mfgtools-only build or different artifact structure"
        ((artifacts_failed++))
    fi
    
    # Manifest file (optional)
    if download_artifact "$target_number" "$factory" \
        "$machine-mfgtools/other/manifest.xml" \
        "$output_dir/manifest.xml" \
        "Build manifest"; then
        ((artifacts_downloaded++))
    else
        ((artifacts_failed++))
    fi
    
    # Summary
    echo
    # Calculate total download time
    local total_time
    total_time=$(end_timer)
    local formatted_total_time
    formatted_total_time=$(format_duration "$total_time")
    
    log_info "Download Summary:"
    log_info "  Artifacts downloaded: $artifacts_downloaded"
    log_info "  Artifacts failed: $artifacts_failed"
    log_info "  Total time: $formatted_total_time"
    
    # Check if we have at least a system image (minimum for some use cases)
    if [[ $artifacts_downloaded -ge 1 ]] && [[ "$system_image_downloaded" == true ]]; then
        log_success "System image downloaded successfully"
        
        if [[ $artifacts_downloaded -ge 2 ]]; then
            log_success "Multiple artifacts downloaded - creating programming script"
            # Create a simple programming script
            create_programming_script "$output_dir" "$machine" "$target_number"
        else
            log_warn "Only system image available - no mfgtools for automatic programming"
            log_info "You can manually flash the system image: $output_dir/lmp-factory-image-$machine.wic.gz"
        fi
        
        return 0
    else
        log_error "Failed to download minimum required artifacts (at least system image needed)"
        return 1
    fi
}

# Create a simple programming script
create_programming_script() {
    local output_dir="$1"
    local machine="$2"
    local target_number="$3"
    local script_file="$output_dir/program-$machine.sh"
    
    log_info "Creating programming script: $script_file"
    
    cat > "$script_file" << EOF
#!/bin/bash
#
# Programming script for $machine (Target $target_number)
# Generated by download-target-artifacts.sh
#
# Usage: sudo ./program-$machine.sh [--flash|--bootloader-only]
#

set -euo pipefail

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
MACHINE="$machine"
TARGET="$target_number"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "\${BLUE}[INFO]\${NC} \$1"; }
log_warn() { echo -e "\${YELLOW}[WARN]\${NC} \$1"; }
log_error() { echo -e "\${RED}[ERROR]\${NC} \$1" >&2; }
log_success() { echo -e "\${GREEN}[SUCCESS]\${NC} \$1"; }

usage() {
    cat << USAGE
Usage: \$0 [--flash|--bootloader-only]

Program $machine board with Target $target_number artifacts.

Options:
  --flash            Program complete image (bootloader + filesystem) [default]
  --bootloader-only  Program bootloader only
  --help            Show this help message

Prerequisites:
  1. Board in download/recovery mode
  2. USB cable connected
  3. UUU tool available in PATH or use included version
  4. Run with sudo for USB device access

USAGE
}

# Check for UUU tool
check_uuu() {
    # First try the extracted mfgtool-files UUU (with machine-specific directory name)
    if [[ -f "\$SCRIPT_DIR/mfgtool-files-\$MACHINE/uuu" ]]; then
        UUU_CMD="\$SCRIPT_DIR/mfgtool-files-\$MACHINE/uuu"
        chmod +x "\$UUU_CMD"
        log_info "Using extracted MFGTools UUU tool"
    elif [[ -f "\$SCRIPT_DIR/mfgtool-files/uuu" ]]; then
        UUU_CMD="\$SCRIPT_DIR/mfgtool-files/uuu"
        chmod +x "\$UUU_CMD"
        log_info "Using extracted MFGTools UUU tool"
    elif command -v uuu &> /dev/null; then
        UUU_CMD="uuu"
        log_info "Using system UUU tool"
    elif [[ -f "\$SCRIPT_DIR/../program/uuu" ]]; then
        UUU_CMD="\$SCRIPT_DIR/../program/uuu"
        chmod +x "\$UUU_CMD"
        log_info "Using project UUU tool"
    else
        log_error "UUU tool not found. Install UUU or use programming package with included UUU."
        return 1
    fi
}

# Program complete image
program_full_image() {
    log_info "Programming complete image for \$MACHINE..."
    
    # Check if we have extracted mfgtool-files with UUU scripts (try machine-specific directory first)
    local mfgtool_dir=""
    if [[ -f "\$SCRIPT_DIR/mfgtool-files-\$MACHINE/full_image.uuu" ]]; then
        mfgtool_dir="mfgtool-files-\$MACHINE"
    elif [[ -f "\$SCRIPT_DIR/mfgtool-files/full_image.uuu" ]]; then
        mfgtool_dir="mfgtool-files"
    fi
    
    if [[ -n "\$mfgtool_dir" ]]; then
        log_info "Using extracted MFGTools full_image.uuu script from \$mfgtool_dir"
        
        # Run UUU with the extracted script (using absolute paths like manual command)
        log_info "Starting UUU programming with MFGTools script..."
        if "\$SCRIPT_DIR/\$mfgtool_dir/uuu" "\$SCRIPT_DIR/\$mfgtool_dir/full_image.uuu"; then
            log_success "Programming completed successfully!"
            log_info "Set board to normal boot mode and power cycle"
        else
            log_error "Programming failed"
            return 1
        fi
        
    else
        # Fallback to manual UUU script creation
        log_info "Creating custom UUU script (MFGTools package not available)"
        
        # Check required files
        local required_files=(
            "lmp-factory-image-\$MACHINE.wic.gz"
            "imx-boot-\$MACHINE"
            "u-boot-\$MACHINE.itb"
        )
        
        for file in "\${required_files[@]}"; do
            if [[ ! -f "\$SCRIPT_DIR/\$file" ]]; then
                log_error "Required file not found: \$file"
                return 1
            fi
        done
        
        # Create temporary UUU script
        local uuu_script="\$SCRIPT_DIR/program_full_image.uuu"
        cat > "\$uuu_script" << UUU_SCRIPT
uuu_version 1.2.39

SDP: boot -f \$SCRIPT_DIR/imx-boot-mfgtool
SDPV: delay 1000
SDPV: write -f \$SCRIPT_DIR/u-boot-mfgtool.itb
SDPV: jump

FB: ucmd setenv fastboot_dev mmc
FB: ucmd setenv mmcdev \\\${emmc_dev}
FB: ucmd mmc dev \\\${emmc_dev} 1; mmc erase 0 0x2000
FB: flash -raw2sparse all \$SCRIPT_DIR/lmp-factory-image-\$MACHINE.wic.gz/*
FB: flash bootloader \$SCRIPT_DIR/imx-boot-\$MACHINE
FB: flash bootloader2 \$SCRIPT_DIR/u-boot-\$MACHINE.itb
FB: flash bootloader_s \$SCRIPT_DIR/imx-boot-\$MACHINE
FB: flash bootloader2_s \$SCRIPT_DIR/u-boot-\$MACHINE.itb
FB: ucmd if env exists emmc_ack; then ; else setenv emmc_ack 0; fi;
FB: ucmd mmc partconf \\\${emmc_dev} \\\${emmc_ack} 1 0
FB: done
UUU_SCRIPT
        
        # Run UUU
        log_info "Starting UUU programming..."
        if "\$UUU_CMD" "\$uuu_script"; then
            log_success "Programming completed successfully!"
            log_info "Set board to normal boot mode and power cycle"
        else
            log_error "Programming failed"
            return 1
        fi
        
        # Cleanup
        rm -f "\$uuu_script"
    fi
}

# Program bootloader only
program_bootloader_only() {
    log_info "Programming bootloader only for \$MACHINE..."
    
    # Check if we have extracted mfgtool-files with UUU scripts (try machine-specific directory first)
    local mfgtool_dir=""
    if [[ -f "\$SCRIPT_DIR/mfgtool-files-\$MACHINE/bootloader.uuu" ]]; then
        mfgtool_dir="mfgtool-files-\$MACHINE"
    elif [[ -f "\$SCRIPT_DIR/mfgtool-files/bootloader.uuu" ]]; then
        mfgtool_dir="mfgtool-files"
    fi
    
    if [[ -n "\$mfgtool_dir" ]]; then
        log_info "Using extracted MFGTools bootloader.uuu script from \$mfgtool_dir"
        
        # Run UUU with the extracted script (using absolute paths like manual command)
        log_info "Starting UUU bootloader programming with MFGTools script..."
        if "\$SCRIPT_DIR/\$mfgtool_dir/uuu" "\$SCRIPT_DIR/\$mfgtool_dir/bootloader.uuu"; then
            log_success "Bootloader programming completed successfully!"
            log_info "Set board to normal boot mode and power cycle"
        else
            log_error "Bootloader programming failed"
            return 1
        fi
        
    else
        # Fallback to manual UUU script creation
        log_info "Creating custom bootloader UUU script (MFGTools package not available)"
        
        # Check required files
        local required_files=(
            "imx-boot-\$MACHINE"
            "u-boot-\$MACHINE.itb"
        )
        
        for file in "\${required_files[@]}"; do
            if [[ ! -f "\$SCRIPT_DIR/\$file" ]]; then
                log_error "Required file not found: \$file"
                return 1
            fi
        done
        
        # Create temporary UUU script
        local uuu_script="\$SCRIPT_DIR/program_bootloader.uuu"
        cat > "\$uuu_script" << UUU_SCRIPT
uuu_version 1.2.39

SDP: boot -f \$SCRIPT_DIR/imx-boot-mfgtool
SDPV: delay 1000
SDPV: write -f \$SCRIPT_DIR/u-boot-mfgtool.itb
SDPV: jump

FB: flash bootloader \$SCRIPT_DIR/imx-boot-\$MACHINE
FB: flash bootloader2 \$SCRIPT_DIR/u-boot-\$MACHINE.itb
FB: flash bootloader_s \$SCRIPT_DIR/imx-boot-\$MACHINE
FB: flash bootloader2_s \$SCRIPT_DIR/u-boot-\$MACHINE.itb
FB: done
UUU_SCRIPT
        
        # Run UUU
        log_info "Starting UUU bootloader programming..."
        if "\$UUU_CMD" "\$uuu_script"; then
            log_success "Bootloader programming completed successfully!"
            log_info "Set board to normal boot mode and power cycle"
        else
            log_error "Bootloader programming failed"
            return 1
        fi
        
        # Cleanup
        rm -f "\$uuu_script"
    fi
}

# Check if running as root (required for USB access)
check_root() {
    if [[ \$EUID -ne 0 ]]; then
        log_warn "Not running as root - USB device access may fail"
        log_info "If programming fails, try running with sudo:"
        log_info "  sudo \$0 \$*"
        echo
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! \$REPLY =~ ^[Yy]\$ ]]; then
            log_info "Exiting. Run with sudo for reliable USB access."
            exit 1
        fi
    fi
}

# Main function
main() {
    local mode="flash"
    
    # Parse arguments
    while [[ \$# -gt 0 ]]; do
        case \$1 in
            --flash)
                mode="flash"
                shift
                ;;
            --bootloader-only)
                mode="bootloader"
                shift
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: \$1"
                usage
                exit 1
                ;;
        esac
    done
    
    log_info "Programming mode: \$mode"
    log_info "Target: \$TARGET"
    log_info "Machine: \$MACHINE"
    echo
    
    # Check if running as root
    check_root
    
    # Check UUU tool
    if ! check_uuu; then
        exit 1
    fi
    
    # Program based on mode
    case \$mode in
        flash)
            program_full_image
            ;;
        bootloader)
            program_bootloader_only
            ;;
        *)
            log_error "Invalid mode: \$mode"
            exit 1
            ;;
    esac
}

# Run main function
main "\$@"
EOF
    
    chmod +x "$script_file"
    log_success "Created programming script: $script_file"
}

# Main function
main() {
    # Check if no arguments provided - show help by default
    if [[ $# -eq 0 ]]; then
        log_info "No arguments provided. Showing help..."
        echo ""
        usage
        exit 0
    fi
    
    # Check all dependencies first
    check_all_dependencies
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
    
    # Load configuration
    load_config
    
    # Parse arguments
    local factory="$DEFAULT_FACTORY"
    local machine="$DEFAULT_MACHINE"
    local output_dir=""
    local target_number=""
    local list_targets_flag=false
    local configure_flag=false
    local program_flag=false
    local continuous_flag=false
    FORCE_DOWNLOAD="false"
    
    # Parse command line options
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--factory)
                factory="$2"
                shift 2
                ;;
            -m|--machine)
                machine="$2"
                shift 2
                ;;
            -o|--output)
                output_dir="$2"
                shift 2
                ;;
            -l|--list-targets)
                list_targets_flag=true
                shift
                ;;
            -c|--configure)
                configure_flag=true
                shift
                ;;
            --force)
                FORCE_DOWNLOAD="true"
                shift
                ;;
            --program)
                program_flag=true
                shift
                ;;
            --continuous)
                continuous_flag=true
                program_flag=true  # Continuous implies programming
                shift
                ;;
            -v|--version)
                show_version
                exit 0
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
                # Positional arguments
                if [[ -z "$target_number" ]]; then
                    target_number="$1"
                elif [[ -z "$machine" ]]; then
                    machine="$1"
                elif [[ -z "$output_dir" ]]; then
                    output_dir="$1"
                else
                    log_error "Too many arguments"
                    usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Handle special modes
    if [[ "$configure_flag" == true ]]; then
        configure_interactive
        exit $?
    fi
    
    if [[ "$list_targets_flag" == true ]]; then
        list_targets "$factory"
        exit $?
    fi
    
    # Validate required parameters - try fioctl default factory if none specified
    if [[ -z "$factory" ]]; then
        log_info "No factory specified, checking if fioctl has a default factory configured..."
        
        # Test if fioctl can work without explicit factory (i.e., has default configured)
        if command -v fioctl &> /dev/null && fioctl targets list >/dev/null 2>&1; then
            log_success "Using fioctl's default factory configuration"
            factory="<default>"  # Placeholder - fioctl will use its default
        else
            log_error "Factory name is required"
            log_info "Options to specify factory:"
            log_info "  1. Use --factory <factory-name>"
            log_info "  2. Run --configure to set default factory in this script"
            log_info "  3. Set default factory in fioctl: echo 'factory: your-factory-name' >> ~/.config/fioctl.yaml"
            log_info "  4. Set DEFAULT_FACTORY in config file: $CONFIG_FILE"
            exit 1
        fi
    fi
    
    # Get latest target if none specified
    if [[ -z "$target_number" ]]; then
        log_info "No target specified, finding latest target for machine: $machine"
        if target_number=$(get_latest_target "$factory" "$machine"); then
            log_success "Using latest target: $target_number"
        else
            log_error "Could not find any targets for machine: $machine"
            if [[ "$factory" == "<default>" ]]; then
                log_info "Use 'fioctl targets list' to see available targets"
            else
                log_info "Use 'fioctl targets list --factory $factory' to see available targets"
            fi
            log_info "Or specify a target number explicitly:"
            log_info "  $SCRIPT_NAME --machine $machine <target-number>"
            exit 1
        fi
    fi
    
    if [[ -z "$machine" ]]; then
        log_error "Machine name is required"
        log_info "Use --machine <machine-name> or run --configure to set defaults"
        exit 1
    fi
    
    # Set default output directory if not specified
    if [[ -z "$output_dir" ]]; then
        output_dir="./downloads/target-$target_number-$machine"
    fi
    
    # Validate inputs
    if ! [[ "$target_number" =~ ^[0-9]+$ ]]; then
        log_error "Target number must be a positive integer"
        exit 1
    fi
    
    log_info "Dynamic Devices Board Programming Tool v$SCRIPT_VERSION"
    log_info "Factory: $factory"
    log_info "Target: $target_number"
    log_info "Machine: $machine"
    log_info "Output: $output_dir"
    if [[ "$FORCE_DOWNLOAD" == "true" ]]; then
        log_warn "Force download enabled - will re-download existing files"
    fi
    echo
    
    # Validation steps - dependencies already checked, just validate factory access
    if [[ "$factory" == "<default>" ]]; then
        if ! fioctl targets list &> /dev/null; then
            log_error "Cannot access default factory"
            log_info "Please check:"
            log_info "  1. Run 'fioctl login' to authenticate"
            log_info "  2. Set default factory: Add 'factory: your-factory-name' to ~/.config/fioctl.yaml"
            log_info "  3. Or use --factory factory-name explicitly"
            exit 1
        fi
    else
        if ! fioctl targets list --factory "$factory" &> /dev/null; then
            log_error "Cannot access factory '$factory'"
            log_info "Please check:"
            log_info "  1. Run 'fioctl login' to authenticate"
            log_info "  2. Verify factory name is correct"
            log_info "  3. Ensure you have access to this factory"
            exit 1
        fi
    fi
    
    if ! validate_target "$target_number" "$factory"; then
        exit 1
    fi
    
    if ! validate_machine "$machine"; then
        exit 1
    fi
    
    # Download artifacts
    if download_target_artifacts "$target_number" "$factory" "$machine" "$output_dir"; then
        echo
        log_success "All artifacts downloaded successfully!"
        log_info "Output directory: $output_dir"
        if [[ -f "$output_dir/program-$machine.sh" ]]; then
            log_info "Programming script: $output_dir/program-$machine.sh"
        else
            log_info "System image: $output_dir/lmp-factory-image-$machine.wic.gz"
        fi
        echo
                # Check if auto-programming is requested
        if [[ "$program_flag" == "true" ]]; then
            echo
            # Check if programming script exists
            if [[ ! -f "$output_dir/program-$machine.sh" ]]; then
                log_warn "Auto-programming requested but no programming script available"
                log_info "This target only contains system image - no mfgtools for automatic programming"
                log_info "You can manually flash the system image using tools like dd or balenaEtcher"
                log_info "System image location: $output_dir/lmp-factory-image-$machine.wic.gz"
                return 0
            fi
            
            if [[ "$continuous_flag" == "true" ]]; then
                log_info "Continuous programming mode - programming boards in sequence"
                log_warn "Make sure each board is in download/recovery mode before connecting USB"
                
                local board_count=1
                while true; do
                    echo
                    log_info "=== Programming Board #$board_count ==="
                    log_info "1. Set board to download/recovery mode"
                    log_info "2. Connect USB cable"
                    log_info "3. Programming will start automatically..."
                    
                    start_timer
                    if sudo "$output_dir/program-$machine.sh" --flash; then
                        local programming_time
                        programming_time=$(end_timer)
                        local formatted_programming_time
                        formatted_programming_time=$(format_duration "$programming_time")
                        log_success "Board #$board_count programming completed! (took $formatted_programming_time)"
                        log_info "Set board to normal boot mode and power cycle"
                        ((board_count++))
                        echo
                        read -p "Program another board? (y/N): " -n 1 -r
                        echo
                        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                            log_info "Continuous programming completed. Total boards programmed: $((board_count-1))"
                            break
                        fi
                    else
                        log_error "Board #$board_count programming failed"
                        read -p "Continue with next board? (y/N): " -n 1 -r
                        echo
                        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                            exit 1
                        fi
                    fi
                done
            else
                log_info "Auto-programming requested - starting board programming..."
                log_warn "Make sure your board is in download/recovery mode and USB is connected"
                
                log_info "Starting programming process..."
                start_timer
                if sudo "$output_dir/program-$machine.sh" --flash; then
                    local programming_time
                    programming_time=$(end_timer)
                    local formatted_programming_time
                    formatted_programming_time=$(format_duration "$programming_time")
                    log_success "Board programming completed successfully! (took $formatted_programming_time)"
                    log_info "Set board to normal boot mode and power cycle"
                else
                    log_error "Board programming failed"
                    exit 1
                fi
            fi
        else
            log_info "Next steps:"
            log_info "  1. Put your board in download/recovery mode"
            log_info "  2. Connect USB cable"
            log_info "  3. Run with sudo: sudo $output_dir/program-$machine.sh --flash"
            log_info ""
            log_info "Note: sudo is required for USB device access during programming"
        fi
    else
        echo
        log_error "Failed to download required artifacts"
        exit 1
    fi
}

# Run main function with all arguments
main "$@"
