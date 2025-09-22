#!/bin/bash
# Check Foundries.io build status using browser cookie
# Usage: ./scripts/check-foundries-build.sh 2027

set -e

TARGET=${1:-2027}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COOKIE_FILE="$PROJECT_ROOT/foundries-cookie.local"

# Load cookie from local file
if [ -f "$COOKIE_FILE" ]; then
    source "$COOKIE_FILE"
else
    echo "❌ Cookie file not found: $COOKIE_FILE"
    echo "Please create the file and add your Foundries.io cookie"
    exit 1
fi

if [ -z "$FOUNDRIES_COOKIE" ]; then
    echo "❌ FOUNDRIES_COOKIE not set in $COOKIE_FILE"
    echo "Please extract your browser cookie and update the file"
    exit 1
fi

echo "🔍 Checking Foundries.io build $TARGET..."
echo ""

# Check build status
echo "📊 Build Status:"
BUILD_STATUS=$(curl -s -H "Cookie: $FOUNDRIES_COOKIE" \
    "https://api.foundries.io/projects/dynamic-devices/lmp/builds/$TARGET/" | \
    jq -r '.data.build.status // "NOT_FOUND"' 2>/dev/null)

if [ "$BUILD_STATUS" = "NOT_FOUND" ] || [ -z "$BUILD_STATUS" ]; then
    echo "❌ Build $TARGET not found or cookie invalid"
    echo "   - Check if build number is correct"
    echo "   - Update cookie in $COOKIE_FILE"
    exit 1
fi

echo "   Status: $BUILD_STATUS"

# Get build details
BUILD_INFO=$(curl -s -H "Cookie: $FOUNDRIES_COOKIE" \
    "https://api.foundries.io/projects/dynamic-devices/lmp/builds/$TARGET/")

if echo "$BUILD_INFO" | jq -e '.data.build' >/dev/null 2>&1; then
    echo "   Started: $(echo "$BUILD_INFO" | jq -r '.data.build.created_at')"
    echo "   Updated: $(echo "$BUILD_INFO" | jq -r '.data.build.updated_at')"
    
    # Show runs status
    echo ""
    echo "🏃 Build Runs:"
    echo "$BUILD_INFO" | jq -r '.data.runs[] | "   \(.name): \(.status)"' 2>/dev/null || echo "   No runs data available"
    
    # If build is running, show recent log
    if [ "$BUILD_STATUS" = "RUNNING" ]; then
        echo ""
        echo "📝 Recent Log (last 10 lines):"
        curl -s -H "Cookie: $FOUNDRIES_COOKIE" \
            "https://api.foundries.io/projects/dynamic-devices/lmp/builds/$TARGET/runs/imx93-jaguar-eink/console.log" | \
            tail -10 2>/dev/null || echo "   Log not available yet"
    fi
else
    echo "❌ Failed to parse build information"
fi

echo ""
echo "🌐 View in browser: https://app.foundries.io/factories/dynamic-devices/targets/$TARGET/"
