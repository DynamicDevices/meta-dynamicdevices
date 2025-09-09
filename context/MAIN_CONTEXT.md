# meta-dynamicdevices Main Context

## Overview
Yocto/OpenEmbedded layers for Dynamic Devices Edge boards on Linux microPlatform (LmP).

## Boards
- **Edge AI** (imx8mm-jaguar-sentai) - Audio processing, TAS2563 driver
- **Edge EInk** (imx93-jaguar-eink) - E-ink display, optimized kernel, flexible WiFi
- **Edge EV/GW** - Future boards

## Recent Updates ✅
- **🚀 fio-program-board.sh v2.0.0**: Complete automation with auto-latest target, default factory support, one-command programming
- **🪟 fio-program-board.bat**: Windows batch version with dependency checking and auto-install (latest target detection WIP)
- **⚡ Auto-Programming**: `--program` flag for download + program in single command (no interactive wait)
- **🔄 Continuous Mode**: `--continuous` flag for batch programming multiple boards with tracking
- **💾 Smart Caching**: Intelligent file caching with `--force` override
- **🔧 i.MX93 Optimization**: Fixed bootloader size issues, uses correct MFGTools bootloader
- **⏱️ Performance Timing**: Real-time download and programming performance tracking
- **🏭 Default Factory**: Uses fioctl's default factory configuration
- **TAS2563**: Android driver with firmware support (Edge AI)
- **WiFi Firmware**: Flexible .se/.bin selection (Edge EInk)
- **Kernel**: Optimized drivers for faster boot (Edge EInk)  

## Structure
- **Main**: recipes-*, kas/, scripts/, docs/
- **BSP**: meta-dynamicdevices-bsp/ (hardware support)
- **Distro**: meta-dynamicdevices-distro/ (distribution policies)
- **Build**: build/layers/ (external layers)

## Technologies
- **SoCs**: i.MX8MM (Edge AI), i.MX93 (Edge EInk)
- **Wireless**: NXP IW612 (WiFi 6, BT 5.4, 802.15.4)
- **Audio**: TAS2563 with Android driver + firmware
- **Power**: Advanced PM for low-power applications

## Architecture
- **Main**: meta-dynamicdevices (apps/middleware)
- **BSP**: meta-dynamicdevices-bsp (hardware support)
- **Distro**: meta-dynamicdevices-distro (distribution policies)
- **Dependencies**: meta-lmp, meta-freescale, meta-openembedded

## Build Systems Architecture

### Critical Understanding: Local vs Cloud Builds

**⚠️ IMPORTANT**: There are **TWO SEPARATE BUILD SYSTEMS**:

1. **Local Development Builds** (KAS-based)
   - Uses `kas/` configuration files in this repository
   - For development, testing, and local debugging
   - Controlled by local KAS YAML configurations
   - **NOT used for production mfgtools-files**

2. **Foundries.io Cloud Builds** (Production)
   - Builds triggered by pushes to Foundries.io-hosted repositories
   - Generates production `mfgtools-files` downloaded by fio-program-board scripts
   - **Controlled by recipes/configurations pushed to Foundries.io**
   - **NOT controlled by local KAS files**

### Key Learnings from SE050 Investigation

**🔍 SE050/OP-TEE Configuration Issues:**
- SE050 failures in newer builds were **NOT** caused by fio-program-board download paths
- SE050 failures were **NOT** caused by local KAS mfgtools configuration changes
- **Root cause**: Changes to OP-TEE recipes that affect Foundries.io cloud builds
- **Critical**: `CFG_CORE_SE05X_SCP03_EARLY=y` requires proper OP-TEE signing configuration
- **Debugging approach**: Check git history of `recipes-security/optee/` for cloud build changes

### Foundries.io Cloud Build System

**🏭 How Cloud Builds Work:**
- Triggered by pushes to Foundries.io-hosted repositories (meta-subscriber-overrides, lmp-manifest)
- **NOT triggered** by pushes to this meta-dynamicdevices repository
- Uses recipes and configurations from multiple layers including this one
- Generates artifacts: `mfgtools-files`, `imx-boot`, `u-boot.itb`, `lmp-factory-image.wic.gz`
- Downloaded via `fioctl targets artifacts` by fio-program-board scripts

**🔧 Troubleshooting Cloud Build Issues:**
1. **Check recipe changes**: `git log --oneline --follow recipes-security/optee/`
2. **Verify machine features**: Check `MACHINE_FEATURES` in machine configs
3. **OP-TEE configuration**: Look for `CFG_CORE_SE05X_*` settings in OP-TEE recipes
4. **SE050 vs ELE**: imx8mm uses external SE050, imx93 uses internal EdgeLock Secure Enclave
5. **Build artifacts**: Use `fioctl targets show <target>` to inspect cloud build details

**🔧 SE050/OP-TEE mfgtools Fix:**
- **Problem**: SE050/ELE initialization failures in mfgtools builds (OP-TEE 4.4.0+)
- **Root Cause**: Secure enclaves not needed for manufacturing/UUU programming, only production runtime
- **Solution**: Conditionally disable SE050/ELE for `lmp-mfgtool` distro builds
- **Implementation**: `'' if d.getVar('DISTRO') == 'lmp-mfgtool' else 'CFG_CORE_SE05X=y...'`
- **Machines**: Applied to imx8mm-jaguar-sentai, imx8mm-jaguar-inst, imx93-jaguar-eink
- **Result**: mfgtools work without secure enclave issues, production builds keep security enabled

**⚠️ Common Pitfalls:**
- Assuming local KAS changes affect cloud builds (they don't)
- Modifying fio-program-board download paths when issue is in cloud build configuration
- Not understanding SE050 early initialization requirements for SCP03 encrypted communication
- Enabling SE050 in mfgtools when it's only needed for production runtime

### Build Commands

#### Local Development Build
```bash
export MACHINE=imx93-jaguar-eink  # or imx8mm-jaguar-sentai
kas build kas/lmp-dynamicdevices.yml
./scripts/program.sh  # Board programming
```

### Production Programming (Foundries.io Builds)

**Linux/macOS (Fully Functional):**
```bash
# One-time setup
./scripts/fio-program-board.sh --configure
echo 'factory: dynamic-devices' >> ~/.config/fioctl.yaml  # Set fioctl default

# 🚀 ULTRA-SIMPLE: Latest target + auto-program
./scripts/fio-program-board.sh --machine imx93-jaguar-eink --program

# 📦 Download latest only
./scripts/fio-program-board.sh --machine imx93-jaguar-eink

# 🎯 Explicit control
./scripts/fio-program-board.sh --factory dynamic-devices --machine imx93-jaguar-eink 1975

# 💾 Force fresh download
./scripts/fio-program-board.sh --machine imx93-jaguar-eink --force

# 🔄 Continuous programming for multiple boards
./scripts/fio-program-board.sh --machine imx93-jaguar-eink --continuous
```

**Windows (Work in Progress):**
```batch
# Basic functionality available, specify target number explicitly
scripts\fio-program-board.bat /factory dynamic-devices /machine imx93-jaguar-eink 1975 /program

# Auto-latest target detection needs completion
# scripts\fio-program-board.bat /machine imx93-jaguar-eink /program  # Not working yet
```

### Key Features
- **🎯 Auto-Latest**: Uses latest successful build automatically
- **⚡ One-Command**: Download + program with `--program` (no wait)
- **🔄 Continuous**: Program multiple boards in sequence with `--continuous`
- **💾 Smart Cache**: Skips re-downloading existing files
- **⏱️ Timing**: Real-time performance feedback per board
- **🔧 i.MX93 Fix**: Correct bootloader prevents "image too large"

## Documentation
- **AI Context**: `context/` (AI assistant context files)
- **Technical Docs**: `docs/` (layer architecture, compliance, templates)
- **User Guides**: `wiki/` (testing, development, setup guides)
- **Board Programming**: `wiki/Board-Programming-with-Foundries-Builds.md`
- **Contributing**: `CONTRIBUTING.md`

## Context Management Guidelines
- **Keep Updated**: Context files must reflect current project state
- **Token Optimization**: Minimize content while retaining essential information
- **Relevance Focus**: Include only information needed for development/debugging
- **Regular Review**: Remove outdated details, consolidate duplicate information