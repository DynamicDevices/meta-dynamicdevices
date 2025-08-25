#!/bin/bash

# Create GitHub issues for identified problems in meta-dynamicdevices
# Requires: gh CLI authenticated

set -e

REPO="DynamicDevices/meta-dynamicdevices"

echo "Creating GitHub issues for identified codebase problems..."

# Issue 1: TODO Comments Need Resolution
gh issue create \
  --repo "$REPO" \
  --title "Resolve Outstanding TODO Comments in Codebase" \
  --label "code-quality,maintenance,cleanup" \
  --body "## Description
Multiple TODO comments throughout the codebase need attention and resolution.

## Identified TODOs requiring action:

### High Priority
- **SPI Library C++ Warnings**: \`recipes-bsp/spi-lib/spi-lib_git.bb\` has C++11 narrowing conversion warnings being suppressed instead of fixed
- **Device Tree Organization**: Multiple device trees have \"TODO: Break these out better?\" for pinctrl organization
- **OPTEE Signing Keys**: Multiple build scripts reference missing signing key configuration
- **SE05X Configuration**: Machine configs have TODO about SE05X_OEFID not taking effect

### Medium Priority  
- **Web Browser Provisioning**: WiFi onboarding documentation mentions unimplemented web browser support
- **Audio Production**: Pipeline needs TODO for disabling production WiFi connection
- **Radar SDK QA Issues**: Recipe skips QA checks instead of addressing root cause
- **Meson Build Issues**: Contains patches with \"FIXME: Add all features\" comments

## Acceptance Criteria
- [ ] Review each TODO comment for continued relevance
- [ ] Create specific issues for complex TODOs requiring substantial work
- [ ] Fix or remove simple TODOs that can be addressed directly
- [ ] Update documentation where TODOs reference outdated information

## Priority
Medium - Code quality and technical debt reduction"

# Issue 2: Recipe License Information Cleanup
gh issue create \
  --repo "$REPO" \
  --title "Fix Recipe License Information - CLOSED Licenses Need Resolution" \
  --label "legal,code-quality,recipes" \
  --body "## Description
Several recipes have incorrect or incomplete license information that needs to be resolved.

## Problematic Recipes

### LICENSE = \"CLOSED\" Issues
- \`recipes-bsp/upd72020x-load/upd72020x-load_git.bb\` - Set to CLOSED with empty LIC_FILES_CHKSUM
- \`recipes-connectivity/uwb-mqtt-publisher/uwb-mqtt-publisher_1.0.bb\` - CLOSED license with empty checksum  
- \`recipes-config/phasora-config/phasora-config_1.0.bb\` - CLOSED license

### Warning Comments About License Guesses
- \`recipes-devtools/python/python3-*.bb\` files contain \"WARNING: the following LICENSE and LIC_FILES_CHKSUM values are best guesses\"
- \`recipes-bsp/radar-sdk/radar-sdk_git.bb\` has similar warning

## Resolution Required
1. **Determine actual licenses** for each component by examining source code headers
2. **Replace CLOSED licenses** with appropriate open source or commercial licenses
3. **Add proper LIC_FILES_CHKSUM** values pointing to actual license files
4. **Remove warning comments** once licenses are verified

## Legal Compliance
Using CLOSED licenses should only be for truly proprietary components. Most components likely have identifiable open source licenses.

## Priority
High - Legal compliance and proper attribution required"

# Issue 3: QA Check Failures and INSANE_SKIP Usage
gh issue create \
  --repo "$REPO" \
  --title "Address QA Check Failures Instead of Using INSANE_SKIP" \
  --label "code-quality,build-system,qa" \
  --body "## Description
Multiple recipes use INSANE_SKIP to bypass QA checks instead of addressing the underlying issues.

## Problematic Uses

### Development Dependencies
- \`recipes-bsp/spi-lib/spi-lib_git.bb\`: \`INSANE_SKIP = \"dev-deps dev-elf\"\`
- \`recipes-multimedia/nxp-afe/nxp-afe_git.bb\`: \`INSANE_SKIP += \"dev-so\"\`
- \`recipes-multimedia/nxp-afe/nxp-afe-voiceseeker_git.bb\`: \`INSANE_SKIP += \"dev-so\"\`

### Architecture Issues  
- \`recipes-support/waydroid/waydroid-data.bb\`: \`INSANE_SKIP += \"arch file-rdeps\"\`
- \`recipes-multimedia/gstreamer/gstreamer1.0-plugins-good_1.24.0.imx.bb\`: \`INSANE_SKIP += \"32bit-time\"\`

### Commented Out Issues
- \`recipes-kernel/firmware-imx/firmware-imx_%.bbappend\`: Has commented INSANE_SKIP for ldflags

## Recommended Actions
1. **Investigate root causes** of each QA failure
2. **Fix packaging issues** instead of skipping checks where possible
3. **Document justification** for any remaining INSANE_SKIP usage
4. **Review commented skips** to determine if they're still needed

## Benefits
- Improved package quality and compliance
- Better error detection during builds
- Cleaner, more maintainable recipes

## Priority
Medium - Code quality improvement"

# Issue 4: STUSB4500 Power Controller Missing Device Tree Implementation
gh issue create \
  --repo "$REPO" \
  --title "STUSB4500 Power Controller Device Tree Implementation Missing" \
  --label "hardware,device-tree,enhancement" \
  --body "## Description
The STUSB4500 USB-C power delivery controller is documented in Edge AI Board wiki but missing from device tree implementation.

## Current State
- **Wiki Documentation**: Pins documented as SAI2_RXFS_GPIO4_IO21 (USB_ALERT#), SAI1_TXC_GPIO4_IO11 (USB_RESET)
- **Device Tree**: \`imx8mm-jaguar-sentai.dts\` has no STUSB4500 configuration
- **Hardware**: Support exists but software integration incomplete

## Expected Implementation
- Device tree entry for STUSB4500 on I2C1 bus
- Pin configurations matching hardware design:
  - USB_ALERT# on GPIO4_IO21 (MX8MM_IOMUXC_SAI2_RXFS_GPIO4_IO21)  
  - USB_RESET on GPIO4_IO11 (MX8MM_IOMUXC_SAI1_TXC_GPIO4_IO11)
- Driver integration for USB-C PD functionality

## Files to Update
- \`recipes-bsp/device-tree/lmp-device-tree/imx8mm-jaguar-sentai.dts\`
- Potentially kernel config for STUSB4500 driver support
- May need I2C1 bus configuration updates

## Hardware Reference
See [Edge AI Board Wiki](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Edge-AI-Board#power-management-stusb4500-interface-i2c1) for complete pin mapping.

## Priority
High - Hardware feature not accessible without proper device tree configuration"

# Issue 5: Device Tree Pinctrl Organization Needs Improvement
gh issue create \
  --repo "$REPO" \
  --title "Device Tree Pinctrl Configuration Organization Cleanup" \
  --label "device-tree,code-quality,maintenance" \
  --body "## Description
Multiple device tree files have TODO comments about improving pinctrl organization, indicating current structure needs cleanup.

## Affected Files
- \`imx8mm-jaguar-sentai.dts\`: \"TODO: Break these out better?\" in pinctrl_hog
- \`imx8mm-jaguar-handheld.dts\`: Same organizational issue
- Other device trees may have similar issues

## Current Problems
- Overly large \`pinctrl_hog\` groups mixing unrelated pin functions
- Pin configurations not logically grouped by peripheral/function
- Harder to maintain and understand pin assignments

## Proposed Improvements
1. **Separate pinctrl groups** by functional area:
   - \`pinctrl_wifi_bt\`: Wireless connectivity pins
   - \`pinctrl_sensors\`: Sensor interface pins  
   - \`pinctrl_audio\`: Audio codec pins
   - \`pinctrl_power\`: Power management pins
   - \`pinctrl_leds\`: LED control pins

2. **Assign specific groups** to their respective device nodes instead of using hog

3. **Add descriptive comments** for each pin group's purpose

## Benefits
- Improved maintainability and readability
- Easier to debug pin configuration issues
- Better organization for future hardware variants
- Follows device tree best practices

## Priority
Medium - Code quality and maintainability improvement"

# Issue 6: Missing Hardware Documentation Implementation Verification
gh issue create \
  --repo "$REPO" \
  --title "Systematic Hardware Documentation vs Implementation Verification Needed" \
  --label "documentation,hardware,verification,sensors" \
  --body "## Description
Need systematic verification that all hardware documented in wiki is properly implemented in device trees and drivers.

## Specific Areas Needing Verification

### Edge AI Board (imx8mm-jaguar-sentai)
- **Sensors I2C3**: Verify LIS2DH12 accelerometer, STTS22H temperature sensor implementations
- **Button Input**: GPIO4_IO6 (SLMB_0) switch implementation  
- **LED Driver**: LP5024 on I2C3 device tree configuration
- **Power Management**: STUSB4500 implementation (separate issue created)

### All Boards
- **Pin mapping accuracy**: Compare wiki tables with actual device tree pin assignments
- **GPIO numbering**: Verify GPIO numbers match hardware design  
- **I2C/SPI addressing**: Check device addresses and bus assignments
- **Interrupt configurations**: Verify interrupt pins are properly configured

## Documented Hardware Features to Check
From Edge AI Board wiki:
- Radar interface (appears implemented)
- Audio TAS2563 codec (implemented)  
- Wireless modules (implemented)
- Sensor interfaces (needs verification)
- LED driver (needs verification)
- Power controller (missing - separate issue)

## Process
1. Compare wiki pin tables with device tree source files
2. Verify each documented GPIO number and function
3. Check for missing device configurations
4. Test hardware functionality matches documentation
5. Update documentation for any discrepancies found

## Expected Outcome
- All documented hardware features have corresponding device tree entries
- Pin mappings are consistent between documentation and implementation
- Any documentation errors are corrected

## Priority
Medium - Ensures accuracy for developers and users, prevents integration issues"

echo "✅ GitHub issues created successfully!"
echo "Visit: https://github.com/$REPO/issues to view created issues"
echo ""
echo "Summary of issues created:"
echo "1. TODO Comments Resolution"
echo "2. Recipe License Cleanup" 
echo "3. QA Check Failures"
echo "4. STUSB4500 Device Tree Implementation"
echo "5. Device Tree Pinctrl Organization"
echo "6. Hardware Documentation Verification"
