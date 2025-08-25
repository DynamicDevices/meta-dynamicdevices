# meta-dynamicdevices Main Context

## Repository Overview

This repository contains BSP (Board Support Package) layers for Dynamic Devices Edge board family, built on the Linux microPlatform (LmP) using Yocto/OpenEmbedded.

## Supported Boards

### Edge Board Family
- **Edge AI Board** (imx8mm-jaguar-sentai) - AI audio processing platform with TAS2563 dual codec
- **Edge EInk Board** (imx93-jaguar-eink) - Low-power e-ink display controller with magic packet wake
- **Edge EV Board** - Clean energy management (future)
- **Edge GW Board** - Communications gateway (future)  

## Repository Structure

```
meta-dynamicdevices/
├── docs/                    # Documentation and context files
│   ├── context/            # Main and project-specific context
│   └── projects/           # Project-specific documentation
├── scripts/                # Utility scripts and tools
├── wiki/                   # Wiki submodule (GitHub wiki)
├── conf/                   # Layer and machine configurations
├── recipes-*/              # Yocto recipes organized by category
├── kas/                    # KAS build configuration files
├── program/                # Board programming utilities
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