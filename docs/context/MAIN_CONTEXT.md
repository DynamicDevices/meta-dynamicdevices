# meta-dynamicdevices Main Context

## Overview
Yocto/OpenEmbedded layers for Dynamic Devices Edge boards on Linux microPlatform (LmP).

## Boards
- **Edge AI** (imx8mm-jaguar-sentai) - Audio processing, TAS2563 driver
- **Edge EInk** (imx93-jaguar-eink) - E-ink display, optimized kernel, flexible WiFi
- **Edge EV/GW** - Future boards

## Recent Updates ✅
- **Foundries.io Integration**: Complete board programming from CI builds (`fio-program-board.sh`)
- **MFGTools Automation**: Auto-download and extract complete programming packages
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

## Build Commands

### Local Development Build
```bash
export MACHINE=imx93-jaguar-eink  # or imx8mm-jaguar-sentai
kas build kas/lmp-dynamicdevices.yml
./scripts/program.sh  # Board programming
```

### Production Programming (Foundries.io Builds)
```bash
# One-time setup
./scripts/fio-program-board.sh --configure

# Download and program latest build
./scripts/fio-program-board.sh --factory dynamic-devices --machine imx93-jaguar-eink

# Or download and program automatically
./scripts/fio-program-board.sh --factory dynamic-devices --machine imx93-jaguar-eink --program
```

## Documentation
- **Context**: `docs/projects/*-context.md` (project details)
- **Wiki**: `wiki/` (user documentation)
- **Board Programming**: `wiki/Board-Programming-with-Foundries-Builds.md`
- **Contributing**: `CONTRIBUTING.md`

## Context Management Guidelines
- **Keep Updated**: Context files must reflect current project state
- **Token Optimization**: Minimize content while retaining essential information
- **Relevance Focus**: Include only information needed for development/debugging
- **Regular Review**: Remove outdated details, consolidate duplicate information