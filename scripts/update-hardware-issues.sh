#!/bin/bash

# Update hardware-related GitHub issues with hardware label and assign to Mike-Hull
# Requires: gh CLI authenticated

set -e

REPO="DynamicDevices/meta-dynamicdevices"
ASSIGNEE="Mike-Hull"

echo "Updating hardware-related GitHub issues..."

# Hardware-related issues to update:

# Issue #12: Systematic Hardware Documentation vs Implementation Verification
echo "Updating issue #12 - Hardware Documentation Verification"
gh issue edit 12 --repo "$REPO" --add-label "hardware" --add-assignee "$ASSIGNEE"

# Issue #11: Device Tree Pinctrl Configuration Organization Cleanup  
echo "Updating issue #11 - Device Tree Pinctrl Organization"
gh issue edit 11 --repo "$REPO" --add-label "hardware" --add-assignee "$ASSIGNEE"

# Issue #10: STUSB4500 Power Controller Device Tree Implementation
echo "Updating issue #10 - STUSB4500 Device Tree Implementation"
gh issue edit 10 --repo "$REPO" --add-label "hardware" --add-assignee "$ASSIGNEE"

# Issue #6: Look at setting default GPIO in Phasora DTS (existing issue)
echo "Updating issue #6 - Phasora DTS GPIO settings"
gh issue edit 6 --repo "$REPO" --add-label "hardware" --add-assignee "$ASSIGNEE"

# Issue #1: Check values for STT22H sensor (existing issue)
echo "Updating issue #1 - STT22H sensor values"
gh issue edit 1 --repo "$REPO" --add-label "hardware" --add-assignee "$ASSIGNEE"

echo "✅ Hardware-related issues updated successfully!"
echo ""
echo "Updated issues with hardware label and assigned to $ASSIGNEE:"
echo "- Issue #12: Hardware Documentation Verification"
echo "- Issue #11: Device Tree Pinctrl Organization"
echo "- Issue #10: STUSB4500 Device Tree Implementation"
echo "- Issue #6: Phasora DTS GPIO settings"
echo "- Issue #1: STT22H sensor values"
echo ""
echo "Non-hardware issues (no changes):"
echo "- Issue #9: QA Check Failures (build system)"
echo "- Issue #8: Recipe License Information (legal/compliance)"
echo "- Issue #7: TODO Comments Resolution (code quality)"
echo "- Issue #5: Remove salt value (security/config)"
