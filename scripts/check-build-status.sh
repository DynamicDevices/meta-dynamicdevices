#!/bin/bash
# Foundries.io Build Status Checker using REST API
# Usage: ./check-build-status.sh [build_number]

FACTORY="dynamic-devices"
TOKEN=$(grep access_token ~/.config/fioctl.yaml | cut -d' ' -f4)

if [ -z "$TOKEN" ]; then
    echo "Error: No API token found in ~/.config/fioctl.yaml"
    exit 1
fi

# Function to check recent E-ink builds
check_recent_eink_builds() {
    echo "🔍 Recent E-ink builds:"
    curl -s -H "Authorization: Bearer $TOKEN" \
         "https://api.foundries.io/ota/factories/$FACTORY/targets/" | \
    jq -r 'to_entries[] | 
           select(.value.custom.name | contains("imx93-jaguar-eink")) | 
           "\(.value.custom.version) \(.value.custom.createdAt) \(.value.custom.uri)"' | \
    sort -n | tail -10
    echo ""
}

# Function to check specific build
check_specific_build() {
    local build_num=$1
    echo "🎯 Checking build $build_num:"
    
    result=$(curl -s -H "Authorization: Bearer $TOKEN" \
                  "https://api.foundries.io/ota/factories/$FACTORY/targets/" | \
             jq -r --arg build "$build_num" '
                 to_entries[] | 
                 select(.value.custom.version == $build) | 
                 "\(.value.custom.version) \(.value.custom.createdAt) \(.value.custom.uri) \(.value.custom.name)"')
    
    if [ -n "$result" ]; then
        echo "✅ Build $build_num found: $result"
    else
        echo "❌ Build $build_num not found (may be building, failed, or queued)"
    fi
    echo ""
}

# Function to check build status via CI URL (if accessible)
check_build_logs() {
    local build_num=$1
    echo "📋 Build $build_num CI URL: https://ci.foundries.io/projects/$FACTORY/lmp/builds/$build_num"
    echo "🌐 Web Interface: https://app.foundries.io/factories/$FACTORY/targets/$build_num/"
    echo ""
}

# Main execution
echo "🏭 Foundries.io Build Status for Factory: $FACTORY"
echo "========================================================"
echo ""

if [ $# -eq 0 ]; then
    # No arguments - show recent builds
    check_recent_eink_builds
else
    # Check specific build number
    for build_num in "$@"; do
        check_specific_build "$build_num"
        check_build_logs "$build_num"
    done
fi

echo "💡 Note: Builds only appear here when completed. In-progress/failed builds"
echo "   require checking the web interface at https://app.foundries.io/factories/$FACTORY/targets/"
