#!/bin/bash

# Create software/firmware labels and assign software/firmware issues to ajlennon
# Requires: gh CLI authenticated

set -e

REPO="DynamicDevices/meta-dynamicdevices"
ASSIGNEE="ajlennon"

echo "Creating software/firmware labels and assigning issues to $ASSIGNEE..."

# Create software and firmware labels
echo "Creating software and firmware labels..."

gh api repos/DynamicDevices/meta-dynamicdevices/labels -f name="software" -f color="0052cc" -f description="Software-related issues including recipes, build system, and application code" || echo "Label may already exist"

gh api repos/DynamicDevices/meta-dynamicdevices/labels -f name="firmware" -f color="5319e7" -f description="Firmware-related issues including bootloaders, kernel modules, and embedded software" || echo "Label may already exist"

echo "Software and firmware labels created successfully!"
echo ""
echo "Analyzing and labeling software/firmware issues..."

# SOFTWARE ISSUES - Build system, recipes, applications, configuration

# Issue #9: QA Check Failures (Build system/recipes - SOFTWARE)
echo "Labeling issue #9 as SOFTWARE - QA check failures in build system"
gh issue edit 9 --repo "$REPO" --add-label "software" --add-assignee "$ASSIGNEE"

# Issue #8: Recipe License Information (Recipe/legal - SOFTWARE) 
echo "Labeling issue #8 as SOFTWARE - Recipe license configuration"
gh issue edit 8 --repo "$REPO" --add-label "software" --add-assignee "$ASSIGNEE"

# Issue #7: TODO Comments Resolution (Code quality across software - SOFTWARE)
echo "Labeling issue #7 as SOFTWARE - TODO comments in software code"
gh issue edit 7 --repo "$REPO" --add-label "software" --add-assignee "$ASSIGNEE"

# Issue #5: Remove salt value (Configuration/security - SOFTWARE)
echo "Labeling issue #5 as SOFTWARE - Configuration security"
gh issue edit 5 --repo "$REPO" --add-label "software" --add-assignee "$ASSIGNEE"

# FIRMWARE ISSUES - Device trees, kernel, low-level drivers

# Issue #11: Device Tree Pinctrl Organization (Device tree - FIRMWARE)
echo "Labeling issue #11 as FIRMWARE - Device tree configuration"
gh issue edit 11 --repo "$REPO" --add-label "firmware" 
# Note: Keeping Mike-Hull assignment since it's hardware-related firmware

# Issue #10: STUSB4500 Device Tree Implementation (Device tree/driver - FIRMWARE)
echo "Labeling issue #10 as FIRMWARE - Device tree and driver implementation"
gh issue edit 10 --repo "$REPO" --add-label "firmware"
# Note: Keeping Mike-Hull assignment since it's hardware-related firmware

# MIXED ISSUES - May need both software and firmware work

# Issue #12: Hardware Documentation Verification (Mixed - but primarily documentation)
echo "Issue #12 is primarily documentation - keeping current assignment"
# This stays with Mike-Hull as it's hardware documentation

# Issue #6: Phasora DTS GPIO settings (Device tree - FIRMWARE)
echo "Labeling issue #6 as FIRMWARE - Device tree GPIO configuration"
gh issue edit 6 --repo "$REPO" --add-label "firmware"
# Note: Keeping Mike-Hull assignment since it's hardware-related firmware

# Issue #1: STT22H sensor values (Could be firmware or hardware - keeping with hardware expert)
echo "Issue #1 - STT22H sensor stays with hardware assignment (could be sensor calibration)"
# This stays with Mike-Hull as it may be hardware calibration

echo ""
echo "✅ Software and firmware issues labeled and assigned successfully!"
echo ""
echo "ASSIGNMENT SUMMARY:"
echo ""
echo "👨‍💻 AJLENNON (Software Issues):"
echo "  #9: QA Check Failures - Build system quality"
echo "  #8: Recipe License Information - Recipe configuration (CRITICAL)"
echo "  #7: TODO Comments Resolution - Code quality"
echo "  #5: Remove salt value - Security configuration"
echo ""
echo "👨‍🔧 MIKE-HULL (Hardware + Hardware-related Firmware):"
echo "  #12: Hardware Documentation Verification - Documentation"
echo "  #11: Device Tree Pinctrl Organization - Hardware firmware"  
echo "  #10: STUSB4500 Device Tree Implementation - Hardware firmware"
echo "  #6: Phasora DTS GPIO settings - Hardware firmware"
echo "  #1: STT22H sensor values - Hardware calibration"
echo ""
echo "LABEL BREAKDOWN:"
echo "🔵 Software: #9, #8, #7, #5"
echo "🟣 Firmware: #11, #10, #6"
echo "🟠 Hardware: #12, #11, #10, #6, #1"
echo ""
echo "Note: Some issues have both hardware and firmware labels as they involve"
echo "firmware that directly interfaces with hardware components."
