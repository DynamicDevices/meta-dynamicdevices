#!/bin/bash
# Extract Foundries.io cookie automatically
# This script tries multiple methods to get the cookie

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COOKIE_FILE="$PROJECT_ROOT/foundries-cookie.local"

echo "🔐 Foundries.io Cookie Extractor"
echo "================================"

# Method 1: Try to read from Chrome's cookie database
echo "📊 Method 1: Reading from Chrome cookie database..."

CHROME_COOKIES="$HOME/.config/google-chrome/Default/Cookies"
if [ -f "$CHROME_COOKIES" ]; then
    # Try to extract cookie (might fail if Chrome is running)
    COOKIE_VALUE=$(sqlite3 "$CHROME_COOKIES" \
        "SELECT value FROM cookies WHERE host_key LIKE '%foundries.io%' AND name = 'osfogsid';" \
        2>/dev/null | head -1)
    
    if [ -n "$COOKIE_VALUE" ] && [ "$COOKIE_VALUE" != "" ]; then
        echo "✅ Found cookie in Chrome database!"
        echo "FOUNDRIES_COOKIE=\"osfogsid=$COOKIE_VALUE\"" > "$COOKIE_FILE"
        echo "💾 Saved to $COOKIE_FILE"
        exit 0
    else
        echo "⚠️  Cookie database empty or locked (Chrome might be running)"
    fi
else
    echo "⚠️  Chrome cookie database not found"
fi

# Method 2: Try Firefox
echo ""
echo "📊 Method 2: Checking Firefox..."

FIREFOX_PROFILE=$(find ~/.mozilla/firefox -name "*.default*" -type d 2>/dev/null | head -1)
if [ -n "$FIREFOX_PROFILE" ] && [ -f "$FIREFOX_PROFILE/cookies.sqlite" ]; then
    COOKIE_VALUE=$(sqlite3 "$FIREFOX_PROFILE/cookies.sqlite" \
        "SELECT value FROM moz_cookies WHERE host LIKE '%foundries.io%' AND name = 'osfogsid';" \
        2>/dev/null | head -1)
    
    if [ -n "$COOKIE_VALUE" ] && [ "$COOKIE_VALUE" != "" ]; then
        echo "✅ Found cookie in Firefox database!"
        echo "FOUNDRIES_COOKIE=\"osfogsid=$COOKIE_VALUE\"" > "$COOKIE_FILE"
        echo "💾 Saved to $COOKIE_FILE"
        exit 0
    else
        echo "⚠️  No valid cookie found in Firefox"
    fi
else
    echo "⚠️  Firefox profile not found"
fi

# Method 3: Launch Chrome headless to get fresh cookie
echo ""
echo "📊 Method 3: Launching Chrome headless for fresh session..."

# Create temporary profile directory
TEMP_PROFILE=$(mktemp -d)
trap "rm -rf $TEMP_PROFILE" EXIT

echo "🌐 Opening Foundries.io in headless Chrome..."
echo "   (This will attempt to use existing credentials)"

# Launch Chrome headless and navigate to Foundries.io
timeout 30s google-chrome \
    --headless \
    --disable-gpu \
    --no-sandbox \
    --user-data-dir="$TEMP_PROFILE" \
    --dump-dom \
    "https://app.foundries.io/factories/dynamic-devices/" > /dev/null 2>&1 || true

# Try to extract cookie from temporary profile
if [ -f "$TEMP_PROFILE/Default/Cookies" ]; then
    COOKIE_VALUE=$(sqlite3 "$TEMP_PROFILE/Default/Cookies" \
        "SELECT value FROM cookies WHERE host_key LIKE '%foundries.io%' AND name = 'osfogsid';" \
        2>/dev/null | head -1)
    
    if [ -n "$COOKIE_VALUE" ] && [ "$COOKIE_VALUE" != "" ]; then
        echo "✅ Got fresh cookie from headless Chrome!"
        echo "FOUNDRIES_COOKIE=\"osfogsid=$COOKIE_VALUE\"" > "$COOKIE_FILE"
        echo "💾 Saved to $COOKIE_FILE"
        exit 0
    fi
fi

echo ""
echo "❌ Automatic cookie extraction failed"
echo ""
echo "📋 Manual extraction required:"
echo "1. Open Chrome: https://app.foundries.io/factories/dynamic-devices/"
echo "2. Press F12 → Network tab → Refresh"
echo "3. Click any app.foundries.io request"
echo "4. Copy Cookie header value"
echo "5. Run: echo 'FOUNDRIES_COOKIE=\"[cookie_value]\"' > $COOKIE_FILE"
echo ""
exit 1
