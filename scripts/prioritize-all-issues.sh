#!/bin/bash

# Create priority labels and prioritize all outstanding GitHub issues
# Requires: gh CLI authenticated

set -e

REPO="DynamicDevices/meta-dynamicdevices"

echo "Creating priority labels and prioritizing all issues..."

# Create priority labels
echo "Creating priority labels..."

gh api repos/DynamicDevices/meta-dynamicdevices/labels -f name="priority: critical" -f color="d73a4a" -f description="Critical issues that block functionality or have security implications" || echo "Label may already exist"

gh api repos/DynamicDevices/meta-dynamicdevices/labels -f name="priority: high" -f color="ff9500" -f description="High priority issues that should be addressed soon" || echo "Label may already exist"

gh api repos/DynamicDevices/meta-dynamicdevices/labels -f name="priority: medium" -f color="fbca04" -f description="Medium priority issues for planned work" || echo "Label may already exist"

gh api repos/DynamicDevices/meta-dynamicdevices/labels -f name="priority: low" -f color="0e8a16" -f description="Low priority issues for future consideration" || echo "Label may already exist"

echo "Priority labels created successfully!"
echo ""
echo "Prioritizing issues..."

# CRITICAL PRIORITY - Security, legal compliance, blocking functionality

# Issue #8: Recipe License Information (Legal compliance - CRITICAL)
echo "Setting CRITICAL priority for issue #8 - License compliance"
gh issue edit 8 --repo "$REPO" --add-label "priority: critical"

# HIGH PRIORITY - Missing hardware features, configuration issues

# Issue #10: STUSB4500 Power Controller (Missing hardware feature - HIGH)
echo "Setting HIGH priority for issue #10 - STUSB4500 implementation"
gh issue edit 10 --repo "$REPO" --add-label "priority: high"

# Issue #1: STT22H sensor values (Hardware functionality - HIGH)
echo "Setting HIGH priority for issue #1 - STT22H sensor"
gh issue edit 1 --repo "$REPO" --add-label "priority: high"

# Issue #6: Phasora DTS GPIO settings (Hardware configuration - HIGH)
echo "Setting HIGH priority for issue #6 - Phasora GPIO"
gh issue edit 6 --repo "$REPO" --add-label "priority: high"

# MEDIUM PRIORITY - Code quality, organization, technical debt

# Issue #11: Device Tree Pinctrl Organization (Code organization - MEDIUM)
echo "Setting MEDIUM priority for issue #11 - Device tree organization"
gh issue edit 11 --repo "$REPO" --add-label "priority: medium"

# Issue #9: QA Check Failures (Build quality - MEDIUM)
echo "Setting MEDIUM priority for issue #9 - QA check failures"
gh issue edit 9 --repo "$REPO" --add-label "priority: medium"

# Issue #12: Hardware Documentation Verification (Documentation accuracy - MEDIUM)
echo "Setting MEDIUM priority for issue #12 - Documentation verification"
gh issue edit 12 --repo "$REPO" --add-label "priority: medium"

# Issue #7: TODO Comments Resolution (Technical debt - MEDIUM)
echo "Setting MEDIUM priority for issue #7 - TODO comments"
gh issue edit 7 --repo "$REPO" --add-label "priority: medium"

# LOW PRIORITY - Clean up tasks

# Issue #5: Remove salt value (Security cleanup - but appears to be older issue - LOW)
echo "Setting LOW priority for issue #5 - Remove salt value"
gh issue edit 5 --repo "$REPO" --add-label "priority: low"

echo ""
echo "✅ All issues prioritized successfully!"
echo ""
echo "PRIORITY SUMMARY:"
echo ""
echo "🔴 CRITICAL (1 issue):"
echo "  #8: Recipe License Information - Legal compliance required"
echo ""
echo "🟠 HIGH (3 issues):"
echo "  #10: STUSB4500 Power Controller - Missing hardware feature"
echo "  #1: STT22H sensor values - Hardware functionality"
echo "  #6: Phasora DTS GPIO settings - Hardware configuration"
echo ""
echo "🟡 MEDIUM (4 issues):"
echo "  #11: Device Tree Pinctrl Organization - Code organization"
echo "  #9: QA Check Failures - Build quality"
echo "  #12: Hardware Documentation Verification - Documentation accuracy"
echo "  #7: TODO Comments Resolution - Technical debt"
echo ""
echo "🟢 LOW (1 issue):"
echo "  #5: Remove salt value - Security cleanup"
echo ""
echo "Hardware issues assigned to Mike-Hull: #12, #11, #10, #6, #1"
echo "Other issues can be assigned as needed based on expertise"
