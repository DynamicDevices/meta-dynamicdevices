#!/bin/bash
#
# Enhanced Foundries.io Build Monitor
# Shows real-time progress with timestamps and better feedback
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
FACTORY="dynamic-devices"
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

print_progress() {
    echo -e "${CYAN}[$(date '+%H:%M:%S')] [PROGRESS]${NC} $1"
}

show_usage() {
    cat << EOF
Usage: $0 [BUILD_ID] [OPTIONS]

Enhanced Foundries.io build monitor with real-time progress updates.

Arguments:
  BUILD_ID         Build ID to monitor (required)

Options:
  -i, --interval SECONDS   Refresh interval in seconds (default: 30)
  -t, --timeout SECONDS    Maximum wait time in seconds (default: 7200)
  -h, --help               Show this help

Examples:
  $0 2048                  # Monitor build 2048
  $0 2048 --interval 15    # Monitor with 15-second refresh

Press Ctrl+C to stop monitoring.
EOF
}

get_latest_builds() {
    local pattern="$1"
    fioctl -f dynamic-devices targets list | grep "$pattern" | head -5 | while read -r line; do
        local version=$(echo "$line" | awk '{print $1}')
        local tags=$(echo "$line" | awk '{print $2}')
        echo "  Build $version: $tags"
    done
}

format_duration() {
    local seconds=$1
    local hours=$((seconds / 3600))
    local minutes=$(((seconds % 3600) / 60))
    local secs=$((seconds % 60))
    
    if [ $hours -gt 0 ]; then
        printf "%dh %02dm %02ds" $hours $minutes $secs
    elif [ $minutes -gt 0 ]; then
        printf "%dm %02ds" $minutes $secs
    else
        printf "%ds" $secs
    fi
}

monitor_build() {
    local build_id="$1"
    local interval="$2"
    local timeout="$3"
    
    local start_time=$(date +%s)
    local elapsed=0
    local check_count=0
    
    print_status "🔍 Enhanced Build Monitor for Build $build_id"
    print_status "Refresh interval: ${interval}s | Timeout: $(format_duration $timeout)"
    print_status "Started at $(date '+%Y-%m-%d %H:%M:%S')"
    echo
    
    # Show recent builds for context
    print_status "Recent imx93-jaguar-eink builds for reference:"
    get_latest_builds "main-imx93-jaguar-eink"
    echo
    
    print_progress "Waiting for Build $build_id to appear in targets list..."
    
    while [ $elapsed -lt $timeout ]; do
        check_count=$((check_count + 1))
        
        # Check if build exists in targets
        local build_info=$(fioctl -f dynamic-devices targets show "$build_id" 2>&1)
        local exit_code=$?
        
        if [ $exit_code -eq 0 ] && [[ "$build_info" != *"ERROR"* ]]; then
            echo
            print_success "🎉 Build $build_id completed successfully!"
            echo
            print_status "Build details:"
            echo "$build_info" | sed 's/^/  /'
            echo
            print_status "Build $build_id is now available for deployment and testing"
            return 0
        fi
        
        # Show progress with timestamp
        local current_time=$(date +%s)
        elapsed=$((current_time - start_time))
        local remaining=$((timeout - elapsed))
        
        # Show progress every 5 checks (every ~50 seconds with 10s interval)
        if [ $((check_count % 5)) -eq 0 ]; then
            print_progress "Check #${check_count}: Build $build_id still building... ($(format_duration $elapsed) elapsed, $(format_duration $remaining) remaining)"
        fi
        
        sleep "$interval"
    done
    
    # Timeout reached
    echo
    print_error "❌ Build $build_id failed or timed out after $(format_duration $timeout)"
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
print_status "🚀 Enhanced Foundries.io Build Monitor v2.0"
print_status "============================================"

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
trap 'echo; print_status "Monitoring stopped by user"; exit 0' INT

monitor_build "$BUILD_ID" "$INTERVAL" "$TIMEOUT"
