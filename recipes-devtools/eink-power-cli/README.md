# E-Ink Power CLI Integration

## Overview
Rust-based CLI utility for controlling the MCXC143VFM power management microcontroller on imx93-jaguar-eink boards.

## Installation
- **Auto-Install**: Included in all imx93-jaguar-eink builds
- **Binaries**: `/usr/bin/eink-power-cli`, `/usr/bin/eink-pmu` (symlink)
- **Config**: `/etc/eink-power-cli.toml` (optional)

## Usage
```bash
# Power status and battery monitoring
eink-pmu status
eink-pmu battery

# Full CLI interface
eink-power-cli --help
```

## Technical Details
- **Communication**: LPUART7 (`/dev/ttyLP2`) @ 115200 baud
- **Protocol**: Serial commands to MCXC143VFM microcontroller
- **Dependencies**: `libgcc`, `coreutils`
- **Architecture**: ARM64/AArch64 cross-compiled

## Integration
- **Recipe**: `eink-power-cli_git.bb`
- **Source**: `github.com/DynamicDevices/eink-power-cli`
- **Machine Feature**: `el133uf1` (enabled in imx93-jaguar-eink.conf)
- **Auto-Include**: `MACHINE_EXTRA_RDEPENDS` in machine config

## Build
```bash
# Build standalone
bitbake eink-power-cli

# Included in factory image
export KAS_MACHINE=imx93-jaguar-eink
kas build kas/lmp-dynamicdevices.yml
```

## Development
- **Language**: Rust with `cargo_bin` class
- **Network**: Build requires network access for cargo dependencies
- **QA**: `already-stripped` and debug prefix mapping handled
