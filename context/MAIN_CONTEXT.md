# meta-dynamicdevices Context

## Overview
Yocto layers for Dynamic Devices Edge boards on Linux microPlatform (LmP).

**Boards**: Edge AI (imx8mm-jaguar-sentai), Edge EInk (imx93-jaguar-eink)
**Key Tech**: i.MX8MM/i.MX93, NXP IW612, TAS2563 echo cancellation

## Recent Updates
- **fio-program-board v2.0**: Auto-latest target, one-command programming (`--program`), continuous mode (`--continuous`)
- **TAS2563 AEC**: Complete echo cancellation with TAS2781 driver, Profile 8 regbin analysis
- **i.MX93**: Fixed bootloader size issues, optimized kernel boot
- **WiFi**: Flexible .se/.bin firmware selection

## Architecture
- **meta-dynamicdevices**: Main recipes, kas/, scripts/
- **meta-dynamicdevices-bsp**: Hardware support (DTS, drivers)
- **meta-dynamicdevices-distro**: Distribution policies

## Build Systems

**⚠️ Two Systems**: 
- **Local KAS**: Development (`./scripts/kas-shell-base.sh`)
- **Foundries Cloud**: Production (triggered by `meta-subscriber-overrides`/`lmp-manifest` pushes)

**Key**: Local changes don't trigger cloud builds. Use `fio-program-board.sh --latest` for production targets.

**SE050/ELE Fix**: Disabled for mfgtools builds (`lmp-mfgtool` distro), enabled for production.

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

## TAS2563 Echo Cancellation

**Driver**: TAS2781 upstream (`git.ti.com/tas2781-linux-drivers`, commit `124282c`) with IRQ/compatibility patches
**Profile**: Profile 8 (`08-pdm-rec-i2s-48kHz-32bit-tx-slot-0-1-mic-slot-3-ref`) for echo reference
**Access**: `arecord -D eref -f S32_LE -r 48000 -c 1` or `hw:Audio,0,1`

### Key Config
- **DTS**: SAI3 bidirectional, 4 TDM slots, 32-bit, `fsl,sai-synchronous-rx`
- **ALSA**: `pcm.eref` (S32_LE), `pcm.eref_16bit` (S16_LE legacy)
- **Init**: `tas2563-init` → Profile 8 (default), music/bypass modes
- **Pipeline**: Speaker `hw:Audio,0,0` → Echo ref `hw:Audio,0,1` → AEC

### Critical Fixes
- **IRQ Bug**: Driver used IRQ as GPIO, fixed with `of_irq_get()` + `request_threaded_irq()`
- **ndev Mismatch**: Modified regbin `ndev=2→1` for single device
- **Format**: Profile 8 = 32-bit, must align ALSA dsnoop format

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