#!/bin/bash
#
# Automated Foundries.io Cookie Extraction
# Uses headless browser automation to get fresh cookies
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COOKIE_FILE="$PROJECT_ROOT/foundries-cookie.local"
TEMP_DIR="/tmp/foundries-cookie-$$"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}$1${NC}"
}

cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}

trap cleanup EXIT

print_header "🔐 Automated Foundries.io Cookie Extraction"
print_header "============================================"

# Method 1: Try existing Chrome session (if logged in)
print_status "Method 1: Checking existing Chrome session..."

# Create temp profile directory
mkdir -p "$TEMP_DIR"

# Try to extract from existing Chrome session
CHROME_COOKIES="$HOME/.config/google-chrome/Default/Cookies"
if [ -f "$CHROME_COOKIES" ]; then
    # Copy cookies to temp location to avoid lock issues
    cp "$CHROME_COOKIES" "$TEMP_DIR/Cookies" 2>/dev/null || true
    
    if [ -f "$TEMP_DIR/Cookies" ]; then
        COOKIE_VALUE=$(sqlite3 "$TEMP_DIR/Cookies" \
            "SELECT value FROM cookies WHERE host_key LIKE '%foundries.io%' AND name = 'osfogsid' ORDER BY creation_utc DESC LIMIT 1;" \
            2>/dev/null | head -1)
        
        if [ -n "$COOKIE_VALUE" ] && [ "$COOKIE_VALUE" != "" ]; then
            print_status "✅ Found existing cookie in Chrome!"
            
            # Test if cookie is still valid
            TEST_RESULT=$(curl -s -H "Cookie: osfogsid=$COOKIE_VALUE" \
                "https://api.foundries.io/projects/dynamic-devices/lmp/builds/" | head -1)
            
            if [[ "$TEST_RESULT" != *"Authorization Required"* ]] && [[ "$TEST_RESULT" == *"{"* ]]; then
                print_status "✅ Cookie is valid!"
                echo "FOUNDRIES_COOKIE=\"osfogsid=$COOKIE_VALUE\"" > "$COOKIE_FILE"
                print_status "💾 Saved to $COOKIE_FILE"
                exit 0
            else
                print_warning "⚠️ Cookie exists but is expired"
            fi
        fi
    fi
fi

# Method 2: Automated browser login using Chrome headless
print_status "Method 2: Automated browser login..."

# Check if we can use Chrome with existing profile
if command -v google-chrome &> /dev/null; then
    print_status "🌐 Opening Chrome to Foundries.io login page..."
    print_status "Please log in manually in the browser window that opens..."
    
    # Open Chrome with user profile to foundries.io login
    google-chrome --new-window "https://app.foundries.io/login" &
    CHROME_PID=$!
    
    print_status "⏳ Waiting for you to log in (60 seconds timeout)..."
    print_status "   1. Log in to Foundries.io in the browser"
    print_status "   2. Navigate to any page in app.foundries.io"
    print_status "   3. This script will detect the cookie automatically"
    
    # Wait and check for cookie every 5 seconds
    for i in {1..12}; do
        sleep 5
        
        # Try to extract cookie again
        if [ -f "$CHROME_COOKIES" ]; then
            cp "$CHROME_COOKIES" "$TEMP_DIR/Cookies_$i" 2>/dev/null || continue
            
            COOKIE_VALUE=$(sqlite3 "$TEMP_DIR/Cookies_$i" \
                "SELECT value FROM cookies WHERE host_key LIKE '%foundries.io%' AND name = 'osfogsid' ORDER BY creation_utc DESC LIMIT 1;" \
                2>/dev/null | head -1)
            
            if [ -n "$COOKIE_VALUE" ] && [ "$COOKIE_VALUE" != "" ]; then
                # Test if cookie is valid
                TEST_RESULT=$(curl -s -H "Cookie: osfogsid=$COOKIE_VALUE" \
                    "https://api.foundries.io/projects/dynamic-devices/lmp/builds/" | head -1)
                
                if [[ "$TEST_RESULT" != *"Authorization Required"* ]] && [[ "$TEST_RESULT" == *"{"* ]]; then
                    print_status "✅ Fresh cookie detected and validated!"
                    echo "FOUNDRIES_COOKIE=\"osfogsid=$COOKIE_VALUE\"" > "$COOKIE_FILE"
                    print_status "💾 Saved to $COOKIE_FILE"
                    
                    # Close Chrome
                    kill $CHROME_PID 2>/dev/null || true
                    exit 0
                fi
            fi
        fi
        
        echo -n "."
    done
    
    # Close Chrome
    kill $CHROME_PID 2>/dev/null || true
    echo
fi

# Method 3: Manual extraction with helper
print_status "Method 3: Manual extraction with browser helper..."

print_header "📋 Manual Cookie Extraction Required"
print_status "1. Open: https://app.foundries.io/factories/dynamic-devices/"
print_status "2. Press F12 → Network tab → Refresh page"
print_status "3. Click any request to app.foundries.io"
print_status "4. Find Cookie header, copy the osfogsid value"
print_status "5. Paste it below:"

read -p "Enter osfogsid cookie value: " MANUAL_COOKIE

if [ -n "$MANUAL_COOKIE" ]; then
    # Clean up the cookie value (remove quotes, spaces, etc.)
    CLEAN_COOKIE=$(echo "$MANUAL_COOKIE" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/^"//;s/"$//')
    
    # Test the cookie
    TEST_RESULT=$(curl -s -H "Cookie: osfogsid=$CLEAN_COOKIE" \
        "https://api.foundries.io/projects/dynamic-devices/lmp/builds/" | head -1)
    
    if [[ "$TEST_RESULT" != *"Authorization Required"* ]] && [[ "$TEST_RESULT" == *"{"* ]]; then
        print_status "✅ Manual cookie validated!"
        echo "FOUNDRIES_COOKIE=\"osfogsid=$CLEAN_COOKIE\"" > "$COOKIE_FILE"
        print_status "💾 Saved to $COOKIE_FILE"
        exit 0
    else
        print_error "❌ Cookie validation failed"
        exit 1
    fi
else
    print_error "❌ No cookie provided"
    exit 1
fi

