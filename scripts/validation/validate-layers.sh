#!/bin/bash
# Yocto Layer Validation Script
# Validates meta-dynamicdevices layers for Yocto Project Compatible compliance

set -e

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
VALIDATION_DIR="$BUILD_DIR/validation"

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

# Usage information
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Validate Yocto layers for Project Compatible compliance

OPTIONS:
    -l, --layer LAYER       Validate specific layer (bsp|distro|all)
    -b, --branch BRANCH     Yocto branch to validate against (scarthgap|kirkstone)
    -c, --clean             Clean validation environment before running
    -v, --verbose           Enable verbose output
    -h, --help              Show this help message

EXAMPLES:
    $0 --layer bsp --branch scarthgap
    $0 --layer all --clean
    $0 --verbose

EOF
}

# Parse command line arguments
LAYER="all"
YOCTO_BRANCH="scarthgap"
CLEAN=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--layer)
            LAYER="$2"
            shift 2
            ;;
        -b|--branch)
            YOCTO_BRANCH="$2"
            shift 2
            ;;
        -c|--clean)
            CLEAN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
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

# Validate arguments
if [[ ! "$LAYER" =~ ^(bsp|distro|all)$ ]]; then
    log_error "Invalid layer: $LAYER. Must be 'bsp', 'distro', or 'all'"
    exit 1
fi

if [[ ! "$YOCTO_BRANCH" =~ ^(scarthgap|kirkstone|nanbield)$ ]]; then
    log_error "Invalid Yocto branch: $YOCTO_BRANCH"
    exit 1
fi

# Set BitBake branch based on Yocto branch
case $YOCTO_BRANCH in
    scarthgap)
        BITBAKE_BRANCH="2.8"
        ;;
    kirkstone)
        BITBAKE_BRANCH="2.0"
        ;;
    nanbield)
        BITBAKE_BRANCH="2.6"
        ;;
esac

log_info "Starting Yocto layer validation"
log_info "Layer: $LAYER"
log_info "Yocto Branch: $YOCTO_BRANCH"
log_info "BitBake Branch: $BITBAKE_BRANCH"

# Clean validation environment if requested
if [ "$CLEAN" = true ]; then
    log_info "Cleaning validation environment..."
    rm -rf "$VALIDATION_DIR"
fi

# Create validation directory structure
mkdir -p "$VALIDATION_DIR"
cd "$VALIDATION_DIR"

# Function to setup Yocto environment
setup_yocto_environment() {
    log_info "Setting up Yocto environment for $YOCTO_BRANCH..."
    
    # Create layers directory
    mkdir -p layers
    
    # Clone OpenEmbedded-Core
    if [ ! -d "layers/openembedded-core" ]; then
        log_info "Cloning OpenEmbedded-Core ($YOCTO_BRANCH)..."
        git clone -b "$YOCTO_BRANCH" \
            https://github.com/openembedded/openembedded-core.git \
            layers/openembedded-core
    else
        log_info "OpenEmbedded-Core already exists, updating..."
        cd layers/openembedded-core
        git fetch origin
        git checkout "$YOCTO_BRANCH"
        git pull origin "$YOCTO_BRANCH"
        cd ../..
    fi
    
    # Clone BitBake
    if [ ! -d "layers/bitbake" ]; then
        log_info "Cloning BitBake ($BITBAKE_BRANCH)..."
        git clone -b "$BITBAKE_BRANCH" \
            https://github.com/openembedded/bitbake.git \
            layers/bitbake
    else
        log_info "BitBake already exists, updating..."
        cd layers/bitbake
        git fetch origin
        git checkout "$BITBAKE_BRANCH"
        git pull origin "$BITBAKE_BRANCH"
        cd ../..
    fi
    
    # Clone meta-openembedded for dependencies
    if [ ! -d "layers/meta-openembedded" ]; then
        log_info "Cloning meta-openembedded ($YOCTO_BRANCH)..."
        git clone -b "$YOCTO_BRANCH" \
            https://github.com/openembedded/meta-openembedded.git \
            layers/meta-openembedded
    else
        log_info "meta-openembedded already exists, updating..."
        cd layers/meta-openembedded
        git fetch origin
        git checkout "$YOCTO_BRANCH"
        git pull origin "$YOCTO_BRANCH"
        cd ../..
    fi
    
    log_success "Yocto environment setup complete"
}

# Function to validate layer structure
validate_layer_structure() {
    local layer_path="$1"
    local layer_name="$2"
    
    log_info "Validating structure for $layer_name..."
    
    # Check required files
    local required_files=("README.md" "SECURITY.md" "LICENSE" "conf/layer.conf")
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$layer_path/$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        log_error "Missing required files in $layer_name:"
        for file in "${missing_files[@]}"; do
            log_error "  - $file"
        done
        return 1
    fi
    
    # Validate layer.conf syntax
    log_info "Validating layer.conf syntax for $layer_name..."
    python3 -c "
import sys
try:
    with open('$layer_path/conf/layer.conf', 'r') as f:
        content = f.read()
        required_vars = ['BBFILE_COLLECTIONS', 'BBFILE_PATTERN', 'BBFILE_PRIORITY', 'LAYERVERSION']
        missing_vars = []
        for var in required_vars:
            if var not in content:
                missing_vars.append(var)
        if missing_vars:
            print('Missing required variables: ' + ', '.join(missing_vars))
            sys.exit(1)
        print('layer.conf syntax valid')
except Exception as e:
    print(f'layer.conf validation failed: {e}')
    sys.exit(1)
"
    
    if [ $? -eq 0 ]; then
        log_success "Structure validation passed for $layer_name"
        return 0
    else
        log_error "Structure validation failed for $layer_name"
        return 1
    fi
}

# Function to run yocto-check-layer
run_yocto_check_layer() {
    local layer_path="$1"
    local layer_name="$2"
    
    log_info "Running yocto-check-layer on $layer_name..."
    
    # Set up BitBake environment
    export PYTHONPATH="$VALIDATION_DIR/layers/bitbake/lib:$PYTHONPATH"
    export PATH="$VALIDATION_DIR/layers/bitbake/bin:$VALIDATION_DIR/layers/openembedded-core/scripts:$PATH"
    
    # Create build configuration
    mkdir -p conf
    
    # Create bblayers.conf
    cat > conf/bblayers.conf << EOF
LCONF_VERSION = "7"
BBPATH = "\${TOPDIR}"
BBFILES ?= ""
BBLAYERS ?= " \\
  \${TOPDIR}/layers/openembedded-core/meta \\
  \${TOPDIR}/layers/meta-openembedded/meta-oe \\
  $layer_path \\
"
EOF
    
    # Create local.conf
    cat > conf/local.conf << EOF
MACHINE ??= "qemux86-64"
DISTRO ?= "poky"
PACKAGE_CLASSES ?= "package_rpm"
EXTRA_IMAGE_FEATURES ?= "debug-tweaks"
USER_CLASSES ?= "buildstats"
PATCHRESOLVE = "noop"
BB_DISKMON_DIRS ??= "\\
    STOPTASKS,\${TMPDIR},1G,100K \\
    STOPTASKS,\${DL_DIR},1G,100K \\
    STOPTASKS,\${SSTATE_DIR},1G,100K \\
    STOPTASKS,/tmp,100M,100K \\
    HALT,\${TMPDIR},100M,1K \\
    HALT,\${DL_DIR},100M,1K \\
    HALT,\${SSTATE_DIR},100M,1K \\
    HALT,/tmp,10M,1K"
CONF_VERSION = "2"
DL_DIR ?= "\${TOPDIR}/downloads"
SSTATE_DIR ?= "\${TOPDIR}/sstate-cache"
EOF
    
    # Run the layer check
    local log_file="$VALIDATION_DIR/layer-check-$layer_name-$YOCTO_BRANCH.log"
    
    if [ "$VERBOSE" = true ]; then
        python3 "$VALIDATION_DIR/layers/openembedded-core/scripts/yocto-check-layer" \
            --layer "$layer_path" \
            --output-log "$log_file" 2>&1 | tee "$log_file.verbose"
        local result=${PIPESTATUS[0]}
    else
        python3 "$VALIDATION_DIR/layers/openembedded-core/scripts/yocto-check-layer" \
            --layer "$layer_path" \
            --output-log "$log_file" > /dev/null 2>&1
        local result=$?
    fi
    
    # Analyze results
    if [ -f "$log_file" ]; then
        log_info "Analyzing yocto-check-layer results for $layer_name..."
        
        if grep -q "ERROR" "$log_file"; then
            log_error "Critical errors found in $layer_name validation:"
            grep "ERROR" "$log_file" | head -10
            return 1
        fi
        
        if grep -q "WARNING" "$log_file"; then
            log_warning "Warnings found in $layer_name validation:"
            grep "WARNING" "$log_file" | head -5
        fi
        
        log_success "yocto-check-layer completed for $layer_name"
        log_info "Full results saved to: $log_file"
        return 0
    else
        log_error "yocto-check-layer failed to generate log for $layer_name"
        return 1
    fi
}

# Function to validate a single layer
validate_single_layer() {
    local layer_type="$1"
    local layer_name="meta-dynamicdevices-$layer_type"
    local layer_path="$PROJECT_ROOT/$layer_name"
    
    if [ ! -d "$layer_path" ]; then
        log_error "Layer directory not found: $layer_path"
        return 1
    fi
    
    log_info "=== Validating $layer_name ==="
    
    # Validate structure
    if ! validate_layer_structure "$layer_path" "$layer_name"; then
        return 1
    fi
    
    # Run yocto-check-layer
    if ! run_yocto_check_layer "$layer_path" "$layer_name"; then
        return 1
    fi
    
    log_success "$layer_name validation completed successfully"
    return 0
}

# Function to generate validation report
generate_report() {
    local report_file="$VALIDATION_DIR/validation-report-$YOCTO_BRANCH.md"
    
    log_info "Generating validation report..."
    
    cat > "$report_file" << EOF
# Yocto Layer Validation Report

**Generated**: $(date -u '+%Y-%m-%d %H:%M:%S UTC')
**Yocto Branch**: $YOCTO_BRANCH
**BitBake Branch**: $BITBAKE_BRANCH
**Validated Layers**: $LAYER

## Summary

EOF
    
    # Add layer-specific information
    if [[ "$LAYER" == "all" || "$LAYER" == "bsp" ]]; then
        echo "### meta-dynamicdevices-bsp" >> "$report_file"
        echo "- **Type**: BSP (Board Support Package)" >> "$report_file"
        echo "- **Machines**: $(ls "$PROJECT_ROOT/meta-dynamicdevices-bsp/conf/machine"/*.conf 2>/dev/null | wc -l)" >> "$report_file"
        echo "- **Recipes**: $(find "$PROJECT_ROOT/meta-dynamicdevices-bsp/recipes-"* -name "*.bb" -o -name "*.bbappend" 2>/dev/null | wc -l)" >> "$report_file"
        echo "" >> "$report_file"
    fi
    
    if [[ "$LAYER" == "all" || "$LAYER" == "distro" ]]; then
        echo "### meta-dynamicdevices-distro" >> "$report_file"
        echo "- **Type**: Distro (Distribution Policy)" >> "$report_file"
        echo "- **Distributions**: $(ls "$PROJECT_ROOT/meta-dynamicdevices-distro/conf/distro"/*.conf 2>/dev/null | wc -l)" >> "$report_file"
        echo "- **Recipes**: $(find "$PROJECT_ROOT/meta-dynamicdevices-distro/recipes-"* -name "*.bb" -o -name "*.bbappend" 2>/dev/null | wc -l)" >> "$report_file"
        echo "" >> "$report_file"
    fi
    
    echo "## Validation Results" >> "$report_file"
    echo "" >> "$report_file"
    
    # Include log summaries
    for log_file in "$VALIDATION_DIR"/layer-check-*.log; do
        if [ -f "$log_file" ]; then
            local log_name=$(basename "$log_file" .log)
            echo "### $log_name" >> "$report_file"
            echo '```' >> "$report_file"
            tail -20 "$log_file" >> "$report_file"
            echo '```' >> "$report_file"
            echo "" >> "$report_file"
        fi
    done
    
    log_success "Validation report generated: $report_file"
}

# Main execution
main() {
    # Setup environment
    setup_yocto_environment
    
    local validation_failed=false
    
    # Validate layers based on selection
    case $LAYER in
        "bsp")
            if ! validate_single_layer "bsp"; then
                validation_failed=true
            fi
            ;;
        "distro")
            if ! validate_single_layer "distro"; then
                validation_failed=true
            fi
            ;;
        "all")
            if ! validate_single_layer "bsp"; then
                validation_failed=true
            fi
            if ! validate_single_layer "distro"; then
                validation_failed=true
            fi
            ;;
    esac
    
    # Generate report
    generate_report
    
    # Final status
    if [ "$validation_failed" = true ]; then
        log_error "Layer validation failed!"
        exit 1
    else
        log_success "All layer validations passed!"
        log_info "Results available in: $VALIDATION_DIR"
        exit 0
    fi
}

# Run main function
main "$@"
