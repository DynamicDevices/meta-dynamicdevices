# meta-dynamicdevices

**Professional Yocto Application Layer for Dynamic Devices Edge Computing Platforms**

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![License: Commercial](https://img.shields.io/badge/License-Commercial-green.svg)](mailto:licensing@dynamicdevices.co.uk)
[![Yocto Compatible](https://img.shields.io/badge/Yocto-scarthgap%20|%20kirkstone-orange.svg)](https://www.yoctoproject.org/)
[![Foundries.io LMP](https://img.shields.io/badge/Foundries.io-v95%20(Scarthgap)-purple.svg)](https://foundries.io/products/releases/95/)

[![KAS Build CI](https://github.com/DynamicDevices/meta-dynamicdevices/actions/workflows/kas-build-ci.yml/badge.svg)](https://github.com/DynamicDevices/meta-dynamicdevices/actions/workflows/kas-build-ci.yml)
[![YP Compliance Ready](https://img.shields.io/badge/YP%20Compliance-Ready%20for%20Certification-blue)](https://docs.yoctoproject.org/test-manual/yocto-project-compatible.html)

---

## 🚀 **Quick Start for Engineers**

**⏱️ Get productive in 30 minutes** | **📋 Complete documentation in [Wiki](https://github.com/DynamicDevices/meta-dynamicdevices/wiki)**

### **New to Dynamic Devices boards?**
👉 **[Start Here: Quick-Start Guide](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Quick-Start)** - Board setup to working system in 30 minutes

### **Ready to develop?**
👉 **[Development Workflows](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Development-Workflows)** - Build, flash, test, debug

### **Need hardware specs?**
👉 **[Hardware Reference](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Hardware-Reference)** - Pinouts, interfaces, specifications

---

## 🎯 **Supported Boards**

| Board | SoC | Key Features | Quick Setup |
|-------|-----|--------------|-------------|
| **Edge AI** | i.MX8MM | Audio processing, sensors, radar | [Hardware Guide](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Hardware-Reference/Edge-AI-Pinout-and-Interfaces) |
| **Edge EInk** | i.MX93 | E-ink display, low power, security | [Hardware Guide](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Hardware-Reference/Edge-EInk-Pinout-and-Interfaces) |
| **Edge EV** | i.MX8MM | Clean energy management | [Board Details](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Edge-EV-Board) |
| **Edge GW** | i.MX8MM | Communications gateway | *Documentation coming soon* |

---

## ⚡ **5-Minute Quick Start**

### **Option 1: Use Pre-Built Images (Fastest)**
```bash
# Download and program in one command
./scripts/fio-program-board.sh --machine imx8mm-jaguar-sentai --program

# For E-Ink board
./scripts/fio-program-board.sh --machine imx93-jaguar-eink --program
```

### **Option 2: Build from Source**
```bash
# Clone with submodules
git clone --recursive https://github.com/DynamicDevices/meta-dynamicdevices.git
cd meta-dynamicdevices

# Build and program (30-90 minutes first time)
KAS_MACHINE=imx8mm-jaguar-sentai ./scripts/kas-build-and-program.sh
```

**📋 Detailed instructions:** [Building and Flashing Guide](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Development-Workflows/Building-and-Flashing)

---

## 🛠️ **Key Features**

- **🔐 Enterprise Security**: Secure boot, OTA updates, device management via Foundries.io
- **📱 Container-Ready**: Docker pre-installed with hardware acceleration
- **🌐 Wireless Connectivity**: WiFi 6, Bluetooth 5.4, 802.15.4 (Zigbee/Thread/Matter)
- **🎵 Audio Processing**: TAS2563 codec with PDM microphones (Edge AI)
- **⚡ Power Management**: Advanced suspend/resume, wake-on-LAN (Edge EInk)
- **🔧 Development Tools**: Complete toolchain, debugging, profiling

**📋 Feature implementation guides:** [Feature Guides](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Feature-Guides)

---

## 📚 **Documentation**

### **For Engineers (Start Here)**
- **[🚀 Quick-Start](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Quick-Start)** - Get productive in 30 minutes
- **[💻 Development Workflows](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Development-Workflows)** - Daily engineering tasks
- **[🔧 Hardware Reference](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Hardware-Reference)** - Technical specifications
- **[🔌 Feature Guides](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Feature-Guides)** - Audio, wireless, security implementation

### **For Advanced Users**
- **[📚 Advanced Topics](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Advanced-Topics)** - CI/CD, custom firmware, complex customization
- **[📖 Technical Documentation](docs/)** - Layer architecture, compliance, best practices

---

## 🆘 **Support**

### **Self-Service (Fastest)**
- **[🔍 Troubleshooting Guide](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Development-Workflows/Debugging-and-Troubleshooting)** - Common issues and solutions
- **[📋 GitHub Issues](https://github.com/DynamicDevices/meta-dynamicdevices/issues)** - Bug reports and feature requests
- **[📖 Complete Wiki](https://github.com/DynamicDevices/meta-dynamicdevices/wiki)** - Comprehensive documentation

### **Direct Support**
- **Email:** info@dynamicdevices.co.uk
- **Security Issues:** security@dynamicdevices.co.uk
- **Commercial Licensing:** licensing@dynamicdevices.co.uk

---

## 📄 **License & Compliance**

- **Open Source:** GPL-3.0 for non-commercial use
- **Commercial:** Available for commercial deployments
- **Yocto Compatible:** Ready for official Yocto Project certification
- **Security:** CVE scanning and SBOM generation in CI/CD

**📋 Details:** [License Information](LICENSE) | [Security Policy](SECURITY.md) | [Contributing Guidelines](CONTRIBUTING.md)

---

## 🏢 **About Dynamic Devices**

**Professional embedded Linux solutions for edge computing platforms**

- **Website:** [dynamicdevices.co.uk](https://dynamicdevices.co.uk)
- **GitHub:** [@DynamicDevices](https://github.com/DynamicDevices)
- **Contact:** info@dynamicdevices.co.uk

---

**💡 Ready to start? Visit the [Wiki](https://github.com/DynamicDevices/meta-dynamicdevices/wiki) for complete documentation!**
