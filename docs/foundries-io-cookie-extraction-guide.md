# Foundries.io Cookie Extraction Guide

## Overview
This guide explains how to extract browser cookies for accessing Foundries.io build logs via API when `fioctl` fails or doesn't provide real-time access.

## Why This Is Needed
- **fioctl limitations**: Sometimes fails with authentication or doesn't provide real-time log access
- **API access**: Direct API calls to Foundries.io require authentication via browser session cookies
- **Real-time monitoring**: Essential for debugging build failures and monitoring progress
- **Build log access**: Enables automated monitoring and analysis of build logs

## Cookie Extraction Methods

### Method 1: Chrome Developer Tools (Recommended)

1. **Open Foundries.io in Chrome**
   - Navigate to: `https://app.foundries.io/factories/dynamic-devices/`
   - Ensure you're logged in and can access build logs

2. **Open Developer Tools**
   - Press `F12` or right-click → "Inspect"
   - Go to the **Network** tab

3. **Make a Request**
   - Navigate to a build page (e.g., `https://app.foundries.io/factories/dynamic-devices/targets/2021/`)
   - Or refresh the current page

4. **Find the Request**
   - Look for requests to `app.foundries.io` in the Network tab
   - Click on any request to the main domain

5. **Extract Cookie**
   - In the **Headers** section, find **Request Headers**
   - Look for the `Cookie:` header
   - Copy the entire cookie string

### Method 2: Chrome Application Tab

1. **Open Developer Tools**
   - Press `F12` → go to **Application** tab

2. **Navigate to Cookies**
   - In left sidebar: **Storage** → **Cookies** → `https://app.foundries.io`

3. **Find Session Cookie**
   - Look for cookie named `osfogsid` (main session cookie)
   - Copy the **Value** field

4. **Format for Use**
   - Format as: `osfogsid=<copied_value>`

### Method 3: Firefox Developer Tools

1. **Open Developer Tools**
   - Press `F12` → go to **Network** tab

2. **Make Request and Extract**
   - Navigate to build page or refresh
   - Click on any request to `app.foundries.io`
   - Go to **Headers** → **Request Headers**
   - Copy the `Cookie:` header value

## Using the Extracted Cookie

### API Access Format
```bash
# Build status API
curl -s -H "Cookie: osfogsid=<session_value>" \
  "https://api.foundries.io/projects/dynamic-devices/lmp/builds/<TARGET>/"

# Build log access
curl -s -H "Cookie: osfogsid=<session_value>" \
  "https://api.foundries.io/projects/dynamic-devices/lmp/builds/<TARGET>/runs/<MACHINE>/console.log"
```

### Example Usage
```bash
# Check build 2021 status
curl -s -H "Cookie: osfogsid=s%3A79b94baf51624cc71904304053522d229d9c2b9fadd4f8a26c3b6de8ef4345ab.TdPrR8kD7l%2FxcsDACXcJDCjRDIvcshipRDokkNVpjmk" \
  "https://api.foundries.io/projects/dynamic-devices/lmp/builds/2021/" | jq '.data.build.status'

# Get last 50 lines of build log
curl -s -H "Cookie: osfogsid=s%3A79b94baf51624cc71904304053522d229d9c2b9fadd4f8a26c3b6de8ef4345ab.TdPrR8kD7l%2FxcsDACXcJDCjRDIvcshipRDokkNVpjmk" \
  "https://api.foundries.io/projects/dynamic-devices/lmp/builds/2021/runs/imx93-jaguar-eink/console.log" | tail -50
```

## Cookie Management

### Cookie Expiration
- **Session cookies**: Expire when browser session ends
- **Persistent cookies**: Have expiration dates (check in developer tools)
- **Signs of expiration**: API returns 401/403 errors or login pages

### Updating Cookies
1. **When to update**:
   - API calls return authentication errors
   - Getting HTML login pages instead of JSON/log data
   - After logging out and back in to Foundries.io

2. **How to update**:
   - Follow extraction steps above
   - Replace old cookie value in scripts/commands
   - Test with a simple API call

### Security Notes
- **Keep cookies private**: Don't commit to git or share publicly
- **Limited scope**: Cookies only work for the logged-in user account
- **Time-limited**: Sessions expire, requiring periodic updates
- **Domain-specific**: Only work for `*.foundries.io` domains

## Automation Scripts

### Cookie Update Helper
```bash
#!/bin/bash
# save as: update-foundries-cookie.sh

echo "🔐 Foundries.io Cookie Update Helper"
echo "1. Open Chrome Developer Tools (F12)"
echo "2. Go to Network tab"
echo "3. Navigate to https://app.foundries.io/factories/dynamic-devices/"
echo "4. Find any request to app.foundries.io"
echo "5. Copy the Cookie header value"
echo ""
echo "Enter the new cookie value:"
read -r NEW_COOKIE

# Test the cookie
echo "🧪 Testing cookie..."
RESPONSE=$(curl -s -H "Cookie: $NEW_COOKIE" \
  "https://api.foundries.io/projects/dynamic-devices/lmp/builds/" | head -1)

if [[ "$RESPONSE" == *"{"* ]]; then
    echo "✅ Cookie is valid!"
    echo "💾 Save this cookie value for future use:"
    echo "$NEW_COOKIE"
else
    echo "❌ Cookie test failed. Please try again."
fi
```

### Build Monitor Script
```bash
#!/bin/bash
# save as: monitor-build.sh
# Usage: ./monitor-build.sh 2021

TARGET=$1
COOKIE="osfogsid=<YOUR_COOKIE_HERE>"

if [ -z "$TARGET" ]; then
    echo "Usage: $0 <target_number>"
    exit 1
fi

echo "🔍 Monitoring build $TARGET..."

while true; do
    STATUS=$(curl -s -H "Cookie: $COOKIE" \
      "https://api.foundries.io/projects/dynamic-devices/lmp/builds/$TARGET/" | \
      jq -r '.data.build.status' 2>/dev/null)
    
    echo "$(date): Build $TARGET status: $STATUS"
    
    if [[ "$STATUS" == "PASSED" || "$STATUS" == "FAILED" ]]; then
        echo "🏁 Build completed with status: $STATUS"
        break
    fi
    
    sleep 30
done
```

## Troubleshooting

### Common Issues
1. **403/401 Errors**: Cookie expired or invalid
   - **Solution**: Extract fresh cookie from browser

2. **HTML Instead of JSON**: Not authenticated properly
   - **Solution**: Verify cookie format and completeness

3. **Empty Responses**: Wrong API endpoint or target number
   - **Solution**: Check URL format and target exists

4. **URL Encoding Issues**: Special characters in cookie
   - **Solution**: Ensure proper URL encoding of cookie values

### Testing Cookie Validity
```bash
# Quick test
curl -s -H "Cookie: <YOUR_COOKIE>" \
  "https://api.foundries.io/projects/dynamic-devices/lmp/builds/" | head -1

# Should return JSON starting with "{"
# If returns HTML, cookie is invalid
```

## API Endpoints Reference

### Build Status
- **URL**: `https://api.foundries.io/projects/dynamic-devices/lmp/builds/<TARGET>/`
- **Returns**: JSON with build status, runs, timestamps

### Build Logs
- **URL**: `https://api.foundries.io/projects/dynamic-devices/lmp/builds/<TARGET>/runs/<MACHINE>/console.log`
- **Returns**: Plain text build log (may redirect to Google Storage)

### Build List
- **URL**: `https://api.foundries.io/projects/dynamic-devices/lmp/builds/`
- **Returns**: JSON list of recent builds

## Integration with Development Workflow

### During Build Debugging
1. **Extract cookie** when starting debugging session
2. **Monitor builds** in real-time using API calls
3. **Analyze failures** by accessing logs immediately
4. **Update cookie** when session expires

### Best Practices
- **Keep cookie current**: Update weekly or when authentication fails
- **Test before critical use**: Verify cookie works before important debugging
- **Document cookie location**: Store securely for team access if needed
- **Automate monitoring**: Use scripts for continuous build monitoring

---

**Last Updated**: September 2025  
**Next Review**: When authentication methods change or API updates occur
