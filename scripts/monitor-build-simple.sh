#!/bin/bash
#
# Simple Foundries.io Build Monitor
# Uses fioctl to monitor build completion and detect failures
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
REFRESH_INTERVAL=30  # seconds
MAX_WAIT_TIME=7200   # 2 hours in seconds

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')] [INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] [WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] [ERROR]${NC} $1"
}

print_success() {
    echo -e "${MAGENTA}[$(date '+%H:%M:%S')] [SUCCESS]${NC} $1"
}

show_usage() {
    cat << EOF
Usage: $0 [BUILD_ID] [OPTIONS]

Monitor Foundries.io builds using fioctl targets list.

Arguments:
  BUILD_ID         Build ID to monitor (required)

Options:
  -i, --interval SECONDS   Refresh interval in seconds (default: 30)
  -t, --timeout SECONDS    Maximum wait time in seconds (default: 7200)
  -h, --help               Show this help

Examples:
  $0 2046                  # Monitor build 2046
  $0 2046 --interval 10    # Monitor with 10-second refresh
  $0 2046 --timeout 3600   # Monitor with 1-hour timeout

The script will:
- Check if the build appears in fioctl targets list
- Report when build completes successfully
- Report if build fails (doesn't appear after timeout)
- Show latest successful builds for reference

Press Ctrl+C to stop monitoring.
EOF
}

get_latest_builds() {
    local pattern="$1"
    fioctl -f dynamic-devices targets list | grep "$pattern" | head -10 | while read -r line; do
        local version=$(echo "$line" | awk '{print $1}')
        local tags=$(echo "$line" | awk '{print $2}')
        echo "  Build $version: $tags"
    done
}

monitor_build() {
    local build_id="$1"
    local interval="$2"
    local timeout="$3"
    
    local start_time=$(date +%s)
    local elapsed=0
    
    print_status "Monitoring Build $build_id (timeout: ${timeout}s, interval: ${interval}s)"
    print_status "Started at $(date)"
    echo
    
    # Show recent builds for context
    print_status "Recent imx93-jaguar-eink builds for reference:"
    get_latest_builds "main-imx93-jaguar-eink"
    echo
    
    while [ $elapsed -lt $timeout ]; do
        # Check if build exists in targets
        local build_info=$(fioctl -f dynamic-devices targets show "$build_id" 2>&1)
        local exit_code=$?
        
        if [ $exit_code -eq 0 ] && [[ "$build_info" != *"ERROR"* ]]; then
            print_success "🎉 Build $build_id completed successfully!"
            echo
            print_status "Build details:"
            echo "$build_info" | sed 's/^/  /'
            echo
            print_status "Build $build_id is now available for deployment"
            return 0
        fi
        
        # Show progress
        local current_time=$(date +%s)
        elapsed=$((current_time - start_time))
        local remaining=$((timeout - elapsed))
        
        if [ $((elapsed % 300)) -eq 0 ] && [ $elapsed -gt 0 ]; then
            print_status "Still waiting for Build $build_id... (${elapsed}s elapsed, ${remaining}s remaining)"
        else
            echo -n "."
        fi
        
        sleep "$interval"
    done
    
    # Timeout reached
    echo
    print_error "❌ Build $build_id failed or timed out after ${timeout}s"
    print_error "Build $build_id did not appear in targets list"
    echo
    print_status "This usually means:"
    print_status "  1. Build failed during compilation"
    print_status "  2. Build was cancelled"
    print_status "  3. Build is taking longer than expected"
    echo
    print_status "Check the Foundries.io web interface for details:"
    print_status "  https://app.foundries.io/factories/dynamic-devices/targets/$build_id/"
    echo
    print_status "Recent successful builds:"
    get_latest_builds "main-imx93-jaguar-eink"
    
    return 1
}

# Parse command line arguments
BUILD_ID=""
INTERVAL="$REFRESH_INTERVAL"
TIMEOUT="$MAX_WAIT_TIME"

while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--interval)
            INTERVAL="$2"
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        -*)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
        *)
            if [ -z "$BUILD_ID" ]; then
                BUILD_ID="$1"
            else
                print_error "Multiple build IDs specified"
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate arguments
if [ -z "$BUILD_ID" ]; then
    print_error "Build ID is required"
    show_usage
    exit 1
fi

if ! [[ "$BUILD_ID" =~ ^[0-9]+$ ]]; then
    print_error "Build ID must be a number"
    exit 1
fi

if ! [[ "$INTERVAL" =~ ^[0-9]+$ ]] || [ "$INTERVAL" -lt 5 ]; then
    print_error "Interval must be a number >= 5"
    exit 1
fi

if ! [[ "$TIMEOUT" =~ ^[0-9]+$ ]] || [ "$TIMEOUT" -lt 60 ]; then
    print_error "Timeout must be a number >= 60"
    exit 1
fi

# Main execution
print_status "🔍 Simple Foundries.io Build Monitor"
print_status "===================================="

# Check fioctl is available
if ! command -v fioctl >/dev/null 2>&1; then
    print_error "fioctl command not found"
    print_error "Please install fioctl and authenticate first"
    exit 1
fi

# Test fioctl access
if ! fioctl -f dynamic-devices targets list >/dev/null 2>&1; then
    print_error "fioctl authentication failed"
    print_error "Please run 'fioctl login' to authenticate"
    exit 1
fi

print_status "✅ fioctl authentication verified"

# Start monitoring
trap 'print_status "Monitoring stopped"; exit 0' INT

monitor_build "$BUILD_ID" "$INTERVAL" "$TIMEOUT"
