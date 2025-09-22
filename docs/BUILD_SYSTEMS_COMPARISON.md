# Build Systems Comparison: Local vs Cloud

## Overview

This document provides a **single source of truth** for understanding the critical differences between Dynamic Devices' three build systems. **These are fundamentally different architectures** and must not be confused.

## 🚨 **CRITICAL WARNING**

**Local KAS builds and Foundries.io cloud builds use completely different systems!**
- Different configuration files
- Different recipes (especially U-Boot)
- Different layer sources
- Different build parameters

**Confusing these systems leads to build failures and debugging confusion.**

---

## 📊 **Complete Build Systems Comparison**

| Aspect | **Standard Yocto** | **Local KAS** | **Foundries.io Cloud** |
|--------|-------------------|---------------|----------------------|
| **Purpose** | Learning/experimentation | Development/testing | Production deployment |
| **Trigger** | Manual `bitbake` | `kas-container build` | Commits to meta-subscriber-overrides |
| **Configuration** | Manual layer setup | KAS YAML files | factory-config.yml + manifest |
| **Environment** | Local development | KAS container | Foundries.io infrastructure |
| **Layer Sources** | Manual configuration | GitHub repos | Foundries.io + GitHub mix |
| **Signing** | Manual setup | Disabled (`SIGN_ENABLE=0`) | Enabled (production keys) |
| **U-Boot Recipes** | Standard recipes | Development recipes | **Different production recipes** |
| **Machine Selection** | Manual `MACHINE=` | `KAS_MACHINE=` | Branch-based (factory-config.yml) |
| **Build Speed** | Slow (no optimization) | Fast (optimized for dev) | Optimized for production |
| **Use Case** | Learning Yocto | Local development | Device deployment |

---

## 🏗️ **Local KAS Build System**

### **Configuration Files**
```
meta-dynamicdevices/kas/
├── base.yml                    # Foundries.io LmP base layers
├── bsp.yml                     # BSP layer configuration
├── dynamicdevices.yml          # Dynamic Devices layers
├── lmp-dynamicdevices-base.yml # Complete build configuration
└── lmp-dynamicdevices-mfgtool.yml # Manufacturing tools
```

### **How It Works**
1. **KAS reads YAML files** and automatically configures BitBake
2. **Downloads layers** from specified repositories
3. **Sets up build environment** with proper dependencies
4. **Optimized for development speed** with caching and parallel builds

### **Key Parameters**
```yaml
distro: lmp-dynamicdevices-base
target: lmp-factory-image
machine: imx93-jaguar-eink  # Set via KAS_MACHINE

local_conf_header:
  meta-dynamicdevices: |
    SIGN_ENABLE = "0"           # Signing disabled for development
    DEV_MODE = "1"              # Development mode enabled
    OPTEE_TA_SIGN_ENABLE = "0"  # OP-TEE signing disabled
```

### **Layer Sources (KAS)**
- **All from GitHub**: Public and private repositories
- **SSH access**: For private Dynamic Devices repositories
- **Version control**: Specific commits/branches per layer

---

## ☁️ **Foundries.io Cloud Build System**

### **Configuration Files**
```
/data_drive/dd/ci-scripts/
└── factory-config.yml          # Controls ALL cloud builds

/data_drive/dd/lmp-manifest/
├── dynamic-devices.xml         # Layer sources and versions
├── lmp-base.xml               # LmP base configuration
└── default.xml                # Default manifest
```

### **How It Works**
1. **Commit to meta-subscriber-overrides** triggers build
2. **factory-config.yml** maps branch to machine and parameters
3. **Manifest files** specify layer sources and versions
4. **Foundries.io infrastructure** performs the build

### **Branch → Machine Mapping**
```yaml
# factory-config.yml
ref_options:
  refs/heads/main-imx93-jaguar-eink:
    machines:
    - imx93-jaguar-eink
    params:
      DISTRO: lmp-dynamicdevices
      
  refs/heads/main-jaguar-sentai:
    machines:
    - imx8mm-jaguar-sentai
    params:
      DISTRO: lmp-dynamicdevices
```

### **Layer Sources (Manifest)**
```xml
<!-- dynamic-devices.xml -->
<project name="meta-subscriber-overrides"
         revision="main-imx93-jaguar-eink"    <!-- Branch-specific -->
         remote="subscriber-overrides"/>      <!-- Foundries.io hosted -->

<project name="meta-dynamicdevices"
         revision="main"                      <!-- Shared -->
         remote="dynamicdevices"/>            <!-- GitHub hosted -->
```

### **Key Differences from KAS**
- ✅ **Signing enabled**: Production security keys
- ✅ **Different U-Boot recipes**: Production-specific builds
- ✅ **Machine-specific branches**: Hardware safety isolation
- ✅ **Production parameters**: Optimized for deployment

---

## 🔄 **Critical Build Trigger Differences**

### **What Triggers Local KAS Builds**
```bash
# Manual trigger - immediate local build
KAS_MACHINE=imx93-jaguar-eink kas-container build kas/lmp-dynamicdevices-base.yml
```

### **What Triggers Foundries.io Cloud Builds**
```bash
# ONLY commits to meta-subscriber-overrides trigger cloud builds
cd /data_drive/dd/meta-subscriber-overrides
git commit --allow-empty -m "Force build"
git push  # This triggers the cloud build
```

### **What Does NOT Trigger Cloud Builds**
❌ Commits to meta-dynamicdevices (GitHub)
❌ Local KAS builds
❌ GitHub Actions CI builds
❌ Changes to KAS files

---

## 🧬 **Layer Integration Differences**

### **Local KAS Layer Integration**
```yaml
# kas/dynamicdevices.yml
repos:
  meta-dynamicdevices:          # Local development repo
  meta-dynamicdevices-bsp:      # Submodule from GitHub
    path: meta-dynamicdevices-bsp
  meta-dynamicdevices-distro:   # Submodule from GitHub
    path: meta-dynamicdevices-distro
```

### **Cloud Build Layer Integration**
```xml
<!-- Foundries.io accesses layers differently -->
<project name="meta-dynamicdevices-bsp"
         revision="main"
         path="layers/meta-dynamicdevices/meta-dynamicdevices-bsp"
         remote="dynamicdevices"/>  <!-- Direct GitHub access -->
```

**Critical Insight**: Cloud builds access submodules directly from GitHub, not through the parent repository structure.

---

## 🔐 **Security & Signing Differences**

| Security Aspect | Local KAS | Foundries.io Cloud |
|-----------------|-----------|-------------------|
| **Code Signing** | Disabled | Enabled |
| **U-Boot Signing** | Disabled | Enabled |
| **OP-TEE Signing** | Disabled | Enabled |
| **Key Storage** | Dummy files | Foundries.io secure storage |
| **Purpose** | Development speed | Production security |

### **Local Development Security**
```yaml
# Signing disabled for speed
SIGN_ENABLE = "0"
UBOOT_SIGN_ENABLE = "0"
OPTEE_TA_SIGN_ENABLE = "0"

# Dummy key paths to prevent build failures
SIGNING_UBOOT_SIGN_KEY = "${TOPDIR}/bitbake.lock"
```

### **Production Security**
- ✅ **Real signing keys** stored securely by Foundries.io
- ✅ **Secure boot** enabled for production devices
- ✅ **Code integrity** verification
- ✅ **OTA update security**

---

## 🎯 **Machine-Specific Branch Strategy**

### **Why Machine-Specific Branches?**
1. **🔧 Hardware Differences**: Each machine has different firmware requirements
2. **🛡️ Safety First**: CRITICAL to prevent breaking one machine when making changes for another
3. **🚀 New Board Safety**: When adding support for new machines/boards, must not break existing boards
4. **⚡ Firmware Isolation**: Different hardware needs different firmware updates

### **Branch Architecture**
```
Shared Core Repositories:
├── meta-dynamicdevices         # Application layer (GitHub)
├── meta-dynamicdevices-bsp     # Hardware support (GitHub)
└── meta-dynamicdevices-distro  # Distribution policies (GitHub)

Machine-Specific Triggers:
└── meta-subscriber-overrides   # Foundries.io hosted
    ├── main-imx93-jaguar-eink  # E-Ink board firmware
    ├── main-imx8mm-jaguar-sentai # Sentai board firmware
    └── main-rpi4               # Raspberry Pi firmware
```

---

## 🚨 **Common Confusion Points**

### **❌ Mistake: Assuming KAS Config Affects Cloud Builds**
```bash
# This change has NO effect on cloud builds
echo "NEW_PARAM = 'value'" >> kas/lmp-dynamicdevices-base.yml
```
**Reality**: Cloud builds use factory-config.yml, not KAS files.

### **❌ Mistake: Wrong Repository for Cloud Build Triggers**
```bash
# This does NOT trigger cloud builds
cd meta-dynamicdevices
git commit -m "Change for cloud"
git push
```
**Reality**: Only meta-subscriber-overrides commits trigger cloud builds.

### **❌ Mistake: Expecting Same U-Boot Behavior**
Local KAS builds and cloud builds use **different U-Boot recipes**.
**Reality**: Test both systems separately.

### **❌ Mistake: Submodule Reference Confusion**
```bash
# Local: Uses submodule references in parent repo
cd meta-dynamicdevices-bsp
git push  # Not enough for cloud builds!

# Cloud: Needs parent repo update AND submodule push
cd meta-dynamicdevices
git add meta-dynamicdevices-bsp
git commit -m "Update submodule"
git push
```

---

## 📋 **Best Practices**

### **Development Workflow**
1. **Use KAS for local development** - fast iteration
2. **Test critical changes in cloud builds** - production validation
3. **Never assume local == cloud** - always verify both
4. **Use machine-specific branches** - hardware safety first

### **Debugging Strategy**
1. **Identify which build system** you're debugging
2. **Check appropriate configuration files**:
   - Local issues → KAS YAML files
   - Cloud issues → factory-config.yml + manifest
3. **Verify correct trigger method** used
4. **Check submodule references** for cloud builds

### **Safety Guidelines**
- ✅ **Always use machine-specific branches** for cloud builds
- ✅ **Test new boards** without affecting existing ones
- ✅ **Verify submodule references** before cloud builds
- ✅ **Monitor both mfgtools and main builds**

---

## 🔗 **Related Documentation**
- `docs/FOUNDRIES_IO_BUILD_SYSTEM.md` - Detailed Foundries.io architecture
- `docs/power-optimization-master-plan.md` - Power optimization implementation
- `scripts/README.md` - Build script documentation
- `.github/workflows/kas-build-ci.yml` - CI build configuration

---

**This document is the single source of truth for build system differences. Keep it updated as systems evolve.**
