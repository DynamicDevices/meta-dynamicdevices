#!/bin/bash
# validate-layers-local.sh - Run comprehensive yocto-check-layer validation locally
#
# This script uses KAS to set up a proper Yocto environment and runs
# yocto-check-layer validation on all meta-dynamicdevices layers.
#
# Usage: ./scripts/validate-layers-local.sh [--clean]
#
# Options:
#   --clean    Clean build directory before validation
#
# Copyright (c) 2025 Dynamic Devices Ltd

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build-validation"
KAS_CONFIG="$PROJECT_ROOT/kas/layer-validation.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Help function
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Run comprehensive yocto-check-layer validation on meta-dynamicdevices layers.

OPTIONS:
    --clean         Clean build directory before validation
    --help, -h      Show this help message

DESCRIPTION:
    This script sets up a proper Yocto environment using KAS and runs
    the official yocto-check-layer tool to validate all meta-dynamicdevices
    layers for Yocto Project compatibility.

    The validation includes:
    - Layer structure and configuration
    - Recipe parsing and compatibility
    - Machine and distro compatibility
    - Patch upstream status
    - BitBake signature generation

EXAMPLES:
    $0                  # Run validation with existing build
    $0 --clean          # Clean build and run validation

EOF
}

# Parse command line arguments
CLEAN_BUILD=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --help|-h)
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

# Check dependencies
check_dependencies() {
    log_info "Checking dependencies..."
    
    if ! command -v kas >/dev/null 2>&1; then
        log_error "KAS not found. Please install kas-container or kas."
        log_info "Install with: pip3 install kas"
        exit 1
    fi
    
    if ! command -v git >/dev/null 2>&1; then
        log_error "Git not found. Please install git."
        exit 1
    fi
    
    log_success "All dependencies found"
}

# Clean build directory if requested
clean_build() {
    if [[ "$CLEAN_BUILD" == "true" ]]; then
        log_info "Cleaning build directory..."
        rm -rf "$BUILD_DIR"
        log_success "Build directory cleaned"
    fi
}

# Set up KAS environment
setup_kas_environment() {
    log_info "Setting up KAS environment for layer validation..."
    
    cd "$PROJECT_ROOT"
    
    # Initialize KAS build environment
    log_info "Initializing KAS build environment..."
    kas shell "$KAS_CONFIG" -c "echo 'KAS environment initialized'"
    
    log_success "KAS environment ready"
}

# Run yocto-check-layer validation
run_layer_validation() {
    local layer_path="$1"
    local layer_name="$2"
    
    log_info "Validating $layer_name using yocto-check-layer..."
    
    cd "$PROJECT_ROOT"
    
    # Run yocto-check-layer in KAS environment
    if kas shell "$KAS_CONFIG" -c "
        cd build-validation
        
        # Find yocto-check-layer script
        YOCTO_CHECK_LAYER=\$(find . -name 'yocto-check-layer' -type f | head -1)
        if [ -z \"\$YOCTO_CHECK_LAYER\" ]; then
            echo 'yocto-check-layer script not found in build environment'
            exit 1
        fi
        
        echo 'Found yocto-check-layer: '\$YOCTO_CHECK_LAYER
        
        # Clean up potential conflicts
        rm -rf layers/bitbake/lib/layerindexlib/tests/testdata/ 2>/dev/null || true
        
        # Run validation
        python3 \"\$YOCTO_CHECK_LAYER\" \"$layer_path\"
    "; then
        log_success "$layer_name validation PASSED"
        return 0
    else
        log_error "$layer_name validation FAILED"
        return 1
    fi
}

# Main validation function
main() {
    echo "🏅 Meta-DynamicDevices Layer Validation"
    echo "========================================"
    echo ""
    
    check_dependencies
    clean_build
    setup_kas_environment
    
    # Track validation results
    local validation_failed=false
    
    echo ""
    log_info "Starting comprehensive layer validation..."
    echo ""
    
    # Validate meta-dynamicdevices-bsp
    echo "1️⃣ Validating meta-dynamicdevices-bsp..."
    if ! run_layer_validation "../meta-dynamicdevices-bsp" "meta-dynamicdevices-bsp"; then
        validation_failed=true
    fi
    echo ""
    
    # Validate meta-dynamicdevices-distro
    echo "2️⃣ Validating meta-dynamicdevices-distro..."
    if ! run_layer_validation "../meta-dynamicdevices-distro" "meta-dynamicdevices-distro"; then
        validation_failed=true
    fi
    echo ""
    
    # Validate meta-dynamicdevices (main layer)
    echo "3️⃣ Validating meta-dynamicdevices (main layer)..."
    if ! run_layer_validation ".." "meta-dynamicdevices"; then
        validation_failed=true
    fi
    echo ""
    
    # Final results
    echo "========================================"
    if [[ "$validation_failed" == "true" ]]; then
        log_error "Layer validation FAILED"
        echo ""
        log_info "Please fix the yocto-check-layer issues above before proceeding."
        log_info "Check the validation log at: $BUILD_DIR/validation.log"
        exit 1
    else
        log_success "All layer validations PASSED"
        echo ""
        log_info "All meta-dynamicdevices layers pass comprehensive yocto-check-layer validation!"
        log_info "Layers are ready for Yocto Project compatibility."
    fi
}

# Run main function
main "$@"
