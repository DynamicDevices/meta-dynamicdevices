#!/bin/bash
#
# Devtool Application Development Workflow Demo
#
# This script demonstrates the complete workflow for developing and debugging
# applications using devtool with remote deployment to a running target board.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"

# Configuration
RECIPE_NAME="eink-power-cli"
TARGET_IP="${TARGET_IP:-192.168.1.100}"
MACHINE="${KAS_MACHINE:-imx93-jaguar-eink}"
DEBUG_PORT="${DEBUG_PORT:-9999}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}🔹 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

show_usage() {
    cat << EOF
Usage: $0 [STEP] [OPTIONS]

Complete devtool application development workflow demonstration.
Uses $RECIPE_NAME as example application for remote development and debugging.

STEPS:
    setup               Set up devtool workspace for recipe modification
    build               Build the application using devtool
    deploy              Deploy application to running target board
    debug               Set up remote debugging session
    test                Test the deployed application
    finish              Finish devtool workspace and commit changes
    complete            Run complete workflow (setup → build → deploy → test)
    clean               Clean up devtool workspace

OPTIONS:
    -t, --target IP          Target board IP address (default: $TARGET_IP)
    -m, --machine MACHINE    Target machine (default: $MACHINE)
    -p, --port PORT          Debug port (default: $DEBUG_PORT)
    -h, --help              Show this help message

ENVIRONMENT VARIABLES:
    TARGET_IP               Default target IP address
    KAS_MACHINE             Target machine
    DEBUG_PORT              Remote debugging port

EXAMPLES:
    # Complete workflow with default settings
    $0 complete
    
    # Step-by-step workflow
    $0 setup
    $0 build
    $0 deploy --target 192.168.1.50
    $0 test
    
    # Set up remote debugging
    $0 debug --target 192.168.1.50 --port 9999
    
    # Clean up when done
    $0 finish

PREREQUISITES:
    1. Target board running with SSH access
    2. Board accessible at specified IP address
    3. KAS development environment set up

EOF
}

# Ensure yocto cache directories exist
setup_cache_dirs() {
    if [ ! -d ~/yocto ]; then
        mkdir -p ~/yocto/{downloads,persistent,sstate}
        chmod 755 ~/yocto/{downloads,persistent,sstate}
    fi
}

# Check if target board is accessible
check_target_board() {
    print_step "Checking target board accessibility at $TARGET_IP..."
    
    if ! ping -c 1 -W 2 "$TARGET_IP" >/dev/null 2>&1; then
        print_error "Target board at $TARGET_IP is not reachable"
        echo "💡 Make sure:"
        echo "   - Board is powered on and booted"
        echo "   - Board is connected to network"
        echo "   - IP address is correct"
        echo "   - No firewall blocking ping"
        return 1
    fi
    
    if ! ssh -o ConnectTimeout=5 -o BatchMode=yes root@"$TARGET_IP" exit 2>/dev/null; then
        print_warning "SSH connection to root@$TARGET_IP failed"
        echo "💡 Try:"
        echo "   - ssh root@$TARGET_IP (manual connection test)"
        echo "   - Check SSH service: ssh root@$TARGET_IP 'systemctl status sshd'"
        echo "   - Check SSH keys or use password authentication"
        return 1
    fi
    
    print_success "Target board is accessible at $TARGET_IP"
    return 0
}

# Set up devtool workspace
setup_devtool_workspace() {
    print_step "Setting up devtool workspace for $RECIPE_NAME..."
    setup_cache_dirs
    
    cd "$PROJECT_ROOT"
    
    # Check if workspace already exists
    if [ -d "build/workspace/sources/$RECIPE_NAME" ]; then
        print_warning "Devtool workspace for $RECIPE_NAME already exists"
        echo "📁 Existing workspace: build/workspace/sources/$RECIPE_NAME"
        echo "💡 Use '$0 clean' to remove existing workspace"
        return 0
    fi
    
    print_step "Running devtool modify $RECIPE_NAME..."
    kas-container --ssh-agent --ssh-dir ${HOME}/.ssh \
        --runtime-args "-v ${HOME}/yocto:/var/cache" \
        shell kas/lmp-dynamicdevices-dev.yml \
        -c "devtool modify $RECIPE_NAME"
    
    if [ -d "build/workspace/sources/$RECIPE_NAME" ]; then
        print_success "Devtool workspace created successfully"
        echo "📁 Source code: build/workspace/sources/$RECIPE_NAME/"
        echo "💡 Make your changes to the source code, then run: $0 build"
        
        # Show source structure
        echo ""
        echo "📂 Source structure:"
        ls -la "build/workspace/sources/$RECIPE_NAME/" || true
    else
        print_error "Failed to create devtool workspace"
        return 1
    fi
}

# Build application using devtool
build_application() {
    print_step "Building $RECIPE_NAME using devtool..."
    setup_cache_dirs
    
    cd "$PROJECT_ROOT"
    
    if [ ! -d "build/workspace/sources/$RECIPE_NAME" ]; then
        print_error "Devtool workspace not found for $RECIPE_NAME"
        echo "💡 Run '$0 setup' first to create workspace"
        return 1
    fi
    
    print_step "Running devtool build $RECIPE_NAME..."
    kas-container --ssh-agent --ssh-dir ${HOME}/.ssh \
        --runtime-args "-v ${HOME}/yocto:/var/cache" \
        shell kas/lmp-dynamicdevices-dev.yml \
        -c "devtool build $RECIPE_NAME"
    
    print_success "Application built successfully"
    echo "💡 Ready for deployment: $0 deploy"
}

# Deploy application to target
deploy_application() {
    print_step "Deploying $RECIPE_NAME to target board..."
    
    if ! check_target_board; then
        return 1
    fi
    
    setup_cache_dirs
    cd "$PROJECT_ROOT"
    
    if [ ! -d "build/workspace/sources/$RECIPE_NAME" ]; then
        print_error "Devtool workspace not found for $RECIPE_NAME"
        echo "💡 Run '$0 setup' and '$0 build' first"
        return 1
    fi
    
    print_step "Running devtool deploy-target $RECIPE_NAME root@$TARGET_IP..."
    kas-container --ssh-agent --ssh-dir ${HOME}/.ssh \
        --runtime-args "-v ${HOME}/yocto:/var/cache" \
        shell kas/lmp-dynamicdevices-dev.yml \
        -c "devtool deploy-target $RECIPE_NAME root@$TARGET_IP"
    
    print_success "Application deployed to target board"
    echo "💡 Test the application: $0 test"
}

# Test deployed application
test_application() {
    print_step "Testing deployed $RECIPE_NAME on target board..."
    
    if ! check_target_board; then
        return 1
    fi
    
    print_step "Checking if application is installed..."
    if ssh root@"$TARGET_IP" "which eink-power-cli" >/dev/null 2>&1; then
        print_success "Application is installed on target"
        
        print_step "Running application help/version..."
        ssh root@"$TARGET_IP" "eink-power-cli --help" || true
        
        print_step "Testing basic functionality..."
        # Add specific tests for eink-power-cli here
        ssh root@"$TARGET_IP" "ls -la /usr/bin/eink*" || true
        
        print_success "Application testing complete"
        echo "💡 For debugging: $0 debug"
    else
        print_error "Application not found on target"
        echo "💡 Try redeploying: $0 deploy"
        return 1
    fi
}

# Set up remote debugging
setup_remote_debugging() {
    print_step "Setting up remote debugging for $RECIPE_NAME..."
    
    if ! check_target_board; then
        return 1
    fi
    
    print_step "Installing debugging tools on target..."
    ssh root@"$TARGET_IP" "opkg update && opkg install gdbserver" || true
    
    print_step "Setting up GDB debugging session..."
    echo "🐛 Remote debugging setup:"
    echo ""
    echo "On target board (run this in target SSH session):"
    echo "  gdbserver :$DEBUG_PORT /usr/bin/eink-power-cli [args]"
    echo ""
    echo "On development host:"
    echo "  gdb build/workspace/sources/$RECIPE_NAME/target/debug/eink-power-cli"
    echo "  (gdb) target remote $TARGET_IP:$DEBUG_PORT"
    echo "  (gdb) continue"
    echo ""
    echo "💡 For Rust debugging, you may need:"
    echo "  rust-gdb instead of gdb"
    
    print_success "Remote debugging setup complete"
}

# Complete workflow
complete_workflow() {
    print_step "Running complete devtool workflow for $RECIPE_NAME..."
    echo ""
    
    setup_devtool_workspace || return 1
    echo ""
    
    build_application || return 1
    echo ""
    
    deploy_application || return 1
    echo ""
    
    test_application || return 1
    echo ""
    
    print_success "Complete workflow finished successfully!"
    echo ""
    echo "🎉 Your application is now deployed and tested on the target board"
    echo "💡 Next steps:"
    echo "   - Make source code changes in: build/workspace/sources/$RECIPE_NAME/"
    echo "   - Rebuild and redeploy: $0 build && $0 deploy"
    echo "   - Set up debugging: $0 debug"
    echo "   - Finish workspace: $0 finish"
}

# Clean up devtool workspace
clean_workspace() {
    print_step "Cleaning up devtool workspace for $RECIPE_NAME..."
    setup_cache_dirs
    
    cd "$PROJECT_ROOT"
    
    if [ ! -d "build/workspace/sources/$RECIPE_NAME" ]; then
        print_warning "No devtool workspace found for $RECIPE_NAME"
        return 0
    fi
    
    print_step "Running devtool reset $RECIPE_NAME..."
    kas-container --ssh-agent --ssh-dir ${HOME}/.ssh \
        --runtime-args "-v ${HOME}/yocto:/var/cache" \
        shell kas/lmp-dynamicdevices-dev.yml \
        -c "devtool reset $RECIPE_NAME" || true
    
    print_success "Devtool workspace cleaned up"
}

# Finish devtool workspace
finish_workspace() {
    print_step "Finishing devtool workspace for $RECIPE_NAME..."
    setup_cache_dirs
    
    cd "$PROJECT_ROOT"
    
    if [ ! -d "build/workspace/sources/$RECIPE_NAME" ]; then
        print_error "No devtool workspace found for $RECIPE_NAME"
        return 1
    fi
    
    print_step "Running devtool finish $RECIPE_NAME meta-dynamicdevices-bsp..."
    kas-container --ssh-agent --ssh-dir ${HOME}/.ssh \
        --runtime-args "-v ${HOME}/yocto:/var/cache" \
        shell kas/lmp-dynamicdevices-dev.yml \
        -c "devtool finish $RECIPE_NAME meta-dynamicdevices-bsp"
    
    print_success "Changes committed to meta-dynamicdevices-bsp layer"
    echo "💡 Don't forget to commit and push your layer changes!"
}

# Parse command line arguments
STEP=""
while [[ $# -gt 0 ]]; do
    case $1 in
        setup|build|deploy|debug|test|finish|complete|clean)
            STEP="$1"
            shift
            ;;
        -t|--target)
            TARGET_IP="$2"
            shift 2
            ;;
        -m|--machine)
            MACHINE="$2"
            shift 2
            ;;
        -p|--port)
            DEBUG_PORT="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "❌ Error: Unknown option $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check if step was provided
if [ -z "$STEP" ]; then
    echo "❌ Error: No step specified"
    show_usage
    exit 1
fi

# Header
echo "🚀 Devtool Application Development Workflow"
echo "📦 Recipe: $RECIPE_NAME"
echo "🎛️  Machine: $MACHINE"
echo "🎯 Target: $TARGET_IP"
echo ""

# Execute the requested step
case "$STEP" in
    setup)
        setup_devtool_workspace
        ;;
    build)
        build_application
        ;;
    deploy)
        deploy_application
        ;;
    debug)
        setup_remote_debugging
        ;;
    test)
        test_application
        ;;
    finish)
        finish_workspace
        ;;
    complete)
        complete_workflow
        ;;
    clean)
        clean_workspace
        ;;
    *)
        echo "❌ Error: Unknown step: $STEP"
        show_usage
        exit 1
        ;;
esac

echo ""
echo "🎉 Step '$STEP' completed!"
