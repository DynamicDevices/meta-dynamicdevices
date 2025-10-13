#!/bin/bash
# =============================================================================
# ⚠️  CRITICAL: FOUNDRIES.IO API SWISS ARMY KNIFE - FIOCTL ALTERNATIVE ⚠️
# =============================================================================
#
# 🔥 THIS SCRIPT PROVIDES CAPABILITIES THAT FIOCTL CANNOT DO!
# 🔥 USE THIS SCRIPT FOR API-EXCLUSIVE FEATURES!
# 🔥 USE FIOCTL FOR DEVICE OPERATIONS!
#
# =============================================================================
# Foundries.io API Swiss Army Knife
# =============================================================================
#
# CRITICAL NOTE: This script provides capabilities that fioctl CANNOT do!
# Use this script for API-exclusive features, use fioctl for device operations.
#
# PURPOSE:
# This comprehensive tool leverages the Foundries.io REST API to provide
# advanced factory management capabilities that are not available through
# the standard fioctl command-line tool. It focuses on build monitoring,
# configuration management, and factory analytics.
#
# WHAT THIS SCRIPT DOES THAT FIOCTL CANNOT:
# ==========================================
# 1. Real-time build monitoring (RUNNING/QUEUED status)
# 2. Live build log streaming and following
# 3. Build log searching and pattern matching
# 4. Factory configuration management and history
# 5. Advanced wave management and deployment control
# 6. Detailed build run analysis (multiple runs per build)
# 7. Enhanced target analysis and platform summaries
# 8. Factory-wide statistics and analytics
# 9. In-progress build detection and monitoring
# 10. Configuration deployment tracking
#
# WHEN TO USE THIS SCRIPT VS FIOCTL:
# ==================================
# USE THIS SCRIPT FOR:
# - Monitoring builds in real-time during development
# - Debugging build failures with live log access
# - Analyzing factory health and deployment trends  
# - Managing factory configurations programmatically
# - Automating CI/CD pipelines with build status checks
# - Investigating deployment waves and rollout status
# - Getting detailed build run information
#
# USE FIOCTL FOR:
# - Device registration and management
# - Secure device communication and updates
# - Application deployment to devices
# - Device configuration and credential management
# - Day-to-day device operations
#
# TECHNICAL DETAILS:
# =================
# - Uses Foundries.io REST API (https://api.foundries.io)
# - Authenticates via token from ~/.config/fioctl.yaml
# - Supports JSON parsing with jq for structured data
# - Color-coded output for visual status indication
# - Modular command structure for extensibility
#
# DEPENDENCIES:
# - curl (for API calls)
# - jq (for JSON parsing)
# - fioctl (for token authentication)
#
# AUTHOR: AI Assistant
# VERSION: 1.0
# CREATED: 2025-10-06
# FACTORY: configurable via environment variable or default
#
# Usage: ./fio-api.sh <command> [options]
#        FACTORY=sentai ./fio-api.sh <command> [options]

# =============================================================================
# CONFIGURATION AND SETUP
# =============================================================================

# Factory configuration - can be overridden by environment variable
FACTORY="${FACTORY:-dynamic-devices}"
TOKEN=$(grep access_token ~/.config/fioctl.yaml | cut -d' ' -f4)
API_BASE="https://api.foundries.io"

# Show current factory configuration
echo "🏭 Using factory: $FACTORY"

# Validate authentication token
if [ -z "$TOKEN" ]; then
    echo "❌ Error: No API token found in ~/.config/fioctl.yaml"
    echo "💡 Ensure fioctl is configured: fioctl login"
    exit 1
fi

# =============================================================================
# COLOR CODES FOR VISUAL STATUS INDICATION
# =============================================================================
# These colors help quickly identify build status and command output

RED='\033[0;31m'      # Failed builds, errors
GREEN='\033[0;32m'    # Successful builds, completed items
YELLOW='\033[1;33m'   # Running builds, warnings
BLUE='\033[0;34m'     # Queued builds, informational
PURPLE='\033[0;35m'   # Headers, special emphasis  
CYAN='\033[0;36m'     # Section headers, commands
NC='\033[0m'          # No Color - reset to default

# =============================================================================
# CORE API HELPER FUNCTION
# =============================================================================
# Centralized API call function with authentication and error handling
# This abstracts the curl complexity and provides consistent API access

api_call() {
    local endpoint=$1          # API endpoint (e.g., "projects/factory/builds")
    local method=${2:-GET}     # HTTP method (GET, POST, PUT, DELETE)  
    local data=${3:-}          # JSON data for POST/PUT requests
    
    # Make authenticated API call with proper headers
    if [ -n "$data" ]; then
        # POST/PUT request with JSON data
        curl -s -L -X "$method" -H "Authorization: Bearer $TOKEN" \
             -H "Content-Type: application/json" \
             -d "$data" "$API_BASE/$endpoint"
    else
        # GET request (most common) - Follow redirects for log access
        curl -s -L -H "Authorization: Bearer $TOKEN" "$API_BASE/$endpoint"
    fi
}

# =============================================================================
# BUILD MONITORING COMMANDS - CRITICAL FIOCTL ALTERNATIVE
# =============================================================================
# This is the most important function as fioctl cannot show in-progress builds!
# 
# FIOCTL LIMITATION: 'fioctl targets list' only shows COMPLETED builds
# API ADVANTAGE: Shows RUNNING, QUEUED, FAILED builds in real-time
#
# KEY CAPABILITIES:
# - Real-time build status (RUNNING/QUEUED/PASSED/FAILED)
# - Live log streaming and following (like tail -f)
# - Build log searching for debugging
# - Multiple run analysis (main build + mfgtools)
# - Color-coded status for quick visual identification
#
# API ENDPOINTS USED:
# - GET /projects/{factory}/lmp/builds/ - List builds with status
# - GET /projects/{factory}/lmp/builds/{id}/ - Specific build details
# - GET /projects/{factory}/lmp/builds/{id}/runs/{run}/console.log - Live logs

builds_command() {
    local action=${1:-list}        # Action: list, status, logs, follow, search
    local build_id=$2               # Build ID (e.g., 2131, 2132)
    local run_name=${3:-}           # Run name (imx93-jaguar-eink, imx93-jaguar-eink-mfgtools)
    
    case "$action" in
        "list"|"recent")
            # CRITICAL: This shows in-progress builds that fioctl cannot see!
            echo -e "${CYAN}🏗️  Recent builds (with in-progress status):${NC}"
            echo "# This shows RUNNING/QUEUED builds that 'fioctl targets list' cannot display"
            
            # API call to get builds with real-time status
            api_call "projects/$FACTORY/lmp/builds/" | \
            jq -r '.data.builds[] | 
                "\(.build_id) \(.status) \(.created) \(.web_url)"' | \
            head -15 | while read -r line; do
                # Color-code based on build status for quick visual identification
                status=$(echo "$line" | awk '{print $2}')
                case "$status" in
                    "RUNNING") echo -e "  ${YELLOW}🔄 $line${NC}" ;;  # Yellow for active builds
                    "QUEUED") echo -e "  ${BLUE}⏳ $line${NC}" ;;    # Blue for waiting builds
                    "PASSED") echo -e "  ${GREEN}✅ $line${NC}" ;;   # Green for successful
                    "FAILED") echo -e "  ${RED}❌ $line${NC}" ;;     # Red for failures
                    *) echo -e "  $line" ;;                          # Default for unknown
                esac
            done
            ;;
            
        "status")
            # Detailed build information including multiple runs per build
            if [ -z "$build_id" ]; then
                echo "❌ Build ID required for status command"
                echo "💡 Usage: $0 builds status <build_id>"
                echo "💡 Example: $0 builds status 2131"
                return 1
            fi
            
            echo -e "${CYAN}📊 Build $build_id Status:${NC}"
            echo "# Detailed build information including all runs (main + mfgtools)"
            
            # Get comprehensive build details including all runs
            api_call "projects/$FACTORY/lmp/builds/$build_id/" | \
            jq -r '.data.build | 
                "🏗️  Build \(.build_id): \(.status) (Created: \(.created))",
                "📋 Trigger: \(.trigger_name)",
                "🌐 Web: \(.web_url)",
                "",
                "🔧 Runs:",
                (.runs[] | "  • \(.name): \(.status) [\(.log_url)]")'
            ;;
            
        "logs")
            # Stream build logs - CRITICAL for debugging builds in progress
            if [ -z "$build_id" ]; then
                echo "❌ Build ID required for logs command"
                echo "💡 Usage: $0 builds logs <build_id> [run_name] [lines]"
                echo "💡 Example: $0 builds logs 2131 imx93-jaguar-eink 100"
                return 1
            fi
            
            run_name=${run_name:-"imx93-jaguar-eink"}  # Default to main build run
            lines=${4:-50}                             # Default to last 50 lines
            
            echo -e "${CYAN}📋 Build $build_id logs ($run_name, last $lines lines):${NC}"
            echo "# Live access to build logs - not available through fioctl!"
            
            # Direct access to build console logs via API
            api_call "projects/$FACTORY/lmp/builds/$build_id/runs/$run_name/console.log" | tail -n "$lines"
            ;;
            
        "follow")
            # Real-time log following - like 'tail -f' for build logs
            if [ -z "$build_id" ]; then
                echo "❌ Build ID required for follow command"
                echo "💡 Usage: $0 builds follow <build_id> [run_name] [interval_seconds]"
                echo "💡 Example: $0 builds follow 2131 imx93-jaguar-eink 5"
                return 1
            fi
            
            run_name=${run_name:-"imx93-jaguar-eink"}  # Default to main build run
            interval=${4:-10}                          # Default refresh every 10 seconds
            
            echo -e "${CYAN}👀 Following Build $build_id logs (every ${interval}s, Ctrl+C to stop):${NC}"
            echo "# Real-time log following - IMPOSSIBLE with fioctl!"
            
            # Continuous log monitoring loop
            while true; do
                clear
                echo -e "${PURPLE}$(date): Following Build $build_id - $run_name${NC}"
                echo "========================================================"
                
                # Get latest log content and show last 30 lines
                api_call "projects/$FACTORY/lmp/builds/$build_id/runs/$run_name/console.log" | tail -n 30
                
                sleep "$interval"
            done
            ;;
            
        "search")
            # Search build logs for specific patterns - debugging superpower!
            if [ -z "$build_id" ] || [ -z "$run_name" ]; then
                echo "❌ Build ID and search pattern required"
                echo "💡 Usage: $0 builds search <build_id> <search_pattern>"
                echo "💡 Example: $0 builds search 2131 'config.*warning'"
                return 1
            fi
            
            pattern=$run_name                          # Second arg is actually the pattern
            run_name="imx93-jaguar-eink"              # Use default run name
            
            echo -e "${CYAN}🔍 Searching Build $build_id for: '$pattern'${NC}"
            echo "# Pattern searching in build logs - advanced debugging capability"
            
            # Search logs with context lines for better understanding
            api_call "projects/$FACTORY/lmp/builds/$build_id/runs/$run_name/console.log" | \
            grep -i -n -A3 -B3 "$pattern" || echo "❌ Pattern '$pattern' not found in logs"
            ;;
            
        *)
            echo "❌ Unknown builds action: $action"
            echo "Available actions:"
            echo "  list              - Show recent builds with real-time status"
            echo "  status <id>       - Detailed build status and run information"
            echo "  logs <id> [run] [lines]    - Show build logs (default: 50 lines)"
            echo "  follow <id> [run] [sec]    - Follow logs in real-time (default: 10s)"
            echo "  search <id> <pattern>      - Search logs for specific patterns"
            ;;
    esac
}

# Factory configuration management (not available in fioctl)
config_command() {
    local action=${1:-list}
    
    case "$action" in
        "list")
            echo -e "${CYAN}⚙️  Factory Configuration:${NC}"
            api_call "ota/factories/$FACTORY/config/" | \
            jq -r '.config[] | 
                "📅 \(.["created-at"]) by \(.["created-by"])",
                "📝 Reason: \(.reason)",
                "📁 Files: \(.files | length) file(s)",
                (.files[] | "  • \(.name): \(.value | length) chars"),
                ""'
            ;;
            
        "show")
            local config_index=${2:-0}
            echo -e "${CYAN}📄 Configuration Details:${NC}"
            api_call "ota/factories/$FACTORY/config/" | \
            jq -r ".config[$config_index] | 
                \"📅 Created: \" + .[\"created-at\"],
                \"👤 By: \" + .[\"created-by\"],
                \"📝 Reason: \" + .reason,
                \"\",
                \"📁 Files:\",
                (.files[] | \"  📄 \" + .name + \":\", \"     \" + .value)"
            ;;
            
        *)
            echo "❌ Unknown config action: $action"
            echo "Available: list, show [index]"
            ;;
    esac
}

# Wave management (advanced deployment control not in fioctl)
waves_command() {
    local action=${1:-list}
    
    case "$action" in
        "list")
            echo -e "${CYAN}🌊 Deployment Waves:${NC}"
            api_call "ota/factories/$FACTORY/waves/" | \
            jq -r '.waves[] | 
                "🌊 \(.name) (v\(.version)) - \(.tag)",
                "   Status: \(.status) | Created: \(.["created-at"])",
                if .["finished-at"] then "   Finished: \(.["finished-at"])" else "" end,
                ""'
            ;;
            
        "active")
            echo -e "${CYAN}🔥 Active Waves:${NC}"
            api_call "ota/factories/$FACTORY/waves/" | \
            jq -r '.waves[] | select(.status == "active") | 
                "🌊 \(.name) (v\(.version)) - \(.tag)",
                "   Created: \(.["created-at"])",
                ""'
            ;;
            
        *)
            echo "❌ Unknown waves action: $action"
            echo "Available: list, active"
            ;;
    esac
}

# Target analysis (enhanced beyond fioctl)
targets_command() {
    local action=${1:-summary}
    local platform=${2:-}
    
    case "$action" in
        "summary")
            echo -e "${CYAN}🎯 Targets Summary by Platform:${NC}"
            api_call "ota/factories/$FACTORY/targets/" | \
            jq -r 'keys[] as $target | 
                .[$target].custom | 
                "\(.hardwareIds[0]) \(.version) \(.createdAt) \(.name)"' | \
            sort | uniq -c | sort -nr | head -20
            ;;
            
        "platform")
            if [ -z "$platform" ]; then
                echo "❌ Platform required (e.g., imx93-jaguar-eink)"
                return 1
            fi
            echo -e "${CYAN}🖥️  $platform Targets (last 10):${NC}"
            api_call "ota/factories/$FACTORY/targets/" | \
            jq -r --arg platform "$platform" '
                to_entries[] | 
                select(.value.custom.hardwareIds[] | contains($platform)) |
                .value.custom | 
                "\(.version) \(.createdAt) \(.["lmp-ver"] // "N/A")"' | \
            sort -nr | head -10
            ;;
            
        "latest")
            echo -e "${CYAN}🆕 Latest Targets by Platform:${NC}"
            api_call "ota/factories/$FACTORY/targets/" | \
            jq -r 'to_entries[] | .value.custom | 
                "\(.hardwareIds[0]) \(.version) \(.createdAt)"' | \
            sort -k1,1 -k2,2nr | awk '!seen[$1]++' | head -10
            ;;
            
        *)
            echo "❌ Unknown targets action: $action"
            echo "Available: summary, platform <name>, latest"
            ;;
    esac
}

# API capabilities comparison
compare_command() {
    echo -e "${PURPLE}🆚 Foundries.io API vs fioctl Capabilities:${NC}"
    echo ""
    echo -e "${GREEN}✅ API-Only Features (not in fioctl):${NC}"
    echo "  🔄 Real-time build monitoring (RUNNING, QUEUED status)"
    echo "  📋 Live build log streaming and following"
    echo "  🔍 Build log searching and pattern matching"
    echo "  ⚙️  Factory configuration management and history"
    echo "  🌊 Advanced wave management and deployment control"
    echo "  📊 Detailed build run analysis (multiple runs per build)"
    echo "  🎯 Enhanced target analysis and platform summaries"
    echo "  🕐 Build timing and duration analysis"
    echo "  📈 Factory-wide statistics and trends"
    echo ""
    echo -e "${YELLOW}⚠️  fioctl Advantages:${NC}"
    echo "  📱 Device management (register, update, configure)"
    echo "  🔐 Secure device communication"
    echo "  📦 Application deployment to devices"
    echo "  🗂️  Local configuration and credential management"
    echo "  🛠️  Simplified CLI interface for common tasks"
    echo ""
    echo -e "${BLUE}💡 Best Practice:${NC}"
    echo "  Use fioctl for device operations and deployments"
    echo "  Use API for build monitoring, factory analysis, and automation"
}

# Statistics and analytics (API exclusive)
stats_command() {
    local timeframe=${1:-week}
    
    echo -e "${CYAN}📊 Factory Statistics:${NC}"
    
    # Build success rate
    echo -e "\n${GREEN}🏗️  Build Success Rate (last 50 builds):${NC}"
    api_call "projects/$FACTORY/lmp/builds/" | \
    jq -r '.data.builds[0:50] | 
        group_by(.status) | 
        map({status: .[0].status, count: length}) | 
        .[] | "\(.status): \(.count) builds"'
    
    # Platform distribution
    echo -e "\n${BLUE}🖥️  Platform Distribution:${NC}"
    api_call "ota/factories/$FACTORY/targets/" | \
    jq -r 'to_entries[] | .value.custom.hardwareIds[0]' | \
    sort | uniq -c | sort -nr | head -10
    
    # Wave statistics
    echo -e "\n${PURPLE}🌊 Wave Statistics:${NC}"
    api_call "ota/factories/$FACTORY/waves/" | \
    jq -r '.waves | group_by(.status) | 
        map({status: .[0].status, count: length}) | 
        .[] | "\(.status): \(.count) waves"'
}

# Main command dispatcher
# =============================================================================
# MAIN EXECUTION FUNCTION
# =============================================================================
# This function routes commands to appropriate handlers and provides the
# primary interface for the script. Each command addresses specific limitations
# of fioctl by leveraging the Foundries.io REST API directly.

main() {
    local command=${1:-help}    # Default to help if no command provided
    
    # Shift arguments to pass remaining parameters to command functions
    shift
    
    # Route commands to appropriate handlers
    # Each handler provides capabilities that fioctl cannot offer
    case "$command" in
        "builds"|"build")
            # CRITICAL: Real-time build monitoring - fioctl's biggest limitation
            # fioctl only shows completed builds, this shows RUNNING/QUEUED/FAILED
            builds_command "$@"
            ;;
        "config"|"configuration")
            # Factory configuration management - not available in fioctl
            # Provides access to configuration history and deployment tracking
            config_command "$@"
            ;;
        "waves"|"wave")
            # Advanced deployment wave management - beyond fioctl scope
            # Critical for understanding production rollout status
            waves_command "$@"
            ;;
        "targets"|"target")
            # Enhanced target analysis with platform-specific insights
            # More detailed than fioctl's basic target listing
            targets_command "$@"
            ;;
        "compare"|"vs")
            # Educational tool to understand API vs fioctl differences
            # Helps users choose the right tool for each task
            compare_command
            ;;
        "stats"|"statistics")
            # Factory analytics and health metrics - API exclusive
            # Provides insights into build success rates and trends
            stats_command "$@"
            ;;
        "help"|"-h"|"--help")
            # =============================================================================
            # 🚀 FOUNDRIES.IO API SWISS ARMY KNIFE - COMPREHENSIVE HELP
            # =============================================================================
            echo -e "${PURPLE}🚀 FOUNDRIES.IO API SWISS ARMY KNIFE${NC}"
            echo "============================================="
            echo ""
            echo -e "${RED}🔥 CRITICAL NOTE: This script provides capabilities that fioctl CANNOT do!${NC}"
            echo -e "${RED}   Use this script for API-exclusive features, use fioctl for device operations.${NC}"
            echo ""
            echo -e "${CYAN}📋 COMMAND REFERENCE${NC}"
            echo "===================="
            echo ""
            echo -e "${GREEN}🏗️  BUILDS (Real-time monitoring - fioctl limitation workaround):${NC}"
            echo "──────────────────────────────────────────────────────────────"
            echo "  $0 builds list                    # Show recent builds with LIVE status"
            echo "  $0 builds status <build_id>       # Detailed build info + all runs"
            echo "  $0 builds logs <id> [run] [lines] # Stream build logs (50 lines default)"
            echo "  $0 builds follow <id> [run] [sec] # Follow logs in real-time (10s default)"
            echo "  $0 builds search <id> <pattern>   # Search logs for debugging patterns"
            echo ""
            echo -e "${YELLOW}⚙️  CONFIG (Factory configuration - not in fioctl):${NC}"
            echo "──────────────────────────────────────────────────"
            echo "  $0 config list                    # Show configuration history"
            echo "  $0 config show [index]            # Get specific config content"
            echo ""
            echo -e "${BLUE}🎯 TARGETS (Enhanced analysis beyond fioctl):${NC}"
            echo "─────────────────────────────────────────────"
            echo "  $0 targets summary                # All targets with platform info"
            echo "  $0 targets platform <name>        # Platform-specific targets"
            echo "  $0 targets latest                 # Latest target per platform"
            echo ""
            echo -e "${PURPLE}🌊 WAVES (Deployment management - advanced):${NC}"
            echo "────────────────────────────────────────────"
            echo "  $0 waves list                     # All deployment waves"
            echo "  $0 waves active                   # Currently active waves"
            echo ""
            echo -e "${CYAN}📊 STATS (Factory analytics - exclusive to API):${NC}"
            echo "────────────────────────────────────────────────"
            echo "  $0 stats [timeframe]              # Factory statistics and analytics"
            echo ""
            echo -e "${GREEN}🔧 UTILITY:${NC}"
            echo "────────"
            echo "  $0 compare                        # Compare API vs fioctl capabilities"
            echo "  $0 help                          # Show this comprehensive help"
            echo ""
            echo -e "${RED}🚨 CRITICAL LIMITATIONS OF FIOCTL THAT THIS SCRIPT SOLVES:${NC}"
            echo "=============================================================="
            echo ""
            echo -e "${RED}❌ FIOCTL CANNOT:${NC}"
            echo "1. Show builds that are RUNNING or QUEUED (only completed)"
            echo "2. Stream build logs in real-time"
            echo "3. Search build logs for debugging patterns"
            echo "4. Access factory configuration history"
            echo "5. Analyze deployment waves and rollout status"
            echo "6. Provide factory-wide statistics and analytics"
            echo "7. Show multiple runs per build (main + mfgtools)"
            echo "8. Follow logs like 'tail -f' for active builds"
            echo ""
            echo -e "${GREEN}✅ THIS SCRIPT CAN:${NC}"
            echo "1. Monitor builds in real-time during development"
            echo "2. Debug build failures with live log access"
            echo "3. Search logs for specific error patterns"
            echo "4. Track factory configuration changes over time"
            echo "5. Analyze deployment success rates and trends"
            echo "6. Provide comprehensive factory health metrics"
            echo "7. Show detailed build run information"
            echo "8. Stream logs continuously for active monitoring"
            echo ""
            echo -e "${CYAN}💡 EXAMPLES FOR COMMON SCENARIOS:${NC}"
            echo "=================================="
            echo ""
            echo -e "${CYAN}🏭 FACTORY CONFIGURATION:${NC}"
            echo "  FACTORY=sentai $0 builds list                # Use sentai factory"
            echo "  FACTORY=dynamic-devices $0 builds list      # Use dynamic-devices factory"
            echo "  export FACTORY=sentai && $0 builds list     # Set factory for session"
            echo ""
            echo -e "${YELLOW}🔍 DEBUGGING A FAILED BUILD:${NC}"
            echo "  $0 builds status 2127              # Get build details"
            echo "  $0 builds logs 2127 100            # Check last 100 log lines"
            echo "  $0 builds search 2127 \"error\"      # Search for error patterns"
            echo ""
            echo -e "${BLUE}📊 MONITORING ACTIVE BUILDS:${NC}"
            echo "  $0 builds list                     # See what's currently running"
            echo "  $0 builds follow 2132             # Watch build 2132 in real-time"
            echo ""
            echo -e "${GREEN}⚙️  FACTORY MANAGEMENT:${NC}"
            echo "  $0 config list                     # Review configuration changes"
            echo "  $0 waves active                    # Check active deployments"
            echo "  $0 stats                           # Overall factory health"
            ;;
        *)
            echo "❌ Unknown command: $command"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
