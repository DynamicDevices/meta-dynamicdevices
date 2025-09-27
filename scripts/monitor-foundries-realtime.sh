#!/bin/bash
#
# Real-time Foundries.io Build Monitor
# Monitors build progress with live updates and failure detection
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
FACTORY="dynamic-devices"
FIOCTL_CONFIG="$HOME/.config/fioctl.yaml"
REFRESH_INTERVAL=10  # seconds
MAX_LOG_LINES=50

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

print_build_status() {
    local status="$1"
    local message="$2"
    case "$status" in
        "RUNNING")
            echo -e "${BLUE}[$(date '+%H:%M:%S')] [BUILD]${NC} $message"
            ;;
        "PASSED")
            echo -e "${GREEN}[$(date '+%H:%M:%S')] [BUILD]${NC} $message"
            ;;
        "FAILED")
            echo -e "${RED}[$(date '+%H:%M:%S')] [BUILD]${NC} $message"
            ;;
        "QUEUED")
            echo -e "${CYAN}[$(date '+%H:%M:%S')] [BUILD]${NC} $message"
            ;;
        *)
            echo -e "${YELLOW}[$(date '+%H:%M:%S')] [BUILD]${NC} $message"
            ;;
    esac
}

print_header() {
    echo -e "${BOLD}${BLUE}$1${NC}"
}

show_usage() {
    cat << EOF
Usage: $0 [BUILD_ID] [OPTIONS]

Monitor Foundries.io builds in real-time with live status updates.

Arguments:
  BUILD_ID         Specific build ID to monitor (optional - monitors latest if not specified)

Options:
  -f, --factory FACTORY    Factory name (default: dynamic-devices)
  -i, --interval SECONDS   Refresh interval in seconds (default: 10)
  -l, --lines LINES        Number of log lines to show (default: 50)
  -q, --quiet              Quiet mode - only show status changes
  -v, --verbose            Verbose mode - show detailed information
  --no-logs                Don't show build logs, only status
  --follow-logs            Continuously follow logs for running builds
  -h, --help               Show this help

Examples:
  $0                       # Monitor latest build
  $0 2045                  # Monitor specific build 2045
  $0 2045 --follow-logs    # Monitor build 2045 with live log following
  $0 --interval 5          # Monitor with 5-second refresh
  $0 --quiet               # Only show status changes

The script will:
- Show real-time build status updates
- Display build progress and timing
- Show failure details immediately
- Follow build logs for running builds
- Provide summary when build completes

Press Ctrl+C to stop monitoring.
EOF
}

get_oauth_token() {
    if [ ! -f "$FIOCTL_CONFIG" ]; then
        print_error "fioctl config not found at $FIOCTL_CONFIG"
        print_error "Please run 'fioctl login' first"
        return 1
    fi
    
    local token=$(grep -A1 "access_token:" "$FIOCTL_CONFIG" | tail -1 | sed 's/^[[:space:]]*access_token:[[:space:]]*//' | tr -d '"')
    
    if [ -z "$token" ]; then
        print_error "No OAuth token found in fioctl config"
        print_error "Please run 'fioctl login' to authenticate"
        return 1
    fi
    
    echo "$token"
}

api_call() {
    local endpoint="$1"
    local token="$2"
    
    curl -s -H "Authorization: Bearer $token" \
         -H "Accept: application/json" \
         "https://api.foundries.io/projects/$FACTORY/lmp/$endpoint" 2>/dev/null
}

get_latest_build() {
    local token="$1"
    
    local response=$(api_call "builds/" "$token")
    if [ $? -ne 0 ] || [ -z "$response" ]; then
        return 1
    fi
    
    echo "$response" | jq -r '.[0].build_id // empty' 2>/dev/null
}

get_build_info() {
    local build_id="$1"
    local token="$2"
    
    api_call "builds/$build_id/" "$token"
}

get_build_logs() {
    local build_id="$1"
    local run_name="$2"
    local token="$3"
    local lines="$4"
    
    local log_url=$(api_call "builds/$build_id/runs/$run_name/console.log" "$token")
    if [[ "$log_url" == *"Redirecting"* ]]; then
        # Extract the actual URL from the redirect
        local actual_url=$(echo "$log_url" | grep -o 'https://storage.googleapis.com[^"]*' | head -1)
        if [ -n "$actual_url" ]; then
            curl -s "$actual_url" | tail -n "$lines" 2>/dev/null
        fi
    else
        echo "$log_url" | tail -n "$lines" 2>/dev/null
    fi
}

format_duration() {
    local start_time="$1"
    local end_time="$2"
    
    if [ -z "$start_time" ] || [ -z "$end_time" ]; then
        echo "Unknown"
        return
    fi
    
    # Convert ISO timestamps to epoch
    local start_epoch=$(date -d "$start_time" +%s 2>/dev/null || echo "0")
    local end_epoch=$(date -d "$end_time" +%s 2>/dev/null || echo "0")
    
    if [ "$start_epoch" -eq 0 ] || [ "$end_epoch" -eq 0 ]; then
        echo "Unknown"
        return
    fi
    
    local duration=$((end_epoch - start_epoch))
    
    if [ "$duration" -lt 60 ]; then
        echo "${duration}s"
    elif [ "$duration" -lt 3600 ]; then
        echo "$((duration / 60))m $((duration % 60))s"
    else
        echo "$((duration / 3600))h $((duration % 3600 / 60))m"
    fi
}

monitor_build() {
    local build_id="$1"
    local token="$2"
    local quiet="$3"
    local verbose="$4"
    local show_logs="$5"
    local follow_logs="$6"
    
    local last_status=""
    local last_run_statuses=""
    local build_start_time=""
    
    print_header "🔍 Monitoring Build $build_id"
    print_header "================================"
    
    while true; do
        local build_info=$(get_build_info "$build_id" "$token")
        
        if [ $? -ne 0 ] || [ -z "$build_info" ]; then
            print_error "Failed to get build info for build $build_id"
            sleep "$REFRESH_INTERVAL"
            continue
        fi
        
        # Parse build information
        local status=$(echo "$build_info" | jq -r '.build.status // "UNKNOWN"')
        local created=$(echo "$build_info" | jq -r '.build.created // ""')
        local completed=$(echo "$build_info" | jq -r '.build.completed // ""')
        local web_url=$(echo "$build_info" | jq -r '.build.web_url // ""')
        
        # Get run information
        local runs=$(echo "$build_info" | jq -r '.build.runs[]? | "\(.name):\(.status)"' | tr '\n' ' ')
        
        # Show status change
        if [ "$status" != "$last_status" ] || [ "$runs" != "$last_run_statuses" ]; then
            if [ -z "$build_start_time" ]; then
                build_start_time="$created"
                print_status "Build $build_id started at $(date -d "$created" '+%H:%M:%S' 2>/dev/null || echo "$created")"
                if [ -n "$web_url" ]; then
                    print_status "Web URL: $web_url"
                fi
            fi
            
            print_build_status "$status" "Build $build_id: $status"
            
            # Show run statuses
            if [ "$verbose" = "true" ] || [ "$status" != "$last_status" ]; then
                echo "$build_info" | jq -r '.build.runs[]? | "  \(.name): \(.status)"' | while read -r line; do
                    if [ -n "$line" ]; then
                        local run_status=$(echo "$line" | cut -d: -f2 | tr -d ' ')
                        print_build_status "$run_status" "$line"
                    fi
                done
            fi
            
            last_status="$status"
            last_run_statuses="$runs"
        fi
        
        # Show logs for failed runs
        if [ "$show_logs" = "true" ] && [[ "$status" == "FAILED" || "$status" == "RUNNING_WITH_FAILURES" ]]; then
            echo "$build_info" | jq -r '.build.runs[]? | select(.status == "FAILED") | .name' | while read -r run_name; do
                if [ -n "$run_name" ]; then
                    print_error "Failure logs for $run_name:"
                    echo "----------------------------------------"
                    get_build_logs "$build_id" "$run_name" "$token" "$MAX_LOG_LINES" | sed 's/^/  /'
                    echo "----------------------------------------"
                fi
            done
        fi
        
        # Follow logs for running builds
        if [ "$follow_logs" = "true" ] && [ "$status" = "RUNNING" ]; then
            echo "$build_info" | jq -r '.build.runs[]? | select(.status == "RUNNING") | .name' | head -1 | while read -r run_name; do
                if [ -n "$run_name" ]; then
                    print_status "Latest logs from $run_name:"
                    echo "----------------------------------------"
                    get_build_logs "$build_id" "$run_name" "$token" 20 | sed 's/^/  /'
                    echo "----------------------------------------"
                fi
            done
        fi
        
        # Check if build is complete
        if [[ "$status" == "PASSED" || "$status" == "FAILED" ]]; then
            local duration=$(format_duration "$created" "$completed")
            print_build_status "$status" "Build $build_id completed: $status (Duration: $duration)"
            
            # Show final summary
            print_header "📊 Build $build_id Summary"
            print_header "=========================="
            echo "$build_info" | jq -r '.build.runs[]? | "  \(.name): \(.status) (\(if .completed then ((.completed | fromdateiso8601) - (.created | fromdateiso8601) | tostring + "s") else "running" end))"'
            
            if [ "$status" = "PASSED" ]; then
                print_success "🎉 Build $build_id completed successfully!"
            else
                print_error "❌ Build $build_id failed"
                if [ "$show_logs" = "true" ]; then
                    print_error "Check the failure logs above for details"
                fi
            fi
            
            break
        fi
        
        if [ "$quiet" != "true" ]; then
            echo -n "."
        fi
        
        sleep "$REFRESH_INTERVAL"
    done
}

# Parse command line arguments
BUILD_ID=""
QUIET="false"
VERBOSE="false"
SHOW_LOGS="true"
FOLLOW_LOGS="false"

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--factory)
            FACTORY="$2"
            shift 2
            ;;
        -i|--interval)
            REFRESH_INTERVAL="$2"
            shift 2
            ;;
        -l|--lines)
            MAX_LOG_LINES="$2"
            shift 2
            ;;
        -q|--quiet)
            QUIET="true"
            shift
            ;;
        -v|--verbose)
            VERBOSE="true"
            shift
            ;;
        --no-logs)
            SHOW_LOGS="false"
            shift
            ;;
        --follow-logs)
            FOLLOW_LOGS="true"
            shift
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

# Main execution
print_header "🔍 Foundries.io Real-time Build Monitor"
print_header "========================================"

# Get OAuth token
print_status "Getting OAuth token from fioctl..."
TOKEN=$(get_oauth_token)
if [ $? -ne 0 ]; then
    exit 1
fi
print_status "✅ OAuth token obtained"

# Get build ID if not specified
if [ -z "$BUILD_ID" ]; then
    print_status "Getting latest build ID..."
    BUILD_ID=$(get_latest_build "$TOKEN")
    if [ $? -ne 0 ] || [ -z "$BUILD_ID" ]; then
        print_error "Failed to get latest build ID"
        exit 1
    fi
    print_status "Latest build ID: $BUILD_ID"
fi

# Validate build exists
print_status "Validating build $BUILD_ID exists..."
BUILD_INFO=$(get_build_info "$BUILD_ID" "$TOKEN")
if [ $? -ne 0 ] || [ -z "$BUILD_INFO" ]; then
    print_error "Build $BUILD_ID not found or API error"
    exit 1
fi
print_status "✅ Build $BUILD_ID found"

# Start monitoring
print_status "Starting real-time monitoring (Ctrl+C to stop)..."
print_status "Refresh interval: ${REFRESH_INTERVAL}s"
echo

trap 'print_status "Monitoring stopped"; exit 0' INT

monitor_build "$BUILD_ID" "$TOKEN" "$QUIET" "$VERBOSE" "$SHOW_LOGS" "$FOLLOW_LOGS"

