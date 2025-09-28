# Changelog

All notable changes to the meta-dynamicdevices BSP layer will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- TAS2563 Android driver with firmware binary support for imx8mm-jaguar-sentai
- Flexible NXP IW612 WiFi firmware selection (secure .se vs standard .bin)
- NXP_WIFI_SECURE_FIRMWARE configuration variable for build flexibility
- Comprehensive kernel driver optimization for imx93-jaguar-eink
- Dual GPLv3/Commercial licensing option
- Comprehensive hardware documentation in wiki
- Professional repository organization with docs/ and scripts/ directories
- Automated WoWLAN configuration for Edge EInk board

### Changed
- **BREAKING**: Switched imx8mm-jaguar-sentai from upstream TAS2562 to Android TAS2563 driver
- Optimized USB serial drivers from 50+ to 5 essential drivers for imx93-jaguar-eink
- Disabled unused SSD display drivers to eliminate kernel warnings
- Updated project context documentation with recent improvements

### Fixed
- NXP IW612 WiFi firmware loading issues (sduart_nw61x_v1.bin vs .se)
- Kernel boot time significantly improved with minimal driver set
- SSD1306/1331/1351 "no spi_device_id" warnings eliminated
- TAS2563 firmware binary download capability restored

### Changed
- Updated LICENSE from MIT-style to dual licensing
- Enhanced Edge AI Board documentation with complete pin mapping tables
- Reorganized repository structure for better maintainability

### Removed
- Zigbee support from Edge EInk board configuration
- Unnecessary dummy files and disabled configurations

## [1.0.0] - 2024-01-01

### Added
- Initial support for Edge board family
- Support for i.MX8MM Jaguar AI board (imx8mm-jaguar-sentai)
- Support for i.MX93 Jaguar EInk board (imx93-jaguar-eink)
- TAS2563 audio codec support with dual microphones
- NXP IW612 wireless tri-radio support (WiFi 6 + Bluetooth 5.4 + 802.15.4)
- BGT60TR13C radar sensor integration
- Environmental sensors (temperature, humidity, accelerometer)
- LED driver support for 6x RGBW LEDs
- USB-C power delivery with STUSB4500 controller
- Comprehensive testing scripts and CE marking support
- Container support with Docker and Waydroid
- Professional documentation and wiki integration

### Security
- OPTEE trusted execution environment support
- Secure boot capabilities
- Hardware security module (HSM) integration
