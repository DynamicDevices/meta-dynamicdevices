#!/bin/bash
# Enhanced Foundries.io Build Monitor with Real-Time Log Access
# Usage: ./monitor-build-logs.sh [build_number] [options]

FACTORY="dynamic-devices"
TOKEN=$(grep access_token ~/.config/fioctl.yaml | cut -d' ' -f4)

if [ -z "$TOKEN" ]; then
    echo "Error: No API token found in ~/.config/fioctl.yaml"
    exit 1
fi

# Function to get build status and runs
get_build_status() {
    local build_num=$1
    curl -s -H "Authorization: Bearer $TOKEN" \
         "https://api.foundries.io/projects/$FACTORY/lmp/builds/$build_num/" | \
    jq -r '
        .data.build |
        "🏗️  Build \(.build_id): \(.status) (Created: \(.created))",
        "🌐 Web: \(.web_url)",
        "",
        "📋 Runs:",
        (.runs[] | "  • \(.name): \(.status) - \(.log_url)")
    '
}

# Function to get recent builds with status
get_recent_builds() {
    echo "🔍 Recent E-ink builds (last 10):"
    curl -s -H "Authorization: Bearer $TOKEN" \
         "https://api.foundries.io/projects/$FACTORY/lmp/builds/" | \
    jq -r '
        .data.builds[] | 
        select(.runs[] | .name | contains("imx93-jaguar-eink")) |
        "\(.build_id) \(.status) \(.created) \(.web_url)"
    ' | head -10 | while read -r line; do
        echo "  $line"
    done
    echo ""
}

# Function to tail build logs in real-time
tail_build_logs() {
    local build_num=$1
    local run_name=${2:-"imx93-jaguar-eink"}
    local lines=${3:-50}
    
    echo "📋 Tailing logs for Build $build_num - $run_name (last $lines lines):"
    echo "========================================================"
    
    local log_url="https://api.foundries.io/projects/$FACTORY/lmp/builds/$build_num/runs/$run_name/console.log"
    
    curl -s -H "Authorization: Bearer $TOKEN" "$log_url" | tail -n "$lines"
}

# Function to follow build logs (simulate tail -f)
follow_build_logs() {
    local build_num=$1
    local run_name=${2:-"imx93-jaguar-eink"}
    local interval=${3:-10}
    
    echo "👀 Following logs for Build $build_num - $run_name (refresh every ${interval}s):"
    echo "Press Ctrl+C to stop"
    echo "========================================================"
    
    local log_url="https://api.foundries.io/projects/$FACTORY/lmp/builds/$build_num/runs/$run_name/console.log"
    local last_size=0
    
    while true; do
        # Get current log size
        local current_content=$(curl -s -H "Authorization: Bearer $TOKEN" "$log_url")
        local current_size=$(echo "$current_content" | wc -c)
        
        # If log grew, show new content
        if [ "$current_size" -gt "$last_size" ]; then
            clear
            echo "👀 Following Build $build_num - $run_name (Updated: $(date))"
            echo "========================================================"
            echo "$current_content" | tail -n 30
            echo ""
            echo "📊 Log size: $current_size bytes (+$((current_size - last_size)))"
        fi
        
        last_size=$current_size
        sleep "$interval"
    done
}

# Function to check for config warnings in logs
check_config_warnings() {
    local build_num=$1
    local run_name=${2:-"imx93-jaguar-eink"}
    
    echo "⚠️  Checking for kernel config warnings in Build $build_num:"
    echo "========================================================"
    
    local log_url="https://api.foundries.io/projects/$FACTORY/lmp/builds/$build_num/runs/$run_name/console.log"
    
    curl -s -H "Authorization: Bearer $TOKEN" "$log_url" | \
    grep -i -A5 -B5 "config.*warning\|config.*error\|specified values did not make it" || \
    echo "✅ No config warnings found!"
}

# Function to search logs for specific patterns
search_logs() {
    local build_num=$1
    local pattern=$2
    local run_name=${3:-"imx93-jaguar-eink"}
    
    echo "🔍 Searching Build $build_num logs for: '$pattern'"
    echo "========================================================"
    
    local log_url="https://api.foundries.io/projects/$FACTORY/lmp/builds/$build_num/runs/$run_name/console.log"
    
    curl -s -H "Authorization: Bearer $TOKEN" "$log_url" | \
    grep -i -n -A3 -B3 "$pattern" || \
    echo "❌ Pattern '$pattern' not found in logs"
}

# Main execution
case "${1:-help}" in
    "help"|"-h"|"--help")
        echo "🏭 Enhanced Foundries.io Build Monitor"
        echo "======================================"
        echo ""
        echo "Usage:"
        echo "  $0                          - Show recent builds"
        echo "  $0 <build_num>              - Show build status and runs"
        echo "  $0 <build_num> tail [lines] - Show last N lines of logs (default: 50)"
        echo "  $0 <build_num> follow [sec] - Follow logs in real-time (default: 10s)"
        echo "  $0 <build_num> config       - Check for kernel config warnings"
        echo "  $0 <build_num> search <pat> - Search logs for pattern"
        echo ""
        echo "Examples:"
        echo "  $0 2131"
        echo "  $0 2131 tail 100"
        echo "  $0 2131 follow 5"
        echo "  $0 2131 config"
        echo "  $0 2131 search mcumgr"
        ;;
    
    [0-9]*)
        build_num=$1
        action=${2:-status}
        
        case "$action" in
            "status")
                get_build_status "$build_num"
                ;;
            "tail")
                lines=${3:-50}
                tail_build_logs "$build_num" "imx93-jaguar-eink" "$lines"
                ;;
            "follow")
                interval=${3:-10}
                follow_build_logs "$build_num" "imx93-jaguar-eink" "$interval"
                ;;
            "config")
                check_config_warnings "$build_num"
                ;;
            "search")
                if [ -z "$3" ]; then
                    echo "Error: Search pattern required"
                    echo "Usage: $0 $build_num search <pattern>"
                    exit 1
                fi
                search_logs "$build_num" "$3"
                ;;
            *)
                echo "Unknown action: $action"
                echo "Use '$0 help' for usage information"
                exit 1
                ;;
        esac
        ;;
        
    *)
        get_recent_builds
        ;;
esac
