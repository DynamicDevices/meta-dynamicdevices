# meta-dynamicdevices Main Context

## Repository Overview

This repository contains application and middleware layers for Dynamic Devices Edge board family, built on the Linux microPlatform (LmP) using Yocto/OpenEmbedded. Hardware-specific BSP (Board Support Package) components are maintained in the separate `meta-dynamicdevices-bsp` submodule.

## Supported Boards

### Edge Board Family
- **Edge AI Board** (imx8mm-jaguar-sentai) - AI audio processing platform with TAS2563 dual codec
- **Edge EInk Board** (imx93-jaguar-eink) - Low-power e-ink display controller with magic packet wake
- **Edge EV Board** - Clean energy management (future)
- **Edge GW Board** - Communications gateway (future)  

## Repository Structure

```
meta-dynamicdevices/                    # Application & Middleware Layer
├── docs/                               # Documentation and context files
│   ├── context/                       # Main and project-specific context
│   ├── projects/                      # Project-specific documentation
│   ├── RECIPE_TEMPLATE.bb             # Template for creating new recipes
│   └── YOCTO_BSP_BEST_PRACTICES.md    # Professional development guidelines
├── scripts/                           # Utility scripts and tools
├── wiki/                              # Wiki submodule (GitHub wiki)
├── conf/                              # Application layer configuration
├── recipes-connectivity/              # Network and wireless applications
├── recipes-multimedia/               # Audio and media processing
├── recipes-support/                  # Application support services
├── recipes-containers/               # Container and virtualization
├── recipes-*/                        # Other application-specific recipes
├── kas/                              # KAS build configuration files
├── program/                          # Board programming utilities
├── meta-dynamicdevices-bsp/          # BSP Submodule (Hardware Support)
│   ├── conf/machine/                 # Machine configurations
│   ├── recipes-bsp/                  # Board support recipes
│   ├── recipes-kernel/               # Hardware-specific kernel configs
│   ├── LICENSE                       # Dual GPL-3.0/Commercial licensing
│   └── README.md                     # BSP-specific documentation
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

### Application Layer (meta-dynamicdevices)
This main repository provides:
- **Application recipes** - User-space applications and services
- **Middleware components** - Audio processing, networking, containers
- **System integration** - Service configuration and orchestration
- **Build configuration** - KAS files and layer dependencies

### BSP Layer (meta-dynamicdevices-bsp)
The BSP submodule provides hardware-specific support:
- **Machine configurations** - Hardware definitions for all board variants
- **Kernel configurations** - Hardware-specific kernel features and drivers
- **Device tree sources** - Hardware description and pin configurations
- **Bootloader support** - U-Boot configurations and patches
- **Firmware integration** - Hardware-specific firmware and drivers

### Layer Dependencies
```
meta-dynamicdevices (Application Layer)
    ↓ depends on
meta-dynamicdevices-bsp (BSP Layer)
    ↓ depends on  
meta-lmp-base (Linux microPlatform)
```

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