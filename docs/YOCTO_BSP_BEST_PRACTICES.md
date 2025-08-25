# Yocto BSP Best Practices for meta-dynamicdevices

## Recipe Licensing Guidelines

### Layer vs Component Licensing
- **Layer License** (`LICENSE` file): Applies to the Yocto layer itself (recipes, configurations, patches)
- **Component License** (recipe `LICENSE` field): Applies to the software being built by each recipe

### Component License Examples
```bash
# Open source components
LICENSE = "MIT"
LICENSE = "GPL-2.0-only"
LICENSE = "Apache-2.0"
LICENSE = "BSD-3-Clause"

# Dual licensed components
LICENSE = "GPL-2.0-only | MIT"

# Proprietary/closed source
LICENSE = "CLOSED"

# Multiple licenses in same component
LICENSE = "GPL-2.0-only & MIT"
```

### License Checksum Requirements
```bash
# For components with license files
LIC_FILES_CHKSUM = "file://LICENSE;md5=actual-md5-hash"
LIC_FILES_CHKSUM = "file://COPYING;md5=actual-md5-hash"

# For components using common licenses
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0-only;md5=801f80980d171dd6425610833a22dbe6"
```

## Professional Recipe Standards

### Required Recipe Headers
Every recipe should include:
1. **SUMMARY**: One-line description
2. **DESCRIPTION**: Detailed explanation
3. **HOMEPAGE**: Project URL
4. **SECTION**: Category (base, kernel, multimedia, etc.)
5. **LICENSE**: Component license(s)
6. **LIC_FILES_CHKSUM**: License verification
7. **MAINTAINER**: Contact information

### File Organization
```
recipes-category/
├── package-name/
│   ├── package-name/          # Package-specific files
│   │   ├── patches/          # Patches directory
│   │   ├── config-file.conf  # Configuration files
│   │   └── service-file.service
│   └── package-name_version.bb
```

### Machine Compatibility
```bash
# For board-specific recipes
COMPATIBLE_MACHINE = "imx8mm-jaguar-sentai"

# For multiple boards
COMPATIBLE_MACHINE = "(imx8mm-jaguar-sentai|imx93-jaguar-eink)"

# For architecture-specific
COMPATIBLE_HOST = "aarch64.*-linux"
```

## Code Quality Standards

### Recipe Formatting
- Use 4-space indentation
- Align multi-line assignments with backslashes
- Group related variables together
- Add comments for complex logic

### Variable Naming
```bash
# Good - descriptive and clear
DYNAMIC_DEVICES_CONFIG_FILE = "edge-config.conf"
TAS2563_FIRMWARE_VERSION = "1.2.3"

# Avoid - vague or generic
CONFIG_FILE = "config.conf"
VERSION = "1.2.3"
```

### File Paths
```bash
# Use proper directory variables
install -d ${D}${bindir}
install -d ${D}${sysconfdir}
install -d ${D}${systemd_unitdir}/system

# Avoid hardcoded paths
install -d ${D}/usr/bin          # Wrong
install -d ${D}/etc             # Wrong
```

## Security Considerations

### Secure Downloads
```bash
# Always use HTTPS when possible
SRC_URI = "https://github.com/example/repo.git;protocol=https"

# Include checksums for tarballs
SRC_URI[sha256sum] = "actual-sha256-hash"
```

### Privilege Separation
```bash
# Run services as non-root when possible
SYSTEMD_SERVICE:${PN} = "example.service"

# In service files:
# [Service]
# User=nobody
# Group=nogroup
```

## Testing and Validation

### Build Testing
- Test recipes on clean build environment
- Verify all dependencies are declared
- Check for build warnings and errors

### Runtime Testing
- Verify service files start correctly
- Test configuration file parsing
- Validate file permissions and ownership

### Documentation
- Update CHANGELOG.md for significant changes
- Maintain accurate README.md
- Document configuration options

## Layer Maintenance

### Version Management
- Use semantic versioning (MAJOR.MINOR.PATCH)
- Tag releases consistently
- Maintain compatibility across Yocto versions

### Dependency Management
```bash
# Explicit dependencies
DEPENDS = "required-build-dependency"
RDEPENDS:${PN} = "required-runtime-dependency"

# Version-specific dependencies when needed
RDEPENDS:${PN} = "package-name (>= 1.2.0)"
```

### Machine Configuration
```bash
# Use feature-based configuration
MACHINE_FEATURES += "wifi bluetooth"
DISTRO_FEATURES += "systemd"

# Avoid hardcoded values
KERNEL_DEVICETREE += "${MACHINE}-board.dtb"
```

## Common Pitfalls to Avoid

1. **Mixing layer and component licenses**
2. **Missing or incorrect license checksums**
3. **Hardcoded file paths**
4. **Missing runtime dependencies**
5. **Overly broad machine compatibility**
6. **Insufficient error handling in custom tasks**
7. **Missing service file installation**
8. **Incorrect file permissions**

## Review Checklist

Before submitting recipes:
- [ ] All required headers present
- [ ] Correct component license specified
- [ ] License checksum verified
- [ ] Dependencies declared
- [ ] Machine compatibility appropriate
- [ ] Service files properly installed
- [ ] Documentation updated
- [ ] Build tested on clean environment
