# Foundries.io Build System Integration Guide

## Overview

This document explains the relationship between meta-dynamicdevices layers and the Foundries.io build system, covering the critical differences between Standard Yocto, Local KAS builds, and Foundries.io Cloud builds.

## 🏗️ **Build System Architecture**

### **Three Different Build Systems**

1. **Standard Yocto Builds** - Traditional BitBake/Yocto workflow
2. **Local KAS Builds** - Development builds using KAS container system  
3. **Foundries.io Cloud Builds** - Production builds triggered by repository commits

⚠️ **CRITICAL**: These are NOT the same and have different requirements!

## 📁 **Repository Structure**

### **Primary Repositories**

```
Dynamic Devices Build Ecosystem:

meta-dynamicdevices/                    # Main development repo (GitHub)
├── meta-dynamicdevices-bsp/           # BSP submodule (hardware-specific)
├── meta-dynamicdevices-distro/        # Distro submodule (system policies)
├── kas/                               # KAS build configurations
├── recipes-*/                         # Application layer recipes
└── docs/                              # Documentation

meta-subscriber-overrides/              # Foundries.io trigger repo (Foundries.io hosted)
├── recipes-bsp/                       # Cloud build overrides
├── recipes-samples/                   # Image customizations
├── recipes-support/                   # Support recipe overrides
└── conf/layer.conf                    # Layer configuration
```

### **Layer Hierarchy & Priorities**

```
Layer Processing Order (BBFILE_PRIORITY):
├── meta-subscriber-overrides: 12      # Foundries.io overrides (highest)
├── meta-dynamicdevices-bsp: 12        # Hardware foundation  
├── meta-dynamicdevices: 11            # Application layer
├── meta-dynamicdevices-distro: 10     # Distribution policies (lowest)
└── meta-lmp-base: 7                   # Foundries.io base layer
```

## 🔄 **Build System Differences**

### **1. Standard Yocto Builds**
- **Purpose**: Traditional Yocto development
- **Trigger**: Manual `bitbake` commands
- **Environment**: Local development machine
- **Layers**: All layers must be manually configured
- **Use Case**: Learning, experimentation, custom workflows

### **2. Local KAS Builds** 
- **Purpose**: Development and testing
- **Trigger**: `kas-container build kas/lmp-dynamicdevices-base.yml`
- **Environment**: KAS container system
- **Layers**: Automatically configured via KAS YAML files
- **Repository**: Uses local meta-dynamicdevices repository
- **Signing**: Disabled for development (`SIGN_ENABLE=0`)
- **Use Case**: Local development, testing, CI validation

**Key KAS Files:**
- `kas/base.yml` - Foundries.io LmP base layers
- `kas/bsp.yml` - BSP layer configuration  
- `kas/dynamicdevices.yml` - Dynamic Devices layers
- `kas/lmp-dynamicdevices-base.yml` - Complete build configuration

### **3. Foundries.io Cloud Builds**
- **Purpose**: Production image generation
- **Trigger**: Commits to `meta-subscriber-overrides` repository
- **Environment**: Foundries.io cloud infrastructure
- **Layers**: Automatically configured by Foundries.io
- **Repository**: Uses Foundries.io-hosted repositories
- **Signing**: Enabled for production security
- **Use Case**: Production images, OTA updates, device deployment

## 🚨 **Critical Build Trigger Rules**

### **What Triggers Foundries.io Cloud Builds**
✅ **Commits to meta-subscriber-overrides** (Foundries.io hosted)
✅ **Commits to meta-dynamicdevices-bsp** (when submodule updated)
✅ **Commits to meta-dynamicdevices-distro** (when submodule updated)

### **What Does NOT Trigger Cloud Builds**
❌ **Commits to meta-dynamicdevices** (GitHub hosted)
❌ **Local KAS builds**
❌ **GitHub Actions CI builds**

### **Force Build Process**
```bash
# CORRECT: Trigger cloud build
cd /data_drive/dd/meta-subscriber-overrides
git commit --allow-empty -m "Force build"
git push

# WRONG: Does not trigger cloud build  
cd /data_drive/dd/meta-dynamicdevices
git commit --allow-empty -m "Force build"
git push
```

## 🔗 **Submodule Integration**

### **Critical Submodule Workflow**
When making changes to BSP or distro layers:

1. **Make changes in submodule**
   ```bash
   cd meta-dynamicdevices-bsp
   # Make changes...
   git add .
   git commit -m "Fix: device tree issue"
   git push origin main
   ```

2. **Update parent repository reference**
   ```bash
   cd ..  # Back to meta-dynamicdevices
   git add meta-dynamicdevices-bsp
   git commit -m "Update BSP submodule: device tree fix"
   git push origin main
   ```

3. **Trigger cloud build**
   ```bash
   cd /data_drive/dd/meta-subscriber-overrides
   git commit --allow-empty -m "Force build with BSP fix"
   git push
   ```

⚠️ **Common Mistake**: Pushing submodule changes without updating parent repository reference. Cloud builds will use the old submodule commit!

## 📋 **Layer Dependencies**

### **meta-dynamicdevices (Main Layer)**
```
LAYERDEPENDS = "meta-lmp-base meta-dynamicdevices-bsp meta-dynamicdevices-distro"
```

### **meta-dynamicdevices-bsp (BSP Layer)**  
```
LAYERDEPENDS = "meta-lmp-base"  # Conditional dependency
```

### **meta-dynamicdevices-distro (Distribution Layer)**
```
LAYERDEPENDS = "meta-lmp-base meta-dynamicdevices-bsp"
```

### **meta-subscriber-overrides (Cloud Override Layer)**
```
LAYERDEPENDS = "meta-lmp-base meta-dynamicdevices"
```

## 🎯 **Best Practices**

### **Development Workflow**
1. **Local Development**: Use KAS builds for testing
2. **BSP Changes**: Always update submodule references
3. **Cloud Testing**: Trigger builds from meta-subscriber-overrides
4. **Multi-board Safety**: Use machine-specific conditionals

### **Build Debugging**
1. **Check mfgtools first** - acts as canary for main build
2. **Verify submodule references** - common source of cloud build failures
3. **Check correct repository** - ensure commits go to right repo for cloud builds
4. **Monitor build logs** - use browser cookie authentication for real-time logs

### **Repository Management**
- **meta-dynamicdevices**: Development, documentation, KAS configs
- **meta-dynamicdevices-bsp**: Hardware-specific changes only
- **meta-dynamicdevices-distro**: System-wide policies only  
- **meta-subscriber-overrides**: Cloud build triggers and overrides only

## 🔧 **Troubleshooting Common Issues**

### **Cloud Build Not Triggered**
- ✅ Check: Committed to meta-subscriber-overrides?
- ✅ Check: Pushed to correct branch?
- ✅ Check: Remote response shows "Trigger CI job"?

### **Cloud Build Uses Old Code**
- ✅ Check: Submodule references updated in parent repo?
- ✅ Check: BSP/distro changes pushed to Foundries.io?
- ✅ Check: Parent repo pushed after submodule update?

### **Local vs Cloud Build Differences**
- ✅ Check: Signing configuration differences
- ✅ Check: Layer priority conflicts
- ✅ Check: Machine-specific conditionals

## 📚 **Related Documentation**
- `docs/LAYER_ORGANIZATION.md` - Layer structure and content organization
- `docs/power-optimization-master-plan.md` - Power optimization implementation
- `scripts/README.md` - Build script documentation
- `.github/workflows/kas-build-ci.yml` - CI build configuration

---
*This document is critical for understanding the Dynamic Devices build ecosystem. Keep it updated as the system evolves.*

## 📁 **Local Repository Locations**

### **Development Repository Structure**

Dynamic Devices maintains local repositories for development and private business code in three main locations:

#### **🏢 /data_drive/dd/ - Core Dynamic Devices**
```
/data_drive/dd/
├── meta-dynamicdevices/           # Main Yocto layer development
├── meta-subscriber-overrides/     # Foundries.io cloud build triggers  
├── lmp-manifest/                  # Linux Microplatform manifest
├── lmp-tools/                     # Foundries.io LmP tools
├── containers/                    # Container configurations
├── ci-scripts/                    # CI/CD automation scripts
├── meta-raspberrypi/              # Raspberry Pi BSP layer
└── wic-editor/                    # WIC image editor tools
```

#### **🎯 /data_drive/sentai/ - Sentai Project**
```
/data_drive/sentai/
├── conversav1/ & conversav2/      # Conversa audio applications
├── tas2781-linux-driver/          # Audio codec driver development
├── radar-distance/                # Radar sensor applications
├── spi-lib/                       # SPI communication library
├── continuous_monitoring/         # System monitoring applications
├── imx-firmware/                  # i.MX firmware files
├── regbin/                        # Register binary tools
└── meta-subscriber-overrides/     # Sentai-specific overrides
```

#### **🖥️ /data_drive/esl/ - E-Ink/ESL Project**
```
/data_drive/esl/
├── eink-spectra6/                 # E-Ink display driver (CRITICAL for imx93-jaguar-eink)
├── eink-microcontroller/          # Microcontroller power management
├── active-16ch-bmp/               # 16-channel BMP sensor
├── active-cantool/                # CAN bus communication tools
├── hello-world-yocto-ai-dev/      # AI development examples
└── zephyr-workspace/              # Zephyr RTOS development
```

### **Repository Access Patterns**

#### **Private Repository Access**
```bash
# SSH protocol for private repositories
SRC_URI = "git://git@github.com/DynamicDevices/eink-spectra6.git;protocol=ssh;branch=${SRCBRANCH}"

# Disable mirror tarballs for private repos
BB_GENERATE_MIRROR_TARBALLS = "0"

# SSH agent forwarding required
# kas-container --ssh-agent --ssh-dir ${HOME}/.ssh
```

#### **Public Repository Access**
```bash
# HTTPS protocol for public repositories
SRC_URI = "git://github.com/DynamicDevices/radar-sdk.git;protocol=https;branch=main"

# Standard checksum verification
SRC_URI[sha256sum] = "actual-sha256-hash"
```

### **Critical Repository Dependencies**

#### **eink-spectra6 (E-Ink Driver)**
- **Location**: `/data_drive/esl/eink-spectra6`
- **Access**: Private SSH repository
- **Importance**: CRITICAL for imx93-jaguar-eink builds
- **Recipe**: `meta-subscriber-overrides/recipes-bsp/eink-spectra6/eink-spectra6_git.bb`
- **Features**: Requires `el133uf1` machine feature
- **Dependencies**: libgpiod, CMake, systemd

#### **spi-lib (Radar Communication)**
- **Location**: `/data_drive/sentai/spi-lib`
- **Access**: Private SSH repository  
- **Recipe**: `meta-dynamicdevices-bsp/recipes-bsp/spi-lib/spi-lib_git.bb`
- **Purpose**: SPI communication for radar sensors

#### **tas2781-linux-driver (Audio)**
- **Location**: `/data_drive/sentai/tas2781-linux-driver`
- **Purpose**: Audio codec driver development
- **Target**: imx8mm-jaguar-sentai boards

### **Development Workflow**

#### **Local Development**
1. **Clone/update local repositories**:
   ```bash
   cd /data_drive/esl/eink-spectra6
   git pull origin main
   ```

2. **Test changes locally**:
   ```bash
   cd /data_drive/esl/eink-spectra6
   mkdir build && cd build
   cmake .. && make
   ```

3. **Update recipe SRCREV**:
   ```bash
   # In meta-subscriber-overrides/recipes-bsp/eink-spectra6/eink-spectra6_git.bb
   SRCREV = "new-commit-hash"
   ```

#### **Build Integration**
- **Local KAS builds**: Access via SSH agent forwarding
- **Cloud builds**: Foundries.io accesses via SSH keys
- **CI builds**: GitHub Actions with SSH key secrets

### **Security Considerations**

#### **SSH Key Management**
- **Development**: SSH keys in `~/.ssh/`
- **KAS builds**: `--ssh-agent --ssh-dir` options
- **Cloud builds**: Foundries.io SSH key configuration
- **CI builds**: GitHub Secrets for SSH keys

#### **Private Repository Protection**
- **No mirror tarballs**: `BB_GENERATE_MIRROR_TARBALLS = "0"`
- **SSH protocol only**: No HTTPS for private repos
- **Access control**: GitHub repository permissions
- **Key rotation**: Regular SSH key updates

### **Troubleshooting Repository Access**

#### **Common Issues**
1. **SSH key not available**: Check `ssh-add -l`
2. **Wrong protocol**: Ensure SSH for private repos
3. **Missing dependencies**: Verify `DEPENDS` in recipes
4. **Build cache issues**: Clear downloads if needed

#### **Debug Commands**
```bash
# Test SSH access
ssh -T git@github.com

# Check SSH agent
ssh-add -l

# Verify repository access
git ls-remote git@github.com/DynamicDevices/eink-spectra6.git
```

---
*When accessing upstream source code or debugging build issues, always check these local repository locations first.*

## 🌿 **Machine-Specific Branch Strategy**

### **Why Machine-Specific Branches?**

Foundries.io uses machine-specific branches in `meta-subscriber-overrides` for **critical hardware safety reasons**:

1. **🔧 Hardware Differences**: Each machine has different firmware requirements
2. **🛡️ Safety First**: CRITICAL to prevent breaking one machine when making changes for another
3. **🚀 New Board Safety**: When adding support for new machines/boards, must not break existing boards
4. **⚡ Firmware Isolation**: Different hardware needs different firmware updates
5. **🎯 Build Separation**: Prevents cross-contamination between board types

### **Branch Pattern**

```
meta-subscriber-overrides branches:
├── main-imx93-jaguar-eink      # E-Ink board firmware
├── main-imx8mm-jaguar-sentai   # Sentai audio board firmware  
├── main-rpi4                   # Raspberry Pi 4 firmware
├── main-jaguar-*               # Various Jaguar board variants
└── main                        # Base/shared configurations
```

### **Architecture Benefits**

#### **Shared Core + Machine-Specific Overrides**
```
Core Repositories (Shared):
├── meta-dynamicdevices         # Application layer (shared)
├── meta-dynamicdevices-bsp     # Hardware support (shared)
└── meta-dynamicdevices-distro  # Distribution policies (shared)

Machine-Specific Triggers:
└── meta-subscriber-overrides   # Machine-specific branches trigger builds
    ├── main-imx93-jaguar-eink  # E-Ink specific overrides
    └── main-imx8mm-jaguar-sentai # Sentai specific overrides
```

#### **Safety Guarantees**
- ✅ **Isolated builds**: Changes to E-Ink board cannot break Sentai board
- ✅ **Hardware-specific firmware**: Each machine gets appropriate firmware
- ✅ **Rollback safety**: Can revert one machine without affecting others
- ✅ **Development safety**: Test new boards without risking production boards

### **Workflow Example**

#### **Adding New Board Support**
1. **Create new branch**: `main-new-board-name`
2. **Add board-specific overrides**: Only affects new board
3. **Test thoroughly**: No impact on existing boards
4. **Deploy safely**: Existing boards continue working

#### **Updating Existing Board**
1. **Work on specific branch**: `main-imx93-jaguar-eink`
2. **Make targeted changes**: Only affects E-Ink boards
3. **Test and deploy**: Other boards unaffected
4. **Monitor results**: Isolated impact assessment

### **Critical Safety Principle**

> **"When updating meta-dynamicdevices metadata, we must ensure firmware builds don't break existing functionality"**

This branch strategy is **essential for hardware safety** and prevents the catastrophic scenario where a firmware update for one board type accidentally breaks a completely different board type in production.


---

## 📚 **SINGLE SOURCE OF TRUTH: Build System Differences**

> **⚠️ CRITICAL**: See `docs/BUILD_SYSTEMS_COMPARISON.md` for the complete comparison table and detailed analysis.

### **Key Takeaways**

1. **🚨 Different Systems**: KAS ≠ Foundries.io Cloud builds
2. **🔧 Different Recipes**: Especially U-Boot recipes differ between systems
3. **📋 Different Configuration**: KAS YAML vs factory-config.yml + manifest
4. **🔐 Different Security**: Development (no signing) vs Production (signing enabled)
5. **🌿 Machine Safety**: Branch isolation prevents cross-hardware contamination

### **Quick Reference**

| Need | Use This System |
|------|----------------|
| **Fast local development** | KAS builds |
| **Production deployment** | Foundries.io cloud builds |
| **Learning Yocto** | Standard Yocto |
| **CI validation** | GitHub Actions (KAS-based) |

### **Trigger Commands**

```bash
# Local KAS build
KAS_MACHINE=imx93-jaguar-eink kas-container build kas/lmp-dynamicdevices-base.yml

# Cloud build trigger
cd /data_drive/dd/meta-subscriber-overrides
git commit --allow-empty -m "Force build"
git push
```

### **Configuration Files**

```
Local Development:
└── meta-dynamicdevices/kas/*.yml

Cloud Production:
├── /data_drive/dd/ci-scripts/factory-config.yml
└── /data_drive/dd/lmp-manifest/dynamic-devices.xml
```

**For complete details, troubleshooting, and comparison tables, see `docs/BUILD_SYSTEMS_COMPARISON.md`.**

