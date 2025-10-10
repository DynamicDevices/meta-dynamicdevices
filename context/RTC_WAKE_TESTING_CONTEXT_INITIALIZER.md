# RTC Wake Testing Context Initializer

## Project Overview
**Dynamic Devices E-Ink Power Management - RTC Wake Testing**
- **Hardware**: i.MX93 Jaguar E-Ink board with external PCF2131 RTC
- **Objective**: Test and validate `rtcwake` functionality for power-efficient sleep/wake cycles
- **Power Goal**: 5-year battery life through optimized sleep states

## Hardware Configuration
### RTC Hardware
- **External RTC**: PCF2131 (I2C connected)
- **Wake Interrupt**: GPIO-based wake signal from RTC to i.MX93
- **Power Controller**: MCXC143VFM manages overall power states
- **Battery**: Primary power source requiring ultra-low power consumption

### Key Components
- **Main SoC**: i.MX93 (low-voltage variant, SOC ID 37632)
- **Display**: E-Ink (SPI or USB T2000)
- **Connectivity**: Maya W2 (WiFi/BT) with power management
- **Storage**: eMMC with OSTree atomic updates

## Current Power Management Services
### Implemented Services
1. **eink-restart.service**: Custom reboot using `eink-power-cli board reset`
2. **eink-shutdown.service**: Custom shutdown using `eink-power-cli board shutdown`
3. **eink-power-cli**: v2.3.0 - UART communication with MCXC143VFM

### Power Management Tools
- **eink-power-cli**: Primary interface to power controller
  - Commands: `board reset`, `board shutdown`, `ping`, `status`
  - UART: `/dev/ttyLP2` communication
- **systemd-timesyncd**: NTP sync with hardware clock updates

## RTC Wake Testing Objectives
### Primary Goals
1. **Validate RTC Wake Interrupt**: Confirm GPIO wake signal functionality
2. **Test rtcwake Command**: Verify kernel RTC wake support
3. **Power State Verification**: Measure actual power consumption during sleep
4. **Integration Testing**: Ensure compatibility with power controller

### Testing Approach
1. **Interrupt Configuration Check**: Verify device tree RTC wake interrupt setup
2. **RTC Device Validation**: Confirm `/dev/rtc*` devices and capabilities
3. **Wake Signal Testing**: Test GPIO interrupt path from RTC to SoC
4. **rtcwake Functionality**: Test various sleep modes and wake times
5. **Power Measurement**: Validate actual power consumption during sleep

## Key Files and Locations
### Device Tree Configuration
- **Main DTS**: `meta-dynamicdevices-bsp/recipes-bsp/device-tree/lmp-device-tree/imx93-jaguar-eink.dts`
- **RTC Node**: PCF2131 I2C configuration with wake interrupt
- **GPIO Configuration**: Wake interrupt pin mapping

### Power Management Recipes
- **eink-power-cli**: `meta-dynamicdevices-bsp/recipes-support/eink-power-cli/`
- **Power Services**: `meta-dynamicdevices-bsp/recipes-bsp/eink-power-management/`

### Target Access
- **SSH**: `fio@62.3.79.162:25` (password: fio)
- **Current Build**: Target 2212 (with Bluetooth UART fixes)

## Recent Context
### Recently Fixed Issues
1. **Bluetooth UART**: Fixed Maya W2 RTS/CTS pin configuration and baudrate
2. **SOC ID Warning**: Disabled LPM driver for low-voltage i.MX93 variant
3. **OSTree Configuration**: Aligned kernel `ro` parameter with read-only root

### Current Status
- **Build**: Target 2212 deployed with critical Bluetooth fixes
- **Power Services**: Fully operational with systemd integration
- **Documentation**: Updated wiki and technical documentation

## Testing Environment
### Hardware Requirements
- **Power Meter**: For measuring actual sleep current consumption
- **Serial Console**: For monitoring wake events and kernel messages
- **Network Access**: For remote testing and log collection

### Software Tools
- **rtcwake**: Kernel utility for RTC-based wake scheduling
- **hwclock**: Hardware clock management
- **journalctl**: System log analysis for wake events
- **eink-power-cli**: Power controller communication

## Expected Challenges
1. **RTC Driver Compatibility**: Ensuring PCF2131 supports alarm/wake functionality
2. **GPIO Interrupt Configuration**: Proper device tree setup for wake signals
3. **Power State Coordination**: Integration between RTC wake and power controller
4. **Timing Accuracy**: RTC precision for scheduled wake events
5. **Power Consumption**: Achieving target battery life during sleep states

## Success Criteria
1. **RTC Wake Interrupt**: Confirmed functional GPIO wake signal
2. **rtcwake Command**: Successfully schedules and executes wake events
3. **Power Consumption**: Sleep current < 100µA for 5-year battery target
4. **System Integration**: Seamless operation with existing power management
5. **Reliability**: Consistent wake functionality across multiple test cycles

---
**Next Steps**: Begin with RTC wake interrupt validation and device tree analysis.
