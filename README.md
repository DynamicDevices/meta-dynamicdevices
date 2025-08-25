# meta-dynamicdevices

**Professional Yocto BSP Layer for Dynamic Devices Edge Computing Platforms**

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![License: Commercial](https://img.shields.io/badge/License-Commercial-green.svg)](mailto:licensing@dynamicdevices.co.uk)
[![Yocto Compatible](https://img.shields.io/badge/Yocto-scarthgap%20|%20kirkstone-orange.svg)](https://www.yoctoproject.org/)

This BSP layer provides comprehensive board support for Dynamic Devices Edge Computing platforms, featuring advanced audio processing, environmental sensing, wireless connectivity, and power management capabilities.

## 📋 Quick Start

### Supported Boards

| Board | Machine | Platform | Description |
|-------|---------|----------|-------------|
| **[Edge AI](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Edge-AI-Board)** | `imx8mm-jaguar-sentai` | i.MX8MM | AI audio STT/TTS platform |
| **[Edge EInk](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Edge-EInk-Board)** | `imx93-jaguar-eink` | i.MX93 | Low-power e-ink controller |
| **[Edge EV](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Edge-EV-Board)** | `imx8mm-jaguar-phasora` | i.MX8MM | Energy management |
| **[Edge GW](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Edge-GW-Board)** | `imx8mm-jaguar-inst` | i.MX8MM | Communications gateway |

### Build & Flash

```bash
# Set target machine
export KAS_MACHINE=imx8mm-jaguar-sentai

# Build image
./scripts/kas-build-base.sh

# Program board
./scripts/program.sh
```

## 📚 Documentation

### Hardware Documentation
- **[Edge AI Board](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Edge-AI-Board)** - TAS2563 audio, sensors, pin mappings
- **[Edge EInk Board](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Edge-EInk-Board)** - Power management, WoWLAN, hardware specs
- **[Edge EV Board](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Edge-EV-Board)** - Energy metering and control
- **[Edge GW Board](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Edge-GW-Board)** - Communications gateway

### Development Guides
- **[Flashing Boards](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Flashing-an-Edge-board-with-a-Yocto-Embedded-Linux-image)** - Programming and recovery procedures
- **[WiFi Onboarding](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Onboarding-to-WiFi-with-BLE-Serial-using-Improv)** - BLE-based WiFi configuration
- **[Security](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Securing-Edge-Boards)** - Security features and configuration
- **[Troubleshooting](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Troubleshooting:-(Re‐)registering-with-Foundries.io)** - Common issues and solutions

### Developer Resources
- **[docs/YOCTO_BSP_BEST_PRACTICES.md](docs/YOCTO_BSP_BEST_PRACTICES.md)** - Professional development guidelines
- **[docs/RECIPE_TEMPLATE.bb](docs/RECIPE_TEMPLATE.bb)** - Template for new recipes
- **[CHANGELOG.md](CHANGELOG.md)** - Version history and changes
- **[MAINTAINERS](MAINTAINERS)** - Maintainer contact information

## ⚡ Prerequisites

- **KAS** - Use `kas-container` for reproducible builds
- **Docker** - Container runtime for isolated build environment
- **USB-C Power** - Required for proper board operation
- **UUU Tool** - For board programming and recovery

## 🔒 Licensing

This BSP layer is available under dual licensing:

- **[GPL v3](LICENSE)** - For open source projects
- **[Commercial](mailto:licensing@dynamicdevices.co.uk)** - For proprietary applications

## 🛠 Development

### Professional Standards
- Semantic versioning with detailed changelog
- Comprehensive documentation in wiki
- Professional recipe templates and best practices
- Clear maintainer ownership and contact information

### Contributing
1. Review [best practices guide](docs/YOCTO_BSP_BEST_PRACTICES.md)
2. Use [recipe template](docs/RECIPE_TEMPLATE.bb) for new components
3. Update documentation and changelog
4. Follow professional development standards

## 📞 Support

- **Technical Issues**: [GitHub Issues](https://github.com/DynamicDevices/meta-dynamicdevices/issues)
- **Commercial Licensing**: licensing@dynamicdevices.co.uk
- **General Inquiries**: info@dynamicdevices.co.uk
- **Wiki**: [Comprehensive Documentation](https://github.com/DynamicDevices/meta-dynamicdevices/wiki)

---

*For detailed hardware specifications, software features, and development guides, please refer to the [comprehensive wiki documentation](https://github.com/DynamicDevices/meta-dynamicdevices/wiki).*