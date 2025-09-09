# Layer Organization Guide

## Overview

This document describes the organized layer structure for the meta-dynamicdevices project, designed to keep the local filesystem clean and separate different types of layers logically.

## Directory Structure

```
meta-dynamicdevices/
├── meta-dynamicdevices-bsp/          # BSP submodule (hardware-specific)
├── meta-dynamicdevices-distro/       # Distro submodule (distribution configs)
├── build/
│   └── layers/                       # External downloaded layers
│       ├── bitbake/                  # BitBake tool
│       ├── openembedded-core/        # OE core
│       ├── lmp-tools/                # LMP tools
│       ├── meta-arm/                 # ARM BSP layers
│       ├── meta-freescale/           # NXP/Freescale layers
│       ├── meta-openembedded/        # OpenEmbedded layers
│       ├── meta-rust-bin/            # Rust toolchain
│       └── ...                       # Other external layers
├── recipes-*/                        # Application recipes (main layer)
├── kas/                              # KAS build configurations
└── ...                               # Other project files
```

## Layer Separation and Content Organization

### 🏗️ meta-dynamicdevices-bsp (BSP Layer)
- **Purpose**: Hardware-specific Board Support Package
- **Priority**: 12 (highest - hardware foundation)
- **Contains**: 
  - **Machine configurations** (`conf/machine/`)
  - **Device trees and kernel patches** (`recipes-kernel/`, `recipes-bsp/device-tree/`)
  - **Board-specific audio** (ALSA, PulseAudio hardware configurations)
  - **Hardware testing** (CE testing, ELE testing, board validation)
  - **Board-specific power management** (WiFi power optimization)
  - **Hardware-specific network policies** (iptables rules per board)
  - **Board-specific device registration** (machine-specific scripts)
  - **Container configurations** with hardware dependencies

### 🎛️ meta-dynamicdevices-distro (Distribution Layer)
- **Purpose**: Distribution policies and system configuration
- **Priority**: 10 (lowest - policy overlay)
- **Contains**:
  - **Distribution definitions** (`lmp-dynamicdevices`, `lmp-dynamicdevices-base`, etc.)
  - **Boot signing policies** (systemd-boot with lmp-signing-override)
  - **Security policies** (OP-TEE, SE050/ELE configuration per distro)
  - **OTA update policies** (aktualizr configuration)
  - **Development feature policies** (GDB TUI support)
  - **Image recipes and feature includes** (`recipes-samples/images/`)
  - **License policies** (commercial license acceptance)

### 📱 meta-dynamicdevices (Main Application Layer)
- **Purpose**: Generic applications and middleware
- **Priority**: 11 (middle - applications over hardware, under policies)
- **Contains**: 
  - **Connectivity applications** (UWB MQTT publisher, wireless tools, modem manager)
  - **Development tools** (Python packages, Meson build system)
  - **Support services** (boot profiling, network management, WiFi hotspot)
  - **Multimedia applications** (DTMF decoder)
  - **Generic libraries** (libgbinder, libglibutil)
  - **Container support** (Waydroid - generic Android support)
  - **Build infrastructure** (KAS configurations, scripts, documentation)

### Layer Separation Principles

**Each layer has a clear, distinct purpose:**
- **BSP Layer** = "What hardware do I have?" (machines, drivers, board-specific configs)
- **Distro Layer** = "What policies do I want?" (security, boot, updates, features)
- **Main Layer** = "What applications do I need?" (generic software, libraries, tools)

This follows Yocto Project best practices:
- ✅ **Clean separation of concerns**
- ✅ **No cross-layer dependencies for wrong reasons**
- ✅ **Proper layer priorities and organization**
- ✅ **Yocto Project Compatible structure**

## Layer Types

### 1. **Submodules** (Root Directory)
- **Location**: Project root directory
- **Purpose**: Project-owned layers maintained as git submodules
- **Examples**:
  - `meta-dynamicdevices-bsp` - Hardware BSP components
  - `meta-dynamicdevices-distro` - Distribution configurations
- **KAS Configuration**: Use relative paths (e.g., `path: meta-dynamicdevices-bsp`)

### 2. **External Layers** (build/layers/)
- **Location**: `build/layers/` directory
- **Purpose**: Third-party layers downloaded by KAS during build
- **Examples**:
  - `meta-openembedded` - OpenEmbedded community layers
  - `meta-freescale` - NXP/Freescale BSP layers
  - `meta-rust-bin` - Rust toolchain layers
- **KAS Configuration**: Use `build/layers/` prefix (e.g., `path: build/layers/meta-openembedded`)

### 3. **Application Layer** (Root Directory)
- **Location**: Project root directory
- **Purpose**: Main application and middleware recipes
- **Examples**: `recipes-*` directories in the root

## Benefits

### 🧹 **Clean Filesystem**
- All downloaded content organized under `build/layers/`
- Root directory contains only project-owned content
- Easy to distinguish between submodules and external dependencies

### 📁 **Logical Organization**
- **Submodules**: Project-controlled, versioned components
- **External layers**: Third-party dependencies, downloaded as needed
- **Application code**: Main project recipes and configurations

### 🚀 **Build Efficiency**
- Downloaded layers cached in organized structure
- Easy cleanup: `rm -rf build/layers/` removes all external content
- Submodules preserved during cleanup operations

### 🔧 **Development Workflow**
- Clear separation of concerns
- Submodules can be developed independently
- External layers managed automatically by KAS

## KAS Configuration Examples

### Submodule Reference
```yaml
repos:
  meta-dynamicdevices-bsp:
    path: meta-dynamicdevices-bsp  # Relative to project root
```

### External Layer Reference
```yaml
repos:
  meta-openembedded:
    url: https://github.com/lmp-mirrors/meta-openembedded
    path: build/layers/meta-openembedded  # Organized under build/layers/
    commit: e92d0173a80ea7592c866618ef5293203c50544c
```

## Migration Notes

- **Legacy locations**: Old layer locations (`layers/`, `bitbake/`, etc.) are preserved in `.gitignore` for compatibility
- **Automatic cleanup**: Empty legacy directories and duplicate files are removed after migration
- **KAS file organization**: All kas configuration files moved to `kas/` directory
- **Removed duplicates**: Outdated `layers.hidden/` directory and misplaced kas files cleaned up
- **Backward compatibility**: Old builds will continue to work during transition period

## Maintenance

### Clean External Layers
```bash
# Remove all downloaded external layers (preserves submodules)
rm -rf build/layers/

# Next kas build will re-download as needed
kas build kas/lmp-dynamicdevices-base.yml
```

### Update Submodules
```bash
# Update all submodules to latest commits
git submodule update --remote

# Update specific submodule
git submodule update --remote meta-dynamicdevices-bsp
```

---

**Dynamic Devices Ltd** - Professional embedded Linux solutions for edge computing platforms.
