#!/bin/bash
#
# KAS Recipe Development Script
#
# This script provides rapid recipe development workflow using kas-container.
# Supports recipe modification, building, testing, and deployment.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"

# Default values
ACTION=""
RECIPE_NAME=""
TARGET_IP=""
MACHINE="${KAS_MACHINE:-imx93-jaguar-eink}"
SOURCE_PATH=""

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 ACTION [OPTIONS]

Rapid recipe development workflow using kas-container.

ACTIONS:
    modify RECIPE           Set up devtool workspace for recipe modification
    add RECIPE [SOURCE]     Add new recipe from source (URL or local path)
    build RECIPE            Build specific recipe
    deploy RECIPE           Deploy recipe to running target
    test RECIPE             Build and deploy recipe for testing
    finish RECIPE           Finish devtool workspace and commit changes
    clean RECIPE            Clean recipe build artifacts
    shell RECIPE            Open devshell for recipe debugging

OPTIONS:
    -m, --machine MACHINE    Target machine (default: \$KAS_MACHINE or imx93-jaguar-eink)
    -t, --target IP          Target board IP address (required for deploy actions)
    -s, --source PATH        Source path/URL for new recipes
    -h, --help              Show this help message

ENVIRONMENT VARIABLES:
    KAS_MACHINE             Target machine
    TARGET_IP               Default target IP address

EXAMPLES:
    # Modify existing recipe
    $0 modify eink-power-cli
    
    # Add new recipe from GitHub
    $0 add my-tool https://github.com/user/my-tool.git
    
    # Add new recipe from local source
    $0 add my-local-tool --source /path/to/source
    
    # Build specific recipe
    $0 build eink-power-cli
    
    # Build and deploy for testing
    $0 test eink-power-cli --target 192.168.1.100
    
    # Deploy recipe to target
    $0 deploy eink-power-cli --target 192.168.1.100
    
    # Open devshell for debugging
    $0 shell eink-power-cli
    
    # Finish workspace and commit changes
    $0 finish eink-power-cli

PREREQUISITES:
    1. KAS development environment set up
    2. Target board accessible via SSH (for deployment)

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

# Modify existing recipe using devtool
modify_recipe() {
    if [ -z "$RECIPE_NAME" ]; then
        echo "❌ Error: Recipe name required"
        exit 1
    fi
    
    echo "🔧 Setting up devtool workspace for $RECIPE_NAME..."
    setup_cache_dirs
    
    kas-container --ssh-agent --ssh-dir ${HOME}/.ssh \
        --runtime-args "-v ${HOME}/yocto:/var/cache" \
        shell kas/lmp-dynamicdevices.yml \
        -c "devtool modify $RECIPE_NAME"
    
    echo "✅ Devtool workspace created for $RECIPE_NAME"
    echo "📁 Source: build/workspace/sources/$RECIPE_NAME/"
    echo "💡 Make your changes, then run: $0 build $RECIPE_NAME"
}

# Add new recipe from source
add_recipe() {
    if [ -z "$RECIPE_NAME" ]; then
        echo "❌ Error: Recipe name required"
        exit 1
    fi
    
    echo "➕ Adding new recipe: $RECIPE_NAME"
    setup_cache_dirs
    
    if [ -n "$SOURCE_PATH" ]; then
        echo "📥 Using source: $SOURCE_PATH"
        kas-container --ssh-agent --ssh-dir ${HOME}/.ssh \
            --runtime-args "-v ${HOME}/yocto:/var/cache" \
            shell kas/lmp-dynamicdevices.yml \
            -c "devtool add $RECIPE_NAME $SOURCE_PATH"
    else
        # Interactive mode - let devtool prompt for source
        kas-container --ssh-agent --ssh-dir ${HOME}/.ssh \
            --runtime-args "-v ${HOME}/yocto:/var/cache" \
            shell kas/lmp-dynamicdevices.yml \
            -c "devtool add $RECIPE_NAME"
    fi
    
    echo "✅ Recipe $RECIPE_NAME added successfully"
    echo "📁 Source: build/workspace/sources/$RECIPE_NAME/"
}

# Build specific recipe
build_recipe() {
    if [ -z "$RECIPE_NAME" ]; then
        echo "❌ Error: Recipe name required"
        exit 1
    fi
    
    echo "🔨 Building recipe: $RECIPE_NAME for $MACHINE..."
    setup_cache_dirs
    
    kas-container --ssh-agent --ssh-dir ${HOME}/.ssh \
        --runtime-args "-v ${HOME}/yocto:/var/cache" \
        shell kas/lmp-dynamicdevices.yml \
        -c "bitbake $RECIPE_NAME"
    
    echo "✅ Recipe $RECIPE_NAME built successfully"
}

# Deploy recipe to target
deploy_recipe() {
    if [ -z "$RECIPE_NAME" ]; then
        echo "❌ Error: Recipe name required"
        exit 1
    fi
    
    if [ -z "$TARGET_IP" ]; then
        echo "❌ Error: Target IP required for deployment"
        echo "Use: $0 deploy $RECIPE_NAME --target <ip-address>"
        exit 1
    fi
    
    echo "📦 Deploying $RECIPE_NAME to $TARGET_IP..."
    setup_cache_dirs
    
    kas-container --ssh-agent --ssh-dir ${HOME}/.ssh \
        --runtime-args "-v ${HOME}/yocto:/var/cache" \
        shell kas/lmp-dynamicdevices.yml \
        -c "devtool deploy-target $RECIPE_NAME root@$TARGET_IP"
    
    echo "✅ Recipe $RECIPE_NAME deployed successfully"
}

# Test recipe (build + deploy)
test_recipe() {
    if [ -z "$RECIPE_NAME" ]; then
        echo "❌ Error: Recipe name required"
        exit 1
    fi
    
    echo "🧪 Testing recipe: $RECIPE_NAME"
    
    # Build first
    build_recipe
    
    # Then deploy if target specified
    if [ -n "$TARGET_IP" ]; then
        deploy_recipe
        echo "💡 Recipe deployed to target. Test your changes!"
    else
        echo "💡 Recipe built successfully. Specify --target to deploy for testing."
    fi
}

# Open devshell for recipe debugging
recipe_shell() {
    if [ -z "$RECIPE_NAME" ]; then
        echo "❌ Error: Recipe name required"
        exit 1
    fi
    
    echo "🐚 Opening devshell for $RECIPE_NAME..."
    setup_cache_dirs
    
    kas-container --ssh-agent --ssh-dir ${HOME}/.ssh \
        --runtime-args "-v ${HOME}/yocto:/var/cache" \
        shell kas/lmp-dynamicdevices.yml \
        -c "bitbake $RECIPE_NAME -c devshell"
}

# Clean recipe build artifacts
clean_recipe() {
    if [ -z "$RECIPE_NAME" ]; then
        echo "❌ Error: Recipe name required"
        exit 1
    fi
    
    echo "🧹 Cleaning $RECIPE_NAME build artifacts..."
    setup_cache_dirs
    
    kas-container --ssh-agent --ssh-dir ${HOME}/.ssh \
        --runtime-args "-v ${HOME}/yocto:/var/cache" \
        shell kas/lmp-dynamicdevices.yml \
        -c "bitbake $RECIPE_NAME -c cleanall"
    
    echo "✅ Recipe $RECIPE_NAME cleaned"
}

# Finish devtool workspace
finish_recipe() {
    if [ -z "$RECIPE_NAME" ]; then
        echo "❌ Error: Recipe name required"
        exit 1
    fi
    
    echo "🏁 Finishing devtool workspace for $RECIPE_NAME..."
    setup_cache_dirs
    
    kas-container --ssh-agent --ssh-dir ${HOME}/.ssh \
        --runtime-args "-v ${HOME}/yocto:/var/cache" \
        shell kas/lmp-dynamicdevices.yml \
        -c "devtool finish $RECIPE_NAME meta-dynamicdevices-bsp"
    
    echo "✅ Changes for $RECIPE_NAME committed to meta-dynamicdevices-bsp layer"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        modify|add|build|deploy|test|finish|clean|shell)
            ACTION="$1"
            if [[ $# -gt 1 ]] && [[ ! "$2" =~ ^- ]]; then
                RECIPE_NAME="$2"
                shift 2
            else
                shift
            fi
            ;;
        -m|--machine)
            MACHINE="$2"
            shift 2
            ;;
        -t|--target)
            TARGET_IP="$2"
            shift 2
            ;;
        -s|--source)
            SOURCE_PATH="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            # If no action set yet, treat as recipe name
            if [ -z "$ACTION" ]; then
                echo "❌ Error: Unknown action or option: $1"
                show_usage
                exit 1
            else
                # Additional arguments after action+recipe
                shift
            fi
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

echo "🎯 KAS Recipe Development - $ACTION"
if [ -n "$RECIPE_NAME" ]; then
    echo "📦 Recipe: $RECIPE_NAME"
fi
echo "🎛️  Machine: $MACHINE"

# Execute the requested action
case "$ACTION" in
    modify)
        modify_recipe
        ;;
    add)
        add_recipe
        ;;
    build)
        build_recipe
        ;;
    deploy)
        deploy_recipe
        ;;
    test)
        test_recipe
        ;;
    finish)
        finish_recipe
        ;;
    clean)
        clean_recipe
        ;;
    shell)
        recipe_shell
        ;;
    *)
        echo "❌ Error: Unknown action: $ACTION"
        show_usage
        exit 1
        ;;
esac

echo "🎉 Action '$ACTION' completed successfully!"
