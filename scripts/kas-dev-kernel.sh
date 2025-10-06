#!/bin/bash
#
# KAS Kernel Development Script
#
# This script provides rapid kernel development workflow using kas-container.
# Supports kernel building, module building, and deployment to target boards.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"

# Default values
ACTION=""
TARGET_IP=""
MODULE_NAME=""
MACHINE="${KAS_MACHINE:-imx93-jaguar-eink}"
DEPLOY_METHOD="scp"  # scp, tftp, or program

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 ACTION [OPTIONS]

Rapid kernel development workflow using kas-container.

ACTIONS:
    build-kernel        Build kernel only
    build-modules       Build kernel modules only  
    build-dtbs          Build device tree blobs only
    deploy-kernel       Deploy kernel to running target
    deploy-modules      Deploy modules to running target
    modify              Set up devtool workspace for kernel modification
    finish              Finish devtool workspace and commit changes

OPTIONS:
    -m, --machine MACHINE    Target machine (default: \$KAS_MACHINE or imx93-jaguar-eink)
    -t, --target IP          Target board IP address (required for deploy actions)
    --module NAME           Module name (for module-specific actions)
    --method METHOD         Deploy method: scp, tftp, program (default: scp)
    -h, --help              Show this help message

ENVIRONMENT VARIABLES:
    KAS_MACHINE             Target machine
    TARGET_IP               Default target IP address

EXAMPLES:
    # Build kernel only (fast iteration)
    $0 build-kernel --machine imx93-jaguar-eink
    
    # Deploy kernel to running target
    $0 deploy-kernel --target 192.168.1.100
    
    # Set up kernel modification workspace
    $0 modify --machine imx93-jaguar-eink
    
    # Build and deploy in one command
    $0 build-kernel && $0 deploy-kernel --target 192.168.1.100
    
    # Deploy modules after kernel change
    $0 deploy-modules --target 192.168.1.100

PREREQUISITES:
    1. KAS development environment set up
    2. Target board accessible via SSH (for scp deployment)
    3. Or TFTP server configured (for tftp deployment)

EOF
}

# Ensure yocto cache directories exist (following existing pattern)
setup_cache_dirs() {
    if [ ! -d ~/yocto ]; then
        mkdir -p ~/yocto
        mkdir -p ~/yocto/downloads
        mkdir -p ~/yocto/persistent
        mkdir -p ~/yocto/sstate
        chmod 755 ~/yocto
        chmod 755 ~/yocto/downloads
        chmod 755 ~/yocto/persistent
        chmod 755 ~/yocto/sstate
    fi
}

# Build kernel using kas
build_kernel() {
    echo "🔨 Building kernel for $MACHINE..."
    setup_cache_dirs
    
    kas-container --ssh-agent --ssh-dir ${HOME}/.ssh \
        --runtime-args "-v ${HOME}/yocto:/var/cache" \
        shell kas/lmp-dynamicdevices.yml \
        -c "bitbake virtual/kernel -c deploy"
    
    echo "✅ Kernel build complete for $MACHINE"
    echo "📁 Artifacts in: build/tmp/deploy/images/$MACHINE/"
}

# Build kernel modules only
build_modules() {
    echo "🔨 Building kernel modules for $MACHINE..."
    setup_cache_dirs
    
    kas-container --ssh-agent --ssh-dir ${HOME}/.ssh \
        --runtime-args "-v ${HOME}/yocto:/var/cache" \
        shell kas/lmp-dynamicdevices.yml \
        -c "bitbake virtual/kernel -c compile && bitbake virtual/kernel -c modules_install"
    
    echo "✅ Kernel modules build complete"
}

# Build device tree blobs only
build_dtbs() {
    echo "🔨 Building device tree blobs for $MACHINE..."
    setup_cache_dirs
    
    kas-container --ssh-agent --ssh-dir ${HOME}/.ssh \
        --runtime-args "-v ${HOME}/yocto:/var/cache" \
        shell kas/lmp-dynamicdevices.yml \
        -c "bitbake virtual/kernel -c compile && bitbake virtual/kernel -c dtbs"
    
    echo "✅ Device tree build complete"
}

# Deploy kernel to target via SCP
deploy_kernel_scp() {
    if [ -z "$TARGET_IP" ]; then
        echo "❌ Error: Target IP required for SCP deployment"
        echo "Use: $0 deploy-kernel --target <ip-address>"
        exit 1
    fi
    
    echo "📦 Deploying kernel to $TARGET_IP via SCP..."
    
    DEPLOY_DIR="build/tmp/deploy/images/$MACHINE"
    
    if [ ! -d "$DEPLOY_DIR" ]; then
        echo "❌ Error: Deploy directory not found: $DEPLOY_DIR"
        echo "Run '$0 build-kernel' first"
        exit 1
    fi
    
    # Copy kernel image
    if [ -f "$DEPLOY_DIR/Image" ]; then
        echo "📤 Copying kernel image..."
        scp "$DEPLOY_DIR/Image" root@$TARGET_IP:/boot/Image.new
        ssh root@$TARGET_IP "mv /boot/Image.new /boot/Image"
    fi
    
    # Copy device tree blobs
    echo "📤 Copying device tree blobs..."
    scp "$DEPLOY_DIR"/*.dtb root@$TARGET_IP:/boot/ 2>/dev/null || true
    
    echo "🔄 Syncing and preparing for reboot..."
    ssh root@$TARGET_IP "sync"
    
    echo "✅ Kernel deployed successfully"
    echo "💡 Reboot target to use new kernel: ssh root@$TARGET_IP reboot"
}

# Deploy modules to target via SCP
deploy_modules_scp() {
    if [ -z "$TARGET_IP" ]; then
        echo "❌ Error: Target IP required for module deployment"
        exit 1
    fi
    
    echo "📦 Deploying kernel modules to $TARGET_IP..."
    
    MODULES_DIR="build/tmp/work-shared/$MACHINE/kernel-build-artifacts"
    
    if [ ! -d "$MODULES_DIR" ]; then
        echo "❌ Error: Modules directory not found"
        echo "Run '$0 build-modules' first"
        exit 1
    fi
    
    # Sync modules (this is a simplified approach)
    echo "📤 Syncing kernel modules..."
    ssh root@$TARGET_IP "mkdir -p /lib/modules.new"
    
    # Copy modules - this is a basic implementation
    # In practice, you'd want to be more selective about which modules to copy
    rsync -av --progress "$MODULES_DIR/" root@$TARGET_IP:/lib/modules.new/ || true
    
    ssh root@$TARGET_IP "sync"
    echo "✅ Modules deployed (may require reboot for some modules)"
}

# Set up devtool workspace for kernel modification
setup_devtool_workspace() {
    echo "🔧 Setting up devtool workspace for kernel modification..."
    setup_cache_dirs
    
    kas-container --ssh-agent --ssh-dir ${HOME}/.ssh \
        --runtime-args "-v ${HOME}/yocto:/var/cache" \
        shell kas/lmp-dynamicdevices.yml \
        -c "devtool modify virtual/kernel"
    
    echo "✅ Devtool workspace created"
    echo "📁 Kernel source: build/workspace/sources/linux-lmp-fslc-imx/"
    echo "💡 Make your changes, then run: $0 build-kernel"
}

# Finish devtool workspace
finish_devtool_workspace() {
    echo "🏁 Finishing devtool workspace..."
    setup_cache_dirs
    
    kas-container --ssh-agent --ssh-dir ${HOME}/.ssh \
        --runtime-args "-v ${HOME}/yocto:/var/cache" \
        shell kas/lmp-dynamicdevices.yml \
        -c "devtool finish virtual/kernel meta-dynamicdevices-bsp"
    
    echo "✅ Changes committed to meta-dynamicdevices-bsp layer"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        build-kernel|build-modules|build-dtbs|deploy-kernel|deploy-modules|modify|finish)
            ACTION="$1"
            shift
            ;;
        -m|--machine)
            MACHINE="$2"
            shift 2
            ;;
        -t|--target)
            TARGET_IP="$2"
            shift 2
            ;;
        --module)
            MODULE_NAME="$2"
            shift 2
            ;;
        --method)
            DEPLOY_METHOD="$2"
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

# Check if action was provided
if [ -z "$ACTION" ]; then
    echo "❌ Error: No action specified"
    show_usage
    exit 1
fi

# Use environment variable if TARGET_IP not set via command line
if [ -z "$TARGET_IP" ] && [ -n "${TARGET_IP:-}" ]; then
    TARGET_IP="$TARGET_IP"
fi

# Change to project root
cd "$PROJECT_ROOT"

echo "🎯 KAS Kernel Development - $ACTION for $MACHINE"

# Execute the requested action
case "$ACTION" in
    build-kernel)
        build_kernel
        ;;
    build-modules)
        build_modules
        ;;
    build-dtbs)
        build_dtbs
        ;;
    deploy-kernel)
        case "$DEPLOY_METHOD" in
            scp)
                deploy_kernel_scp
                ;;
            *)
                echo "❌ Error: Deploy method '$DEPLOY_METHOD' not implemented yet"
                echo "Available methods: scp"
                exit 1
                ;;
        esac
        ;;
    deploy-modules)
        case "$DEPLOY_METHOD" in
            scp)
                deploy_modules_scp
                ;;
            *)
                echo "❌ Error: Deploy method '$DEPLOY_METHOD' not implemented yet"
                exit 1
                ;;
        esac
        ;;
    modify)
        setup_devtool_workspace
        ;;
    finish)
        finish_devtool_workspace
        ;;
    *)
        echo "❌ Error: Unknown action: $ACTION"
        show_usage
        exit 1
        ;;
esac

echo "🎉 Action '$ACTION' completed successfully!"
