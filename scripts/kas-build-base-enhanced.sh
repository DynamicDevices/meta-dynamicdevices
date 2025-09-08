#!/bin/bash
#
# Enhanced KAS Build Script for Base Images
# Provides comprehensive error handling, validation, and CI compatibility
#

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DEFAULT_CACHE_DIR="${HOME}/yocto"
LOG_FILE="${PROJECT_ROOT}/logs/kas-build-$(date +%Y%m%d-%H%M%S).log"

# Color output for better UX
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

# Cleanup function for error handling
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "Build failed with exit code $exit_code"
        log_info "Check log file: $LOG_FILE"
        
        # In CI environment, preserve artifacts for debugging
        if [ "${CI:-false}" = "true" ]; then
            log_info "CI environment detected - preserving build artifacts"
        fi
    fi
}

trap cleanup EXIT

# Supported machines list
SUPPORTED_MACHINES=(
    "imx8mm-jaguar-sentai"
    "imx8mm-jaguar-inst" 
    "imx8mm-jaguar-phasora"
    "imx8mm-jaguar-handheld"
    "imx93-jaguar-eink"
    "imx93-11x11-lpddr4x-evk"
)

# Validation functions
validate_machine() {
    local machine="$1"
    
    if [ -z "$machine" ]; then
        log_error "No machine specified"
        show_usage
        exit 1
    fi
    
    # Check if machine is supported
    for supported in "${SUPPORTED_MACHINES[@]}"; do
        if [ "$machine" = "$supported" ]; then
            return 0
        fi
    done
    
    log_error "Unsupported machine: $machine"
    log_info "Supported machines: ${SUPPORTED_MACHINES[*]}"
    exit 1
}

validate_environment() {
    log_info "Validating build environment..."
    
    # Check for required tools
    local required_tools=("kas-container" "docker")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "Required tool not found: $tool"
            exit 1
        fi
    done
    
    # Check Docker daemon
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running or not accessible"
        exit 1
    fi
    
    # Check KAS configuration exists
    local kas_config="$PROJECT_ROOT/kas/lmp-dynamicdevices-base.yml"
    if [ ! -f "$kas_config" ]; then
        log_error "KAS configuration not found: $kas_config"
        exit 1
    fi
    
    log_success "Environment validation passed"
}

setup_cache_directories() {
    local cache_dir="${YOCTO_CACHE_DIR:-$DEFAULT_CACHE_DIR}"
    
    log_info "Setting up cache directories in: $cache_dir"
    
    # Create cache directories with proper permissions
    local dirs=("downloads" "persistent" "sstate")
    for dir in "${dirs[@]}"; do
        local full_path="$cache_dir/$dir"
        if [ ! -d "$full_path" ]; then
            mkdir -p "$full_path"
            # Use more restrictive permissions than 777
            chmod 755 "$full_path"
            log_info "Created directory: $full_path"
        fi
    done
    
    export YOCTO_CACHE_DIR="$cache_dir"
}

# TODO Resolution: Check for factory keys and provide guidance
check_factory_keys() {
    local factory_keys_dir="$PROJECT_ROOT/conf/factory-keys"
    
    if [ ! -d "$factory_keys_dir" ]; then
        log_warn "Factory keys directory not found: $factory_keys_dir"
        log_warn "Secure boot features will be disabled"
        log_info "To enable secure boot, create factory keys using lmp-tools/scripts/rotate_ci_keys.sh"
        
        # For development builds, disable signing
        export OPTEE_TA_SIGN_ENABLE="0"
        export SIGN_ENABLE="0" 
        export UBOOT_SIGN_ENABLE="0"
        export UBOOT_SPL_SIGN_ENABLE="0"
        export TF_A_SIGN_ENABLE="0"
        export UEFI_SIGN_ENABLE="0"
        
        return 1
    else
        log_info "Factory keys found - secure boot will be enabled"
        return 0
    fi
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -m, --machine MACHINE    Target machine (required)"
    echo "  -c, --cache-dir DIR      Cache directory (default: $DEFAULT_CACHE_DIR)"
    echo "  -j, --jobs JOBS          Number of parallel jobs"
    echo "  -v, --verbose            Verbose output"
    echo "  -h, --help               Show this help"
    echo ""
    echo "Supported machines:"
    printf "  %s\n" "${SUPPORTED_MACHINES[@]}"
    echo ""
    echo "Environment variables:"
    echo "  KAS_MACHINE              Target machine (alternative to -m)"
    echo "  YOCTO_CACHE_DIR          Cache directory (alternative to -c)"
    echo "  BB_NUMBER_THREADS        BitBake parallel threads"
    echo "  PARALLEL_MAKE            Make parallel jobs"
    echo ""
    echo "Examples:"
    echo "  $0 -m imx8mm-jaguar-sentai"
    echo "  KAS_MACHINE=imx93-jaguar-eink $0"
    echo "  $0 -m imx8mm-jaguar-sentai -j 8 -v"
}

# Parse command line arguments
parse_arguments() {
    local TEMP
    TEMP=$(getopt -o 'm:c:j:vh' --long 'machine:,cache-dir:,jobs:,verbose,help' -n "$0" -- "$@")
    
    if ! getopt -o 'm:c:j:vh' --long 'machine:,cache-dir:,jobs:,verbose,help' -n "$0" -- "$@" >/dev/null; then
        show_usage
        exit 1
    fi
    
    eval set -- "$TEMP"
    unset TEMP
    
    while true; do
        case "$1" in
            '-m'|'--machine')
                export KAS_MACHINE="$2"
                shift 2
                continue
                ;;
            '-c'|'--cache-dir')
                export YOCTO_CACHE_DIR="$2"
                shift 2
                continue
                ;;
            '-j'|'--jobs')
                export BB_NUMBER_THREADS="$2"
                export PARALLEL_MAKE="-j $2"
                shift 2
                continue
                ;;
            '-v'|'--verbose')
                set -x  # Enable verbose mode
                shift
                continue
                ;;
            '-h'|'--help')
                show_usage
                exit 0
                ;;
            '--')
                shift
                break
                ;;
            *)
                log_error "Internal error parsing arguments"
                exit 1
                ;;
        esac
    done
    
    # Use KAS_MACHINE from environment if not set via arguments
    if [ -z "${KAS_MACHINE:-}" ]; then
        log_error "Machine not specified. Use -m/--machine or set KAS_MACHINE environment variable"
        show_usage
        exit 1
    fi
}

# Main build function
run_kas_build() {
    local machine="$KAS_MACHINE"
    local cache_dir="${YOCTO_CACHE_DIR:-$DEFAULT_CACHE_DIR}"
    local kas_config="$PROJECT_ROOT/kas/lmp-dynamicdevices-base.yml"
    
    log_info "Starting KAS build for machine: $machine"
    log_info "Using cache directory: $cache_dir"
    log_info "KAS configuration: $kas_config"
    
    # Build kas-container command with SSH support for private repositories
    local kas_cmd=(
        "kas-container"
        "--runtime-args"
        "-v ${cache_dir}:/var/cache -e KAS_MACHINE=$machine"
    )
    
    # Add SSH support for private repositories
    if [ -n "${SSH_AUTH_SOCK:-}" ] && [ -d "${HOME}/.ssh" ]; then
        kas_cmd=("kas-container" "--ssh-agent" "--ssh-dir" "${HOME}/.ssh" "--runtime-args" "-v ${cache_dir}:/var/cache -e KAS_MACHINE=$machine")
        log_info "SSH agent and SSH directory forwarding enabled for private repositories"
    else
        log_warn "SSH_AUTH_SOCK not set or ~/.ssh directory not found - private repository access may fail"
    fi
    
    # Add environment variables for parallel builds
    if [ -n "${BB_NUMBER_THREADS:-}" ]; then
        kas_cmd[2]+=" -e BB_NUMBER_THREADS=$BB_NUMBER_THREADS"
    fi
    
    if [ -n "${PARALLEL_MAKE:-}" ]; then
        kas_cmd[2]+=" -e PARALLEL_MAKE='$PARALLEL_MAKE'"
    fi
    
    # Add signing configuration
    kas_cmd[2]+=" -e OPTEE_TA_SIGN_ENABLE=${OPTEE_TA_SIGN_ENABLE:-1}"
    kas_cmd[2]+=" -e SIGN_ENABLE=${SIGN_ENABLE:-1}"
    kas_cmd[2]+=" -e UBOOT_SIGN_ENABLE=${UBOOT_SIGN_ENABLE:-1}"
    kas_cmd[2]+=" -e UBOOT_SPL_SIGN_ENABLE=${UBOOT_SPL_SIGN_ENABLE:-1}"
    kas_cmd[2]+=" -e TF_A_SIGN_ENABLE=${TF_A_SIGN_ENABLE:-1}"
    kas_cmd[2]+=" -e UEFI_SIGN_ENABLE=${UEFI_SIGN_ENABLE:-1}"
    
    kas_cmd+=("build" "$kas_config")
    
    log_info "Executing: ${kas_cmd[*]}"
    
    # Run the build with proper error handling
    if "${kas_cmd[@]}"; then
        log_success "KAS build completed successfully for $machine"
        show_build_artifacts "$machine"
    else
        log_error "KAS build failed for $machine"
        exit 1
    fi
}

# Show build artifacts information
show_build_artifacts() {
    local machine="$1"
    local cache_dir="${YOCTO_CACHE_DIR:-$DEFAULT_CACHE_DIR}"
    local deploy_dir="$cache_dir/persistent/build/tmp/deploy/images/$machine"
    
    if [ -d "$deploy_dir" ]; then
        log_info "Build artifacts available in: $deploy_dir"
        log_info "Key artifacts:"
        
        # List important artifacts
        local artifacts=(
            "lmp-factory-image-$machine.wic.gz"
            "imx-boot-$machine"
            "u-boot-$machine.itb"
        )
        
        for artifact in "${artifacts[@]}"; do
            if [ -f "$deploy_dir/$artifact" ]; then
                local size
                size=$(du -h "$deploy_dir/$artifact" | cut -f1)
                log_info "  - $artifact ($size)"
            fi
        done
    else
        log_warn "Deploy directory not found: $deploy_dir"
    fi
}

# Main execution
main() {
    # Ensure logs directory exists
    mkdir -p "$(dirname "$LOG_FILE")"
    
    log_info "=== Enhanced KAS Build Script ==="
    log_info "Starting build at $(date)"
    log_info "Log file: $LOG_FILE"
    
    # Parse arguments first
    parse_arguments "$@"
    
    # Run validations
    validate_machine "$KAS_MACHINE"
    validate_environment
    setup_cache_directories
    check_factory_keys
    
    # Execute build
    run_kas_build
    
    log_success "=== Build completed successfully ==="
    log_info "Completed at $(date)"
}

# Execute main function with all arguments
main "$@"
