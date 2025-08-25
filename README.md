# meta-dynamicdevices

**Professional Yocto BSP Layer for Dynamic Devices Edge Computing Platforms**

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![License: Commercial](https://img.shields.io/badge/License-Commercial-green.svg)](mailto:licensing@dynamicdevices.co.uk)
[![Yocto Compatible](https://img.shields.io/badge/Yocto-scarthgap%20|%20kirkstone-orange.svg)](https://www.yoctoproject.org/)
[![Foundries.io LMP](https://img.shields.io/badge/Foundries.io-v95%20(Scarthgap)-purple.svg)](https://foundries.io/products/releases/95/)

[![KAS Build CI](https://github.com/DynamicDevices/meta-dynamicdevices/actions/workflows/kas-build-ci.yml/badge.svg)](https://github.com/DynamicDevices/meta-dynamicdevices/actions/workflows/kas-build-ci.yml)
[![GitHub Issues](https://img.shields.io/github/issues/DynamicDevices/meta-dynamicdevices)](https://github.com/DynamicDevices/meta-dynamicdevices/issues)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/DynamicDevices/meta-dynamicdevices)](https://github.com/DynamicDevices/meta-dynamicdevices/pulls)
[![Latest Release](https://img.shields.io/github/v/release/DynamicDevices/meta-dynamicdevices?include_prereleases)](https://github.com/DynamicDevices/meta-dynamicdevices/releases)
[![Code Quality](https://img.shields.io/badge/code%20quality-multi--layer%20✓-brightgreen)](https://github.com/DynamicDevices/meta-dynamicdevices/actions/workflows/kas-build-ci.yml)
[![Security Scanning](https://img.shields.io/badge/security-CVE%20%2B%20SBOM%20✓-blue)](https://github.com/DynamicDevices/meta-dynamicdevices/actions/workflows/kas-build-ci.yml)

This BSP layer provides comprehensive board support for Dynamic Devices Edge Computing platforms, featuring advanced audio processing, environmental sensing, wireless connectivity, and power management capabilities.

## 🔐 Enterprise-Grade Security & Device Management

Dynamic Devices board platforms, in partnership with **Foundries.io**, deliver a comprehensive security-first approach to edge computing with professional-grade device lifecycle management.

### 🛡️ **Secure Boot Foundation**
- **Hardware Root of Trust**: i.MX8MM/i.MX93 High Assurance Boot (HAB) with secure key storage
- **Verified Boot Chain**: U-Boot → Linux kernel → Root filesystem integrity validation
- **Anti-Rollback Protection**: Prevents downgrade attacks through secure version control
- **Encrypted Storage**: LUKS disk encryption for sensitive data protection

### 🌐 **Remote Device Management**
- **Zero-Touch Provisioning**: Automated device registration and configuration
- **Secure Remote Access**: VPN-less device connectivity through Foundries.io gateway
- **Fleet Monitoring**: Real-time device health, performance metrics, and diagnostics
- **Role-Based Access Control**: Fine-grained permissions for development teams

### 📦 **Container-First Architecture**
- **Docker Integration**: Native container runtime with hardware-accelerated features
- **Application Isolation**: Secure sandboxing for customer applications
- **Resource Management**: CPU, memory, and GPU allocation controls
- **Multi-Tenant Support**: Run multiple isolated customer workloads safely

### 🚀 **Over-the-Air (OTA) Updates**
- **Atomic Updates**: All-or-nothing deployment prevents bricked devices
- **Rollback Capability**: Automatic recovery from failed updates
- **Delta Updates**: Bandwidth-efficient incremental deployments
- **Staged Rollouts**: Controlled deployment to device groups with A/B testing
- **Continuous Delivery**: Direct integration with CI/CD pipelines

### 📊 **Production-Ready Benefits**
- **📈 Scalability**: Manage thousands of devices from a single dashboard
- **🔍 Observability**: Comprehensive logging, metrics, and alerting
- **🛠️ DevOps Integration**: GitOps workflow for configuration and application deployment
- **🏢 Enterprise Support**: Professional SLA with Foundries.io partnership
- **🌍 Global Infrastructure**: Edge-optimized content delivery network

### 💼 **Customer Application Deployment**
```bash
# Deploy containerized applications securely
fioctl targets update --apps myapp:v1.2.3 production-fleet

# Monitor deployment across device fleet
fioctl devices list --factory mycompany

# Secure remote debugging (development only)
fioctl devices access mydevice-001
```

**Learn More**: [Foundries.io Platform Overview](https://foundries.io/platform/) | [Security Whitepaper](https://foundries.io/security/) | [Getting Started Guide](https://docs.foundries.io/)

## 📋 Quick Start - Get Running in Minutes

> **🚀 Ready to Go**: All boards come with pre-built production images and comprehensive programming packages for immediate deployment.

### ⚡ **Zero to Running Board in 4 Steps**

#### **Step 1: Download Programming Package** 📦
```bash
# Visit our CI builds and download the latest programming package for your board
# https://github.com/DynamicDevices/meta-dynamicdevices/actions/workflows/kas-build-ci.yml
# Download: programming-package-[your-board-name].zip
```

#### **Step 2: Setup Board for Programming** 🔌
```bash
# 1. Power OFF your board
# 2. Set DIP switches to download/recovery mode (see board manual)
# 3. Connect USB cable between board and your computer
# 4. Power ON your board
```

#### **Step 3: Program Your Board** ⚡
```bash
# Extract the programming package
unzip programming-package-imx8mm-jaguar-sentai.zip  # (or your board)
cd programming-package-imx8mm-jaguar-sentai/

# The programming package includes the correct UUU tool version
# NO need to install system UUU - use the included one for compatibility

# Program the board (takes ~3-5 minutes)
./program-imx8mm-jaguar-sentai.sh --flash
```

#### **Step 4: First Boot** 🎉
```bash
# 1. Set DIP switches back to normal boot mode
# 2. Power cycle the board
# 3. Board boots to login prompt (user: root, no password)
# 4. Connect Ethernet or setup WiFi
# 5. Start developing immediately!

# Verify everything works
docker --version      # Docker ready for containers
iwconfig              # WiFi available  
systemctl status       # All services running
```

### 🎯 **What You Get Out-of-the-Box**
- **Full Linux System**: Yocto-based embedded Linux with all drivers
- **Container Runtime**: Docker pre-installed for application deployment
- **Networking**: WiFi, Bluetooth, Ethernet configured and ready
- **Development Tools**: SSH, package managers, debugging utilities
- **Security**: Secure boot chain and encrypted storage support
- **Remote Management**: Foundries.io integration for fleet management

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

## 🔄 Continuous Integration

Our automated CI/CD pipeline builds and validates all board variants on every commit:

- **🚀 Automated Builds**: Active board variants built in parallel using self-hosted runners
- **📦 Programming Packages**: Complete board programming artifacts generated automatically  
- **🧪 Multi-Layer Quality**: Comprehensive validation across all code layers
- **🎯 Multi-Board Matrix**: Simultaneous builds for imx8mm and imx93 platforms
- **⚡ Optimized Performance**: Persistent cache and CPU-optimized parallel builds

### 🔍 **Comprehensive Quality & Security Validation**

Our CI pipeline includes enterprise-grade validation across all layers:

| **Layer** | **Checks** | **Tools** |
|-----------|------------|-----------|
| **Shell Scripts** | Syntax, best practices, security | `shellcheck` via Docker |
| **Yocto Recipes** | BB syntax, style, SRC_URI validation | Custom validators |
| **Layer Config** | Dependencies, priorities, collections | BitBake compatibility |
| **Device Trees** | DTS syntax, naming, indentation | Custom DT checkers |
| **Build System** | KAS configs, machine definitions | Multi-environment testing |
| **CVE Security** | Vulnerable packages, hardcoded secrets | Security scanners |
| **SBOM Generation** | Software Bill of Materials | SPDX-compliant SBOM |

### 🔒 **Security & CVE Validation**

#### **Vulnerability Scanning**
- **30+ Critical Packages**: OpenSSL, glibc, BusyBox, SSH, curl, systemd, kernel, U-Boot
- **Version Analysis**: Detection of pinned versions that may contain known vulnerabilities
- **Security Configuration**: Validation of FORTIFY_SOURCE, security CFLAGS/LDFLAGS
- **Network Security**: Detection of insecure HTTP/FTP downloads and configurations

#### **Secret & Credential Detection**
- **Hardcoded Secrets**: Scans for passwords, API keys, tokens, certificates in recipes
- **Configuration Security**: Identifies disabled security features and insecure settings
- **License Compliance**: Validates LICENSE declarations and identifies proprietary components
- **Technical Debt**: Tracks security-related TODOs and FIXMEs requiring attention

#### **Build Security & Reproducibility**
- **Reproducible Builds**: Validates SOURCE_DATE_EPOCH configuration
- **Security Features**: Checks for PAM, systemd, SELinux, SMACK, IMA integration
- **Debug Features**: Warns about debug-tweaks and development features in production
- **Host Contamination**: Prevents host system contamination in builds

### 📋 **SBOM & Supply Chain Transparency**

#### **SPDX-Compliant Documentation**
- **SPDX 2.3 Standard**: Industry-standard Software Bill of Materials format
- **Complete Inventory**: All recipes, versions, licenses, and dependencies tracked
- **Package Manifests**: Runtime package information from Yocto builds
- **Build Metadata**: Machine type, configuration, commit hash, timestamps

#### **Supply Chain Security**
- **Artifact Inclusion**: SBOM included in every programming package
- **Long-term Retention**: 90-day artifact retention for compliance auditing
- **Multi-Build Coverage**: Separate SBOMs for base and manufacturing tool builds
- **Traceability**: Complete source-to-deployment component tracking

#### **Compliance & Auditing**
- **Regulatory Compliance**: Supports software supply chain regulations
- **Vendor Management**: Clear component sourcing and licensing information
- **Security Audits**: Detailed vulnerability and component analysis
- **Risk Assessment**: Enables comprehensive security risk evaluation

[**View Latest Builds →**](https://github.com/DynamicDevices/meta-dynamicdevices/actions/workflows/kas-build-ci.yml)

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