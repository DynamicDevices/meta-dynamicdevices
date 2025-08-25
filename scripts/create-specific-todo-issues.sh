#!/bin/bash

# Create GitHub issues for specific high-priority TODO items that need individual tracking
# Requires: gh CLI authenticated

set -e

REPO="DynamicDevices/meta-dynamicdevices"

echo "Creating GitHub issues for specific high-priority TODO items..."

# Issue 1: SE05X Configuration Not Taking Effect
gh issue create \
  --repo "$REPO" \
  --title "SE05X_OEFID Configuration Not Taking Effect in Machine Configs" \
  --label "bug" \
  --body "## Description
SE05X_OEFID configuration in machine configs is not taking effect, requiring workarounds.

## Affected Files
- \`conf/machine/imx8mm-jaguar-sentai.conf\` line 38-39
- \`conf/machine/imx8mm-jaguar-inst.conf\` line 35-36

## Current Workaround
Currently overriding the setting in the OpTee recipe instead of using the machine config.

## Expected Behavior
\`SE05X_OEFID:imx8mm-jaguar-sentai = \"0xA200\"\` should work from machine config without needing recipe-level override.

## Investigation Needed
1. Check if variable is being read at the right time in build process
2. Verify variable precedence and scope
3. Determine if this is a Yocto layer dependency issue
4. Fix the root cause and remove workarounds

## Files to Check
- OpTee recipe with current workaround
- Build order and variable resolution
- SE05X integration configuration

## Priority
Medium - Security feature configuration should work as designed"

# Issue 2: OpTee Signing Key Configuration Missing
gh issue create \
  --repo "$REPO" \
  --title "OpTee Signing Key Configuration Missing from Build Scripts" \
  --label "enhancement" \
  --body "## Description
Multiple build scripts reference missing OpTee signing key configuration that needs to be implemented.

## Affected Files
- \`scripts/kas-build-base.sh\` line 3-4
- \`scripts/kas-build-mfgtools.sh\` line 19-20  
- \`scripts/kas-shell-base.sh\` line 3-4

## Current State
All scripts have commented out references to:
\`\`\`
conf/machine/include/lmp-factory-custom.inc:OPTEE_TA_SIGN_KEY = \"\${TOPDIR}/conf/factory-keys/opteedev.key\"
\`\`\`

## Required Actions
1. **Determine if signing is needed** for current use case
2. **Create proper key management** if signing is required:
   - Generate or obtain signing keys
   - Secure key storage location
   - Update build configuration
3. **Remove TODO comments** once decision is made
4. **Document the signing process** in build documentation

## Security Considerations
- Keys should not be committed to repository
- Consider using environment variables or external key management
- Document key generation process for developers

## Priority
Medium - Security and build system completion"

# Issue 3: SPI Library C++ Warnings Need Fixing
gh issue create \
  --repo "$REPO" \
  --title "Fix C++11 Narrowing Conversion Warnings in SPI Library" \
  --label "bug" \
  --body "## Description
SPI library recipe suppresses C++11 narrowing conversion warnings instead of fixing the underlying code issues.

## Current Problem
In \`recipes-bsp/spi-lib/spi-lib_git.bb\` line 26-27:
\`\`\`
# TODO: Fix C++11 narrowing conversion warnings in source code
TARGET_CFLAGS += \"-Wno-c++11-narrowing\"
\`\`\`

## Root Cause
The upstream SPI library source code has narrowing conversion issues that should be fixed rather than suppressed.

## Recommended Solution
1. **Review the warnings** when removing the suppression flag
2. **Fix the narrowing conversions** in the source code:
   - Use explicit casts where appropriate
   - Ensure integer types are properly sized
   - Update variable declarations to match usage
3. **Submit patches upstream** to the SPI library repository
4. **Remove the warning suppression** once fixed

## Benefits
- Cleaner code without warnings
- Better type safety
- Follows C++ best practices
- Removes technical debt

## Files to Update
- \`recipes-bsp/spi-lib/spi-lib_git.bb\`
- Upstream SPI library source code

## Priority
Low-Medium - Code quality improvement"

# Issue 4: U-Boot Device Tree Customization Missing
gh issue create \
  --repo "$REPO" \
  --title "Add U-Boot Device Tree Customization for i.MX8ULP EVK" \
  --label "enhancement" \
  --body "## Description
U-Boot recipe has commented out device tree customization that may be needed for i.MX8ULP EVK support.

## Current State
In \`recipes-bsp/u-boot/u-boot-fio_%.bbappend\` line 36-39:
\`\`\`
# TODO: Add u-boot DTB customisation patch
#SRC_URI:append:imx8ulp-lpddr4-evk = \" \\
#    file://custom-dtb.cfg \\
#\"
\`\`\`

## Investigation Needed
1. **Determine if customization is required** for i.MX8ULP EVK
2. **Check if current u-boot works** without custom device tree
3. **Identify what customizations might be needed**:
   - Pin configurations
   - Memory settings
   - Peripheral configurations
   - Boot sequence modifications

## Possible Actions
1. **Test current u-boot** on i.MX8ULP EVK hardware
2. **Create custom-dtb.cfg** if needed
3. **Enable the configuration** if required
4. **Remove TODO** if not needed

## Files Involved
- \`recipes-bsp/u-boot/u-boot-fio_%.bbappend\`
- Potential new \`custom-dtb.cfg\` file

## Priority
Low - Only needed if i.MX8ULP EVK support is required"

# Issue 5: Binder Module Configuration Needs DISTRO-Based Logic
gh issue create \
  --repo "$REPO" \
  --title "Make Binder Module Configuration DISTRO-Based" \
  --label "enhancement" \
  --body "## Description
Kernel configuration for binder module should be conditional based on DISTRO instead of hardcoded.

## Current Issue
In \`recipes-kernel/linux/linux-lmp-fslc-imx_%.bbappend\` line 66-67:
\`\`\`
# TODO: Make binder module based on DISTRO
SRC_URI:append:imx8mm-jaguar-handheld = \" \\
\`\`\`

## Current State
Binder module configuration is hardcoded for specific machines, but should be based on DISTRO features.

## Proposed Solution
1. **Create DISTRO feature** for Android/Waydroid support:
   \`\`\`
   DISTRO_FEATURES:append = \" android-support\"
   \`\`\`

2. **Make binder conditional**:
   \`\`\`
   SRC_URI:append = \"\${@bb.utils.contains('DISTRO_FEATURES', 'android-support', ' file://enable_binder.cfg', '', d)}\"
   \`\`\`

3. **Update affected distros** to include the feature where needed

## Benefits
- More flexible configuration management
- Easier to enable/disable Android support
- Better separation of concerns
- Follows Yocto best practices

## Files to Update
- \`recipes-kernel/linux/linux-lmp-fslc-imx_%.bbappend\`
- Distro configuration files that need Android support
- Machine configs that currently hardcode binder

## Priority
Low-Medium - Better configuration management"

echo "✅ Specific TODO GitHub issues created successfully!"
echo "Visit: https://github.com/$REPO/issues to view created issues"
echo ""
echo "Summary of specific TODO issues created:"
echo "1. SE05X Configuration Not Taking Effect"
echo "2. OpTee Signing Key Configuration Missing"
echo "3. SPI Library C++ Warnings Need Fixing"
echo "4. U-Boot Device Tree Customization Missing"
echo "5. Binder Module Configuration Needs DISTRO-Based Logic"
