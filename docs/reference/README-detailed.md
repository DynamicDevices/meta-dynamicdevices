# meta-dynamicdevices

**Professional Yocto Application Layer for Dynamic Devices Edge Computing Platforms**

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![License: Commercial](https://img.shields.io/badge/License-Commercial-green.svg)](mailto:licensing@dynamicdevices.co.uk)
[![Yocto Compatible](https://img.shields.io/badge/Yocto-scarthgap%20|%20kirkstone-orange.svg)](https://www.yoctoproject.org/)
[![Foundries.io LMP](https://img.shields.io/badge/Foundries.io-v95%20(Scarthgap)-purple.svg)](https://foundries.io/products/releases/95/)

[![Yocto Layer Validation](https://github.com/DynamicDevices/meta-dynamicdevices/actions/workflows/yocto-layer-validation.yml/badge.svg)](https://github.com/DynamicDevices/meta-dynamicdevices/actions/workflows/yocto-layer-validation.yml)
[![KAS Build CI](https://github.com/DynamicDevices/meta-dynamicdevices/actions/workflows/kas-build-ci.yml/badge.svg)](https://github.com/DynamicDevices/meta-dynamicdevices/actions/workflows/kas-build-ci.yml)
[![GitHub Issues](https://img.shields.io/github/issues/DynamicDevices/meta-dynamicdevices)](https://github.com/DynamicDevices/meta-dynamicdevices/issues)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/DynamicDevices/meta-dynamicdevices)](https://github.com/DynamicDevices/meta-dynamicdevices/pulls)
[![Latest Release](https://img.shields.io/github/v/release/DynamicDevices/meta-dynamicdevices?include_prereleases)](https://github.com/DynamicDevices/meta-dynamicdevices/releases)
[![YP Compliance Ready](https://img.shields.io/badge/YP%20Compliance-Ready%20for%20Certification-blue)](https://docs.yoctoproject.org/test-manual/yocto-project-compatible.html)
[![Security Scanning](https://img.shields.io/badge/security-CVE%20%2B%20SBOM%20✓-blue)](https://github.com/DynamicDevices/meta-dynamicdevices/actions/workflows/kas-build-ci.yml)

This application layer provides comprehensive middleware and applications for Dynamic Devices Edge Computing platforms, featuring advanced audio processing, environmental sensing, wireless connectivity, and power management capabilities.

**Note**: This layer depends on separate submodules:
- **[meta-dynamicdevices-bsp](./meta-dynamicdevices-bsp/)** - Hardware-specific Board Support Package (BSP) components
- **[meta-dynamicdevices-distro](./meta-dynamicdevices-distro/)** - Distribution configurations and policies

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
# 🚀 EASIEST: One-time setup, then ultra-simple usage
./scripts/fio-program-board.sh --configure  # Set factory & machine defaults (auto-installs fioctl if needed)
echo 'factory: dynamic-devices' >> ~/.config/fioctl.yaml  # Set fioctl default
./scripts/fio-program-board.sh --machine imx93-jaguar-eink --program  # Download + program!

# 📦 Download only (manual programming)
./scripts/fio-program-board.sh --machine imx93-jaguar-eink  # Uses latest target automatically

# 🎯 Explicit control (all options)
./scripts/fio-program-board.sh --factory dynamic-devices --machine imx93-jaguar-eink 1975 --force

# 🪟 Windows users: Use the batch file version (Work in Progress)
scripts\fio-program-board.bat /configure  # Basic features available, latest target detection needs fixing

# Alternative: Manual download from GitHub CI
# Visit: https://github.com/DynamicDevices/meta-dynamicdevices/actions/workflows/kas-build-ci.yml
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
# 🚀 AUTOMATIC: If you used --program flag in Step 1, programming starts immediately!
# No waiting - just make sure board is in download mode before running

# 🔄 CONTINUOUS: For multiple boards, use --continuous flag
# Programs boards in sequence with tracking: Board #1, #2, #3...

# 📋 MANUAL: If you downloaded only, program manually:
cd downloads/target-*-imx93-jaguar-eink/  # (or your board)
sudo ./program-imx93-jaguar-eink.sh --flash

# 📦 MANUAL DOWNLOAD: Using GitHub CI packages
unzip programming-package-imx8mm-jaguar-sentai.zip  # (or your board)
cd programming-package-imx8mm-jaguar-sentai/
sudo ./program-imx8mm-jaguar-sentai.sh --flash

# ⚙️ BOOTLOADER ONLY: For development/recovery
sudo ./program-[your-board-name].sh --bootloader-only

# 📊 PERFORMANCE: Programming takes ~1-3 minutes with timing display
# 🔧 COMPATIBILITY: Uses included UUU tool version for reliability
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

### 🎯 **Board-Specific Programming Commands**

#### **Edge AI Board (imx8mm-jaguar-sentai)**
```bash
# Complete programming with custom boot files (RECOMMENDED)
./scripts/fio-program-board.sh --factory sentai --machine imx8mm-jaguar-sentai --program --mfgfolder program

# Alternative: Standard programming (if no custom boot files needed)
./scripts/fio-program-board.sh --factory sentai --machine imx8mm-jaguar-sentai --program
```

> **📝 Note**: The `--mfgfolder program` option uses custom boot files from the `program/` directory, which contain optimized bootloader and U-Boot images for the imx8mm-jaguar-sentai board.

### Build & Flash

```bash
# Set target machine
export KAS_MACHINE=imx8mm-jaguar-sentai

# Build image
./scripts/kas-build-base.sh

# Program board (RECOMMENDED: Use Foundries.io programming)
./scripts/fio-program-board.sh --factory sentai --machine imx8mm-jaguar-sentai --program --mfgfolder program

# Alternative: Local build programming (development only)
# Note: This uses locally built images, not production Foundries.io builds
./scripts/program-local-build.sh --machine imx8mm-jaguar-sentai
```

## 📚 Documentation

### Hardware Documentation
- **[Edge AI Board](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Edge-AI-Board)** - TAS2563 audio, sensors, pin mappings
- **[Edge EInk Board](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Edge-EInk-Board)** - Power management, WoWLAN, hardware specs
- **[Edge EV Board](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Edge-EV-Board)** - Energy metering and control
- **[Edge GW Board](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Edge-GW-Board)** - Communications gateway

### **🚀 Key Features of fio-program-board.sh**

| Feature | Description | Example |
|---------|-------------|---------|
| **🎯 Auto-Latest Target** | Uses latest build automatically | `--machine imx93-jaguar-eink` |
| **🏭 Default Factory** | Uses fioctl's default factory | No `--factory` needed |
| **📦 Auto-Install fioctl** | Installs fioctl if not found | Homebrew/snap/manual |
| **⚡ Auto-Programming** | Download + program in one command | `--program` flag |
| **🔄 Continuous Mode** | Program multiple boards in sequence | `--continuous` flag |
| **💾 Smart Caching** | Skips re-downloading existing files | Instant re-runs |
| **⏱️ Performance Timing** | Shows download + programming time | Real-time feedback |
| **🔧 i.MX93 Optimized** | Uses correct bootloader size | No "image too large" errors |
| **🪟 Windows Support** | Native batch file version (WIP) | `fio-program-board.bat` |
| **📁 Auto-Organization** | Creates `downloads/target-X-machine/` | Clean file management |

### Programming Documentation
- **[Board Programming with Foundries.io Builds](https://github.com/DynamicDevices/meta-dynamicdevices/wiki/Board-Programming-with-Foundries-Builds)** - Complete guide to programming boards using Foundries.io CI builds

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

## 🔨 Building from Source

### Quick Build Commands

```bash
# Build for E-Ink board
KAS_MACHINE=imx93-jaguar-eink ./scripts/kas-build-base.sh

# Build for Audio board
KAS_MACHINE=imx8mm-jaguar-sentai ./scripts/kas-build-base.sh

# Enhanced build with options
./scripts/kas-build-base-enhanced.sh -m imx93-jaguar-eink -j 8 -v
```

### 🔐 Building with Private Repositories

Some recipes in this layer access private repositories (e.g., `eink-spectra6`). To build these successfully, you need SSH key access:

#### **Prerequisites for Private Repository Access**

1. **SSH Key Setup**:
   ```bash
   # Ensure you have SSH keys configured for GitHub
   ssh -T git@github.com
   # Should show: "Hi username! You've successfully authenticated..."
   ```

2. **SSH Agent Running**:
   ```bash
   # Start SSH agent if not running
   eval "$(ssh-agent -s)"
   
   # Add your SSH key
   ssh-add ~/.ssh/id_rsa  # or your specific key file
   
   # Verify key is loaded
   ssh-add -l
   ```

#### **Build Process with SSH Keys**

The build scripts automatically handle SSH key forwarding to the kas-container:

```bash
# The scripts automatically detect and forward SSH keys
KAS_MACHINE=imx93-jaguar-eink ./scripts/kas-build-base.sh
```

**What happens automatically**:
- ✅ SSH agent forwarding (`--ssh-agent`)
- ✅ SSH directory mounting (`--ssh-dir ~/.ssh`)
- ✅ Proper container permissions
- ✅ GitHub host key handling

#### **Troubleshooting SSH Issues**

If you encounter SSH-related build errors:

1. **Verify SSH Access**:
   ```bash
   # Test GitHub access
   ssh -T git@github.com
   ```

2. **Check SSH Agent**:
   ```bash
   # Verify SSH agent is running
   echo $SSH_AUTH_SOCK
   
   # List loaded keys
   ssh-add -l
   ```

3. **Debug in Container**:
   ```bash
   # Enter build container shell
   ./scripts/kas-shell-base.sh
   
   # Inside container, test SSH
   ssh -T git@github.com
   ```

4. **Manual SSH Setup** (if automatic detection fails):
   ```bash
   # Ensure SSH directory exists and has correct permissions
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/id_rsa
   chmod 644 ~/.ssh/id_rsa.pub
   ```

#### **CI/CD Considerations**

For automated builds in CI/CD environments:

- **GitHub Actions**: Use `ssh-agent` action to load deploy keys
- **GitLab CI**: Configure SSH keys in CI/CD variables
- **Jenkins**: Use SSH Agent plugin with credential management

### Build Artifacts

After successful build, artifacts are available in:
```
build/tmp/deploy/images/[machine]/
├── lmp-factory-image-[machine].wic.gz  # Main system image
├── imx-boot-[machine]                   # Bootloader
└── u-boot-[machine].itb                # U-Boot image
```

### 🔧 Programming Local Builds

After building locally, you can program your board with the development image:

```bash
# Program local build (development/testing)
./scripts/program-local-build.sh --machine imx93-jaguar-eink

# Alternative: Using environment variable
KAS_MACHINE=imx93-jaguar-eink ./scripts/program-local-build.sh

# For other machines
./scripts/program-local-build.sh --machine imx8mm-jaguar-sentai
./scripts/program-local-build.sh --machine imx8mm-jaguar-phasora
```

**Prerequisites for local programming**:
1. **Build completed successfully** - Run `kas-build-base.sh` first
2. **Board in download mode** - Set DIP switches and connect USB
3. **UUU tool available** - Should be in `program/` directory
4. **Root privileges** - UUU requires sudo access

**Important Notes**:
- 🔧 **Development Only**: Local builds are for development and testing
- 🏭 **Production**: Use `fio-program-board.sh` for production deployments
- ⚠️ **No OTA**: Local builds don't include Foundries.io OTA capabilities
- 🔒 **Security**: Local builds may have different security configurations

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
| **Yocto Compatible** | Official Yocto Project layer compatibility | `yocto-check-layer` script |
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

### Boot Performance Optimization ⚡

**Target**: < 1.5s boot time for optimal user experience

#### Current Status (i.MX93 Jaguar E-Ink)
- **Baseline**: 22.7s total boot time (15x over target)
- **Recent test**: 22.936s (only 0.33s improvement after optimizations)
- **Issue**: U-Boot optimizations showing minimal impact (2.879s → 2.884s)
- **Major bottleneck**: Kernel+Systemd phase still ~15 seconds

#### U-Boot Recipe Architecture

The project uses three different U-Boot recipes:
- **`u-boot-fio`**: Main recipe for both local and Foundries.io builds ✅
- **`u-boot-fio-mfgtool`**: Manufacturing/programming only (UUU)
- **`u-boot-ostree-scr-fit`**: Boot scripts for Foundries.io (not U-Boot config)

**Key insight**: Boot optimizations in `u-boot-fio` automatically apply to both local and production builds!

#### Serial Boot Logging Tools ✅
```bash
# Complete workflow - capture and analyze
./scripts/boot-timing-suite.sh capture --name board-test
# Power cycle board, wait for boot completion
./scripts/boot-timing-suite.sh latest

# Continuous monitoring and comparison
./scripts/boot-timing-suite.sh monitor --name consistency-test
./scripts/boot-timing-suite.sh compare
```

#### Documentation
- **U-Boot Recipes**: [docs/U_BOOT_RECIPES.md](docs/U_BOOT_RECIPES.md)
- **Serial Logging**: [scripts/BOOT_TIMING_README.md](scripts/BOOT_TIMING_README.md)
- **Boot Profiling**: [docs/BOOT_PROFILING.md](docs/BOOT_PROFILING.md)
- **Optimization Context**: [docs/projects/boot-optimization-context.md](docs/projects/boot-optimization-context.md)

### Contributing
1. Review [best practices guide](docs/YOCTO_BSP_BEST_PRACTICES.md)
2. Use [recipe template](docs/RECIPE_TEMPLATE.bb) for new components
3. Update documentation and changelog
4. Follow professional development standards

## 🏅 Yocto Project Layer Information

### Layer Details
- **Layer Name**: meta-dynamicdevices
- **Layer Type**: BSP (Board Support Package) + Software Layer
- **Maintainer**: Dynamic Devices Ltd
- **Repository**: https://github.com/DynamicDevices/meta-dynamicdevices
- **Branch Compatibility**: scarthgap, kirkstone
- **Yocto Project Compatible**: In Progress
- **OpenEmbedded Index**: [Registered](https://layers.openembedded.org/layerindex/branch/master/layer/meta-dynamicdevices/)

### Layer Origin & Purpose
This layer was created by Dynamic Devices Ltd to provide comprehensive board support for our Edge Computing platform family. The layer includes:

- **BSP Components**: Device trees, kernel configurations, bootloader support
- **Hardware Drivers**: Audio (TAS2563), power management (STUSB4500), sensors
- **Software Stack**: Audio processing, connectivity, system services
- **Integration**: Foundries.io LMP integration for secure OTA updates

### Dependencies
**Required Layers:**
- `openembedded-core` (meta)
- `meta-lmp-base` (Foundries.io Linux microPlatform)
- `meta-lmp-bsp` (Foundries.io BSP layer)
- `meta-openembedded/meta-oe`
- `meta-openembedded/meta-networking`
- `meta-openembedded/meta-python`
- `meta-openembedded/meta-multimedia`

**Optional Layers:**
- `meta-rust-bin` (for Rust-based utilities)
- `meta-security` (enhanced security features)

### Version Requirements
- **Yocto Project**: 5.0+ (Scarthgap) or 4.0+ (Kirkstone)
- **BitBake**: 2.0+
- **Python**: 3.8+
- **KAS**: 3.0+ (recommended build tool)

### Submitting Changes
1. **Fork** the repository on GitHub
2. **Create** a feature branch from main
3. **Follow** coding standards and use provided templates
4. **Test** changes with `yocto-check-layer` validation
5. **Submit** pull request with detailed description
6. **Address** review feedback promptly

### Bug Reports & Issues
- **GitHub Issues**: https://github.com/DynamicDevices/meta-dynamicdevices/issues
- **Security Issues**: See [SECURITY.md](SECURITY.md) for responsible disclosure
- **Feature Requests**: Use GitHub Issues with enhancement label

### Layer Compatibility
This layer is designed to be compatible with other Yocto Project layers:
- **No QA Bypasses**: All standard QA checks are enabled
- **Network Access**: Only during do_fetch using BitBake fetcher APIs
- **Non-Invasive**: Does not change system behavior without explicit configuration
- **Separation**: Hardware, distro, and software components are properly separated
- **OpenEmbedded Registered**: [Official layer index entry](https://layers.openembedded.org/layerindex/branch/master/layer/meta-dynamicdevices/)

## 📞 Support

- **Technical Issues**: [GitHub Issues](https://github.com/DynamicDevices/meta-dynamicdevices/issues)
- **Security Issues**: [security@dynamicdevices.co.uk](mailto:security@dynamicdevices.co.uk)
- **Commercial Licensing**: [licensing@dynamicdevices.co.uk](mailto:licensing@dynamicdevices.co.uk)
- **General Inquiries**: [info@dynamicdevices.co.uk](mailto:info@dynamicdevices.co.uk)
- **Wiki**: [Comprehensive Documentation](https://github.com/DynamicDevices/meta-dynamicdevices/wiki)

---

*For detailed hardware specifications, software features, and development guides, please refer to the [comprehensive wiki documentation](https://github.com/DynamicDevices/meta-dynamicdevices/wiki).*