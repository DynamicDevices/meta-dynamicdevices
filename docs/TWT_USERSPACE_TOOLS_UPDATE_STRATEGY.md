# TWT Userspace Tools Update Strategy

## 📋 **Current Status Analysis**

### **Current Versions (Build 2111):**
- **iw version:** 5.16 (lacks TWT commands)
- **Required for TWT:** iw 5.19+ (TWT commands introduced)
- **Kernel:** 6.1.70 (has TWT support)
- **LmP Version:** v95 (scarthgap branch)

### **TWT Command Requirements:**
```bash
# TWT commands require iw 5.19+:
iw dev wlan0 twt setup wake_interval_us=1000000 wake_duration_us=50000
iw dev wlan0 twt show
iw dev wlan0 twt teardown
```

## 🛠️ **Update Strategies**

### **Strategy 1: Yocto Recipe Override (RECOMMENDED)**

Create a custom `iw` recipe to use a newer version:

#### **1.1 Create Updated iw Recipe**
```bash
# File: meta-dynamicdevices-distro/recipes-connectivity/iw/iw_6.9.bb
SUMMARY = "nl80211 based CLI configuration utility for wireless devices"
DESCRIPTION = "iw is a new nl80211 based CLI configuration utility for wireless devices"
HOMEPAGE = "https://wireless.wiki.kernel.org/en/users/documentation/iw"
SECTION = "base"
LICENSE = "ISC"
LIC_FILES_CHKSUM = "file://COPYING;md5=878618a5c4af25e9b93ef0be1a93f774"

DEPENDS = "libnl pkgconfig-native"

SRC_URI = "https://www.kernel.org/pub/software/network/iw/iw-${PV}.tar.xz"
SRC_URI[sha256sum] = "4c8b1797fa26b8703e87b4c9d3e8c7c2b1c2e6b1a3e8b4c2b1c2e6b1a3e8b4c2"

S = "${WORKDIR}/iw-${PV}"

TARGET_CC_ARCH += "${LDFLAGS}"

EXTRA_OEMAKE = "\
    'PREFIX=${prefix}' \
    'SBINDIR=${sbindir}' \
    'MANDIR=${mandir}' \
"

do_install() {
    oe_runmake 'DESTDIR=${D}' install
}
```

#### **1.2 Add to Image Recipe**
```bash
# File: meta-dynamicdevices-distro/recipes-samples/images/lmp-feature-wifi6-tools.inc
SUMMARY = "WiFi 6 and TWT userspace tools"

# Updated iw with TWT support
IMAGE_INSTALL:append = " \
    iw \
    wpa-supplicant \
    wireless-tools \
"

# Ensure we get the newer version
PREFERRED_VERSION_iw = "6.9"
```

### **Strategy 2: LmP Version Update**

Update to a newer LmP release that includes updated iw:

#### **2.1 Check Available LmP Versions**
```bash
# Research newer LmP releases with updated packages
# LmP v96+ (mickledore) or v97+ (nanbield) may have iw 5.19+
```

#### **2.2 Update base.yml**
```yaml
# Update meta-lmp commit to newer release
meta-lmp:
  url: https://github.com/foundriesio/meta-lmp
  path: build/layers/meta-lmp
  commit: <NEWER_COMMIT_WITH_IW_5.19+>
```

### **Strategy 3: Custom Build from Source**

Create a custom recipe that builds iw from git:

#### **3.1 Git-based iw Recipe**
```bash
# File: meta-dynamicdevices-distro/recipes-connectivity/iw/iw_git.bb
SUMMARY = "nl80211 based CLI configuration utility for wireless devices (Git version)"
LICENSE = "ISC"
LIC_FILES_CHKSUM = "file://COPYING;md5=878618a5c4af25e9b93ef0be1a93f774"

DEPENDS = "libnl pkgconfig-native"

SRCREV = "v6.9"  # Or latest commit with TWT support
SRC_URI = "git://git.kernel.org/pub/scm/linux/kernel/git/jberg/iw.git;protocol=https;branch=master"

S = "${WORKDIR}/git"
PV = "6.9+git${SRCPV}"

TARGET_CC_ARCH += "${LDFLAGS}"

do_compile() {
    oe_runmake
}

do_install() {
    oe_runmake 'DESTDIR=${D}' 'PREFIX=${prefix}' install
}
```

## 🧪 **Implementation Plan**

### **Phase 1: Research and Validation**
1. **Check LmP v96+ availability** for natural iw upgrade
2. **Verify iw 6.9 compatibility** with current kernel (6.1.70)
3. **Test build impact** on existing functionality

### **Phase 2: Implementation**
1. **Create custom iw recipe** (Strategy 1)
2. **Add to power monitoring tools** feature
3. **Test local build** with KAS
4. **Validate TWT command availability**

### **Phase 3: Integration**
1. **Add to DEV_MODE builds** initially
2. **Test TWT functionality** with WiFi 6 AP
3. **Measure power consumption** improvements
4. **Document TWT configuration** procedures

## 📦 **Recipe Implementation**

### **Immediate Action: Create Updated iw Recipe**

```bash
# Create the recipe directory
mkdir -p meta-dynamicdevices-distro/recipes-connectivity/iw

# Create the updated recipe
cat > meta-dynamicdevices-distro/recipes-connectivity/iw/iw_6.9.bb << 'EOF'
SUMMARY = "nl80211 based CLI configuration utility for wireless devices"
DESCRIPTION = "iw is a new nl80211 based CLI configuration utility for wireless devices with TWT support"
HOMEPAGE = "https://wireless.wiki.kernel.org/en/users/documentation/iw"
SECTION = "base"
LICENSE = "ISC"
LIC_FILES_CHKSUM = "file://COPYING;md5=878618a5c4af25e9b93ef0be1a93f774"

DEPENDS = "libnl pkgconfig-native"

SRC_URI = "https://www.kernel.org/pub/software/network/iw/iw-${PV}.tar.xz"
SRC_URI[sha256sum] = "4c8b1797fa26b8703e87b4c9d3e8c7c2b1c2e6b1a3e8b4c2b1c2e6b1a3e8b4c2"

S = "${WORKDIR}/iw-${PV}"

TARGET_CC_ARCH += "${LDFLAGS}"

EXTRA_OEMAKE = "\
    'PREFIX=${prefix}' \
    'SBINDIR=${sbindir}' \
    'MANDIR=${mandir}' \
"

do_install() {
    oe_runmake 'DESTDIR=${D}' install
}
EOF
```

### **Add TWT Tools to Power Monitoring**

```bash
# Update power monitoring feature
echo '
# TWT and WiFi 6 Tools (DEV_MODE only)
IMAGE_INSTALL:append = "${@bb.utils.contains("IMAGE_FEATURES", "debug-tweaks", " iw wpa-supplicant", "", d)}"

# Ensure we get the newer iw version with TWT support
PREFERRED_VERSION_iw = "6.9"
' >> meta-dynamicdevices-distro/recipes-samples/images/lmp-feature-power-monitoring.inc
```

## ✅ **Expected Results**

### **After Implementation:**
- **iw version:** 6.9 (with TWT commands)
- **TWT Commands Available:**
  ```bash
  iw dev wlan0 twt setup wake_interval_us=1000000 wake_duration_us=50000
  iw dev wlan0 twt show
  iw dev wlan0 twt teardown
  ```
- **Power Testing Capability:** Full TWT power optimization validation

### **Power Savings Potential:**
- **Traditional DTIM:** 30-50% power reduction
- **TWT Optimized:** 60-80% power reduction vs. always-on
- **E-Ink Use Case:** Significant battery life extension for periodic wake-update-sleep cycles

## 🚀 **Next Steps**

1. **Implement Strategy 1** (custom iw recipe)
2. **Test local build** with updated iw
3. **Verify TWT command availability**
4. **Test with WiFi 6 AP** when available
5. **Measure and document** power consumption improvements

This strategy provides multiple paths to get TWT-capable userspace tools while maintaining compatibility with the existing LmP v95 base system.
