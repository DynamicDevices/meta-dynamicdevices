#!/bin/bash

# Create GitHub issues from documentation maintenance review
# Requires: gh CLI authenticated

set -e

REPO="DynamicDevices/meta-dynamicdevices"

echo "Creating GitHub issues from documentation review..."

# Issue 1: STUSB4500 Device Tree Implementation
gh issue create \
  --repo "$REPO" \
  --title "STUSB4500 Power Controller Device Tree Implementation" \
  --label "enhancement,hardware,device-tree" \
  --body "## Description
The STUSB4500 USB-C power delivery controller is documented in wiki but missing from device tree implementation.

## Current State
- Wiki documents pins: SAI2_RXFS_GPIO4_IO21 (USB_ALERT#), SAI1_TXC_GPIO4_IO11 (USB_RESET)
- Device tree (imx8mm-jaguar-sentai.dts) has no STUSB4500 configuration
- Hardware support exists but software integration incomplete

## Expected Outcome
- Device tree entry for STUSB4500 on I2C1
- Pin configurations matching hardware design
- Driver integration for USB-C PD functionality

## Files to Update
- \`recipes-bsp/device-tree/lmp-device-tree/imx8mm-jaguar-sentai.dts\`
- Potentially kernel config for STUSB4500 driver

## Priority
High - Hardware feature not accessible without proper device tree configuration"

# Issue 2: Recipe Headers Standardization
gh issue create \
  --repo "$REPO" \
  --title "Recipe Headers Standardization" \
  --label "code-quality,recipes,documentation" \
  --body "## Description
Many recipes lack professional headers with proper licensing information.

## Current Issues
- Missing SUMMARY and DESCRIPTION fields
- Inconsistent LICENSE field usage (component vs layer licensing)
- Missing or incorrect LIC_FILES_CHKSUM values
- No MAINTAINER information

## Acceptance Criteria
- [ ] All .bb and .bbappend files have standardized headers
- [ ] LICENSE fields correctly specify component licenses (not layer license)
- [ ] SUMMARY and DESCRIPTION fields added where missing
- [ ] LIC_FILES_CHKSUM verified for accuracy
- [ ] MAINTAINER field added consistently

## Reference
Use \`docs/RECIPE_TEMPLATE.bb\` as reference for standardization.

## Files Affected
- All recipe files in recipes-* directories
- Focus on files missing headers or with incomplete information"

# Issue 3: Hardware Documentation Verification
gh issue create \
  --repo "$REPO" \
  --title "Complete Hardware Documentation vs Implementation Verification" \
  --label "documentation,hardware,verification" \
  --body "## Description
Systematic verification of all hardware pin mappings between wiki documentation and device tree implementation.

## Completed
- ✅ Edge AI Board pin mapping corrections (LED Enable, Codec Interrupt)
- ✅ Removed internal codenames from user documentation

## Remaining Work
- [ ] Verify all sensor configurations match device tree
- [ ] Check power management pin assignments
- [ ] Validate wireless module pin mappings
- [ ] Cross-check Edge EInk Board documentation

## Process
1. Compare wiki pin tables with actual device tree sources
2. Verify GPIO numbers and pin functions
3. Update documentation for any discrepancies
4. Test hardware functionality matches documentation

## Priority
Medium - Ensures accuracy for developers and users"

echo "✅ GitHub issues created successfully!"
echo "Visit: https://github.com/$REPO/issues"
