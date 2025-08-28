# meta-dynamicdevices Main Context

## Repository Overview

This repository contains application and middleware layers for Dynamic Devices Edge board family, built on the Linux microPlatform (LmP) using Yocto/OpenEmbedded. Hardware-specific BSP (Board Support Package) components are maintained in the separate `meta-dynamicdevices-bsp` submodule.

## Supported Boards

### Edge Board Family
- **Edge AI Board** (imx8mm-jaguar-sentai) - AI audio processing platform with TAS2563 Android driver + firmware support
- **Edge EInk Board** (imx93-jaguar-eink) - Low-power e-ink display controller with optimized kernel + flexible WiFi firmware
- **Edge EV Board** - Clean energy management (future)
- **Edge GW Board** - Communications gateway (future)

## Recent Major Updates (December 2024)

### ✅ **TAS2563 Android Driver Implementation** 
- **Board**: imx8mm-jaguar-sentai
- **Change**: Switched from upstream TAS2562 to Android TAS2563 driver
- **Benefit**: Enables firmware binary downloads for DSP noise reduction
- **Files**: Machine config, kernel configs, driver recipes

### ✅ **NXP IW612 WiFi Firmware Optimization**
- **Board**: imx93-jaguar-eink  
- **Change**: Flexible firmware selection (secure .se vs standard .bin)
- **Benefit**: Supports both production and development builds
- **Configuration**: `NXP_WIFI_SECURE_FIRMWARE` variable

### ✅ **Kernel Driver Optimization**
- **Board**: imx93-jaguar-eink
- **Change**: Reduced USB serial drivers from 50+ to 5 essential
- **Benefit**: Faster boot, smaller kernel, cleaner dmesg output
- **Impact**: Significant boot time improvement  

## Repository Structure

```
meta-dynamicdevices/                    # Main Application & Middleware Layer
├── docs/                               # Documentation and context files
│   ├── context/                       # Main and project-specific context
│   ├── projects/                      # Project-specific documentation
│   ├── RECIPE_TEMPLATE.bb             # Template for creating new recipes
│   ├── YOCTO_BSP_BEST_PRACTICES.md    # Professional development guidelines
│   └── LAYER_ORGANIZATION.md          # Layer organization guide
├── scripts/                           # Utility scripts and tools
├── wiki/                              # Wiki submodule (GitHub wiki)
├── conf/                              # Application layer configuration
├── recipes-config/                    # Application configuration
├── recipes-connectivity/              # Network and wireless applications
├── recipes-containers/               # Container and virtualization
├── recipes-core/                     # Core system components
├── recipes-devtools/                 # Development tools
├── recipes-extended/                 # Extended utilities
├── recipes-multimedia/               # Generic audio and media processing
├── recipes-security/                 # Security policies
├── recipes-sota/                     # OTA management
├── recipes-support/                  # Application support services
├── kas/                              # KAS build configuration files
├── program/                          # Board programming utilities
├── lmp-docker/                       # Docker container customization
├── meta-lmp-base/                    # Local project patches (OpenSSH CVE fixes)
├── build/                            # Build outputs and external layers
│   └── layers/                       # External downloaded layers (organized)
│       ├── bitbake/                  # BitBake tool
│       ├── openembedded-core/        # OE core
│       ├── meta-lmp/                 # Foundries.io LMP layers
│       ├── meta-freescale/           # NXP/Freescale layers
│       ├── meta-openembedded/        # OpenEmbedded community layers
│       └── [20+ other external layers]
├── meta-dynamicdevices-bsp/          # BSP Submodule (Hardware Support)
│   ├── conf/machine/                 # Machine configurations (5 boards)
│   ├── recipes-bsp/                  # Board support recipes
│   ├── recipes-kernel/               # Hardware-specific kernel configs
│   ├── recipes-multimedia/           # Hardware-specific multimedia (GStreamer i.MX)
│   ├── LICENSE                       # Dual GPL-3.0/Commercial licensing
│   └── README.md                     # BSP-specific documentation
├── meta-dynamicdevices-distro/       # Distro Submodule (Distribution Policies)
│   ├── conf/distro/                  # Distribution configurations (4 variants)
│   ├── recipes-samples/images/       # Image recipes and feature includes
│   ├── LICENSE                       # Dual GPL-3.0/Commercial licensing
│   └── README.md                     # Distro-specific documentation
├── CHANGELOG.md                      # Project changelog
├── VERSION                           # Current version number
├── MAINTAINERS                       # Maintainer contact information
├── LICENSE                           # Dual GPL-3.0/Commercial licensing
└── [build artifacts are git-ignored]
```

## Key Technologies

### Platforms
- **NXP i.MX8MM** - Cortex-A53 quad-core (Edge AI)
- **NXP i.MX93** - Cortex-A55 dual-core + M33 (Edge EInk)

### Wireless Connectivity
- **NXP IW612** - WiFi 6 + Bluetooth 5.4 + 802.15.4 tri-radio
- **Wake-on-LAN** - Magic packet wake capabilities
- **Bluetooth LE** - Device pairing and control

### Power Management (Edge EInk)
- **Advanced suspend/resume** - Sub-second wake times
- **Selective wake sources** - Magic packet, GPIO, RTC
- **Power optimization** - Dynamic scaling and sleep states

## Layer Architecture

### 🏗️ **Multi-Layer Architecture**
The project follows Yocto best practices with a clean three-layer separation:

### Application Layer (meta-dynamicdevices)
**Main repository** - Focus: Applications and middleware
- **Application recipes** - User-space applications and services  
- **Middleware components** - Generic audio, networking, containers
- **System integration** - Service configuration and orchestration
- **Development tools** - Python packages, build tools, debugging
- **Build configuration** - KAS files and layer dependencies
- **External layer management** - Organized in `build/layers/` structure

### BSP Layer (meta-dynamicdevices-bsp)
**Hardware submodule** - Focus: Hardware-specific support
- **Machine configurations** - 5 board definitions (imx8mm-jaguar-*, imx93-jaguar-eink)
- **Device tree customizations** - Hardware-specific DTS files and overlays
- **Bootloader configurations** - U-Boot patches and configurations  
- **Hardware drivers** - Kernel modules and firmware
- **Board support recipes** - Hardware initialization and testing scripts
- **Hardware multimedia** - i.MX-specific GStreamer plugins and audio processing

### Distribution Layer (meta-dynamicdevices-distro)  
**Distribution submodule** - Focus: Distribution policies and images
- **Distribution configurations** - 4 distro variants (base, flutter, waydroid, etc.)
- **Image recipes** - Factory images with feature-based composition
- **Feature includes** - Modular feature sets (ALSA, auto-register, improv, etc.)
- **Distribution policies** - Security settings, package selections, licensing

### 🔗 **Layer Dependencies**
```
meta-dynamicdevices (Priority: 11)
├── depends on: meta-dynamicdevices-bsp (Priority: 12)  
├── depends on: meta-dynamicdevices-distro (Priority: 10)
└── depends on: meta-lmp-base (external)

External layers managed in build/layers/:
├── meta-lmp/ (Foundries.io LMP)
├── meta-freescale/ (NXP/Freescale BSP)  
├── meta-openembedded/ (Community layers)
└── 20+ other external dependencies
```

This separation enables:
- **Independent development** - Each layer can be developed and versioned separately
- **Reusable components** - BSP can be used across projects, distros can be mixed
- **Clean abstraction** - Applications don't need hardware or distro-specific knowledge
- **Professional maintenance** - Each layer follows Yocto best practices
- **Organized dependencies** - External vs project-owned content clearly separated

## Development Workflow

### Build Environment Setup
```bash
# Source LmP environment
source lmp-tools/setup-environment

# Set target machine
export MACHINE=imx93-jaguar-eink  # or imx8mm-jaguar-sentai

# Build image
kas build kas/lmp-dynamicdevices.yml
```

### Common Tasks

#### Board Programming
```bash
# Create programming archive
./scripts/create-archive.sh

# Program board (using UUU tool)
./scripts/program.sh
```

## Project Context Files

Individual projects have detailed context documentation:

- **[Edge EInk Context](../projects/edge-eink-context.md)** - Power management and suspend/resume implementation
- **[WiFi Testing Guide](../projects/wifi-testing-guide.md)** - Local WiFi configuration for development
- **[Power Management Summary](../projects/power-management-summary.md)** - Detailed power implementation guide

## Board Documentation (Wiki)

Comprehensive user documentation is maintained in the wiki:

- **[Edge AI Board](../../wiki/Edge-AI-Board.md)** - Audio processing, TAS2563, sensors
- **[Edge EInk Board](../../wiki/Edge-EInk-Board.md)** - Power management, hardware specs, connectivity
- **[Edge EInk Power Management](../../wiki/Edge-EInk-Power-Management.md)** - Detailed implementation guide

## Contributing

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for development guidelines.

## Documentation

- **Wiki** - Comprehensive board documentation in `wiki/` submodule
- **Context files** - Project-specific details in `docs/context/`
- **README** - Getting started information