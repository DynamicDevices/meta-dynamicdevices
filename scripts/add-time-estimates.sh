#!/bin/bash

# Add time estimate labels to GitHub issues
# Requires: gh CLI authenticated

set -e

REPO="DynamicDevices/meta-dynamicdevices"

echo "Creating time estimate labels and adding estimates to issues..."

# Create time estimate labels
echo "Creating time estimate labels..."

gh api repos/DynamicDevices/meta-dynamicdevices/labels -f name="estimate: 1-2 hours" -f color="c2e0c6" -f description="Small task, 1-2 hours of work" || echo "Label may already exist"

gh api repos/DynamicDevices/meta-dynamicdevices/labels -f name="estimate: 4-8 hours" -f color="bfd4f2" -f description="Medium task, half to full day of work" || echo "Label may already exist"

gh api repos/DynamicDevices/meta-dynamicdevices/labels -f name="estimate: 1-2 days" -f color="d4c5f9" -f description="Large task, 1-2 days of work" || echo "Label may already exist"

gh api repos/DynamicDevices/meta-dynamicdevices/labels -f name="estimate: 3-5 days" -f color="f9c5d4" -f description="Complex task, 3-5 days of work" || echo "Label may already exist"

gh api repos/DynamicDevices/meta-dynamicdevices/labels -f name="estimate: 1+ weeks" -f color="fad5a5" -f description="Major project, 1+ weeks of work" || echo "Label may already exist"

echo "Time estimate labels created successfully!"
echo ""
echo "Adding time estimates to issues..."

# CRITICAL PRIORITY

# Issue #8: Recipe License Information (SOFTWARE - ajlennon)
echo "Adding estimate to issue #8 - Recipe License Information"
gh issue edit 8 --repo "$REPO" --add-label "estimate: 4-8 hours"
echo "  📋 Rationale: Need to research actual licenses, update 4+ recipe files, verify checksums"

# HIGH PRIORITY

# Issue #10: STUSB4500 Device Tree Implementation (FIRMWARE - Mike-Hull)  
echo "Adding estimate to issue #10 - STUSB4500 Device Tree Implementation"
gh issue edit 10 --repo "$REPO" --add-label "estimate: 1-2 days"
echo "  📋 Rationale: Device tree entry, pin config, driver integration, testing on hardware"

# Issue #1: STT22H sensor values (HARDWARE - Mike-Hull)
echo "Adding estimate to issue #1 - STT22H sensor values"
gh issue edit 1 --repo "$REPO" --add-label "estimate: 4-8 hours"
echo "  📋 Rationale: Investigate sensor readings, potentially adjust calibration values"

# Issue #6: Phasora DTS GPIO settings (FIRMWARE - Mike-Hull)
echo "Adding estimate to issue #6 - Phasora DTS GPIO settings"
gh issue edit 6 --repo "$REPO" --add-label "estimate: 1-2 hours"
echo "  📋 Rationale: Simple GPIO configuration change in device tree"

# MEDIUM PRIORITY

# Issue #11: Device Tree Pinctrl Organization (FIRMWARE - Mike-Hull)
echo "Adding estimate to issue #11 - Device Tree Pinctrl Organization"
gh issue edit 11 --repo "$REPO" --add-label "estimate: 1-2 days"
echo "  📋 Rationale: Reorganize multiple device tree files, test pin configurations"

# Issue #9: QA Check Failures (SOFTWARE - ajlennon)
echo "Adding estimate to issue #9 - QA Check Failures"
gh issue edit 9 --repo "$REPO" --add-label "estimate: 1-2 days"
echo "  📋 Rationale: Investigate multiple QA failures, fix packaging issues, test builds"

# Issue #12: Hardware Documentation Verification (HARDWARE - Mike-Hull)
echo "Adding estimate to issue #12 - Hardware Documentation Verification"
gh issue edit 12 --repo "$REPO" --add-label "estimate: 3-5 days"
echo "  📋 Rationale: Systematic comparison of wiki vs implementation across multiple boards"

# Issue #7: TODO Comments Resolution (SOFTWARE - ajlennon)
echo "Adding estimate to issue #7 - TODO Comments Resolution"
gh issue edit 7 --repo "$REPO" --add-label "estimate: 3-5 days"
echo "  📋 Rationale: 29 TODO items to review, some may need separate issues, code fixes"

# LOW PRIORITY

# Issue #5: Remove salt value (SOFTWARE - ajlennon)
echo "Adding estimate to issue #5 - Remove salt value"
gh issue edit 5 --repo "$REPO" --add-label "estimate: 1-2 hours"
echo "  📋 Rationale: Simple configuration cleanup, remove salt file reference"

echo ""
echo "✅ Time estimates added to all issues successfully!"
echo ""
echo "TIME ESTIMATE SUMMARY:"
echo ""
echo "🔴 CRITICAL (1 issue = 4-8 hours):"
echo "  #8: Recipe License Information [4-8 hours] - ajlennon"
echo ""
echo "🟠 HIGH (3 issues = ~3.5 days):"
echo "  #10: STUSB4500 Device Tree [1-2 days] - Mike-Hull"
echo "  #1: STT22H sensor values [4-8 hours] - Mike-Hull"
echo "  #6: Phasora DTS GPIO [1-2 hours] - Mike-Hull"
echo ""
echo "🟡 MEDIUM (4 issues = ~9-14 days):"
echo "  #11: Device Tree Pinctrl [1-2 days] - Mike-Hull"
echo "  #9: QA Check Failures [1-2 days] - ajlennon"
echo "  #12: Hardware Documentation [3-5 days] - Mike-Hull"
echo "  #7: TODO Comments Resolution [3-5 days] - ajlennon"
echo ""
echo "🟢 LOW (1 issue = 1-2 hours):"
echo "  #5: Remove salt value [1-2 hours] - ajlennon"
echo ""
echo "TOTAL ESTIMATED EFFORT:"
echo "👨‍💻 ajlennon (Software): ~2-3 weeks"
echo "👨‍🔧 Mike-Hull (Hardware/Firmware): ~2-3 weeks"
echo "🏢 Overall Project: ~3-4 weeks (with parallel work)"
echo ""
echo "Note: Estimates include investigation, implementation, testing, and documentation time."
