# meta-dynamicdevices Main Context

## Overview
Yocto/OpenEmbedded layers for Dynamic Devices Edge boards on Linux microPlatform (LmP).

## Boards
- **Edge AI** (imx8mm-jaguar-sentai) - Audio processing, TAS2563 driver
- **Edge EInk** (imx93-jaguar-eink) - E-ink display, optimized kernel, flexible WiFi
- **Edge EV/GW** - Future boards

## Recent Updates ✅
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
```bash
export MACHINE=imx93-jaguar-eink  # or imx8mm-jaguar-sentai
kas build kas/lmp-dynamicdevices.yml
./scripts/program.sh  # Board programming
```

## Documentation
- **Context**: `docs/projects/*-context.md` (project details)
- **Wiki**: `wiki/` (user documentation)
- **Contributing**: `CONTRIBUTING.md`