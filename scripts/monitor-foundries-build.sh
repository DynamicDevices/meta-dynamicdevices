#!/bin/bash
# Monitor Foundries.io build using OAuth token
# Usage: ./scripts/monitor-foundries-build.sh 2027

set -e

TARGET=${1:-2027}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Extract OAuth token from fioctl config
FIOCTL_CONFIG="$HOME/.config/fioctl.yaml"
if [ ! -f "$FIOCTL_CONFIG" ]; then
    echo "❌ fioctl config not found: $FIOCTL_CONFIG"
    exit 1
fi

ACCESS_TOKEN=$(grep "access_token:" "$FIOCTL_CONFIG" | awk '{print $2}')
if [ -z "$ACCESS_TOKEN" ]; then
    echo "❌ No access token found in fioctl config"
    exit 1
fi

echo "🔍 Monitoring Foundries.io Build $TARGET"
echo "========================================"
echo ""

# Function to get build status
get_build_status() {
    curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
        "https://api.foundries.io/projects/dynamic-devices/lmp/builds/$TARGET/" 2>/dev/null
}

# Function to display build info
show_build_info() {
    local build_data="$1"
    
    if ! echo "$build_data" | jq -e '.data.build' >/dev/null 2>&1; then
        echo "❌ Build $TARGET not found or API error"
        return 1
    fi
    
    echo "📊 Build Status:"
    echo "$build_data" | jq -r '.data.build | 
        "   Build ID: \(.build_id // "N/A")
   Status: \(.status // "UNKNOWN")
   Created: \(.created_at // "N/A")
   Updated: \(.updated_at // "N/A")"'
    
    # Show runs if available
    if echo "$build_data" | jq -e '.data.runs[]?' >/dev/null 2>&1; then
        echo ""
        echo "🏃 Build Runs:"
        echo "$build_data" | jq -r '.data.runs[] | "   \(.name): \(.status)"'
    else
        echo ""
        echo "🏃 Build Runs: Not started yet"
    fi
    
    echo ""
}

# Monitor loop
echo "⏱️  Starting monitoring (Ctrl+C to stop)..."
echo ""

while true; do
    BUILD_DATA=$(get_build_status)
    
    if [ $? -eq 0 ]; then
        clear
        echo "🔍 Monitoring Foundries.io Build $TARGET - $(date)"
        echo "========================================"
        echo ""
        
        show_build_info "$BUILD_DATA"
        
        # Check if build is complete
        STATUS=$(echo "$BUILD_DATA" | jq -r '.data.build.status // "UNKNOWN"')
        if [[ "$STATUS" == "PASSED" || "$STATUS" == "FAILED" ]]; then
            echo "🏁 Build completed with status: $STATUS"
            echo ""
            echo "🌐 View details: https://app.foundries.io/factories/dynamic-devices/targets/$TARGET/"
            break
        fi
        
        echo "🔄 Refreshing in 30 seconds..."
    else
        echo "❌ Failed to get build status"
    fi
    
    sleep 30
done
