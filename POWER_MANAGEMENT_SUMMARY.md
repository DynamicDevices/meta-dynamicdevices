# E-ink Board Power Management Implementation

## Overview
Comprehensive power management implementation for the i.MX93 Jaguar E-ink board to optimize low power consumption and provide robust suspend/resume functionality.

## Key Features Implemented

### 1. Device Tree Power Management
**File**: `recipes-bsp/device-tree/lmp-device-tree/imx93-jaguar-eink.dts`

#### Power Regulators
- **WiFi Power Control**: MCXC143VFM-controlled regulator with startup delays
- **Bluetooth/802.15.4 Power**: Configurable power control with ramp delays
- **LTE Power**: Removable always-on for better power management

#### Sleep Pin Configurations
- **UART Sleep States**: Console and Bluetooth UART with GPIO fallback
- **USDHC Sleep States**: WiFi SDIO and eMMC with low-power pin configs
- **SPI Sleep States**: 802.15.4 interface with power-down configurations

#### Wakeup Sources
- **WiFi Wake**: GPIO interrupt from wireless module
- **ZigBee Wake**: 802.15.4 interrupt as wakeup source
- **GPIO Keys**: Dedicated wakeup key configuration
- **Wake-on-LAN**: Network-based system wakeup

### 2. Kernel Power Management
**Files**: 
- `recipes-kernel/linux/linux-lmp-fslc-imx/imx93-jaguar-eink/enable_power_management.cfg`
- `recipes-kernel/linux/linux-lmp-fslc-imx/imx93-jaguar-eink/enable_wifi_power_management.cfg`

#### CPU Power Management
- **CPU Idle**: Multiple idle governors (ladder, menu, TEO)
- **CPU Frequency Scaling**: SCHEDUTIL governor as default
- **ARM CPUIdle**: Platform-specific idle states
- **Thermal Management**: i.MX thermal driver with multiple governors

#### System Power Management
- **Suspend-to-Idle (S2idle)**: Primary suspend mode for ARM platforms
- **PM Generic Domains**: Power domain support for subsystems
- **Runtime PM**: Dynamic power management for devices
- **Wake Sources**: Comprehensive wakeup source handling

#### Wireless Power Management
- **NXP MOAL/MLAN**: Advanced power saving for IW612 chipset
- **MAC80211 Power Save**: Standard wireless power management
- **SDIO Power Sequence**: WiFi module power sequencing
- **Bluetooth Power Save**: UART and controller power management

### 3. System Services

#### WiFi Power Management Service
**Recipe**: `recipes-support/wifi-power-management/`
- Configures NXP IW612 WiFi module for optimal power consumption
- Sets power save modes via iw and iwconfig
- Configures MOAL driver parameters for deep sleep
- Enables Wake-on-LAN functionality

#### E-ink Power Management Service  
**Recipe**: `recipes-support/eink-power-management/`
- **Suspend Script**: Prepares system for low power mode
- **Resume Script**: Restores system performance after wakeup
- **Power Configuration**: System-wide power optimization
- **GPIO Wakeup**: Configures interrupt-based wakeup sources

### 4. Hardware Integration

#### MCXC143VFM Power Controller
- External microcontroller for advanced power management
- Controls WiFi module power independently of main CPU
- Allows WiFi to remain powered during i.MX93 suspend
- GPIO interface for power state control

#### Power Domains
- **MLMix Power Domain**: AI/ML accelerator power control
- **USB Power Domains**: LTE modem power management
- **SDIO Power Domains**: WiFi module power control

## Power Consumption Optimizations

### 1. Disabled Power-Hungry Features
- Audio subsystem (ALSA, PulseAudio, GStreamer)
- Graphics acceleration (Mesa, DRM)
- Unnecessary USB controllers
- High-frequency timers

### 2. Optimized Settings
- **CPU Governor**: Powersave for eink use case
- **I/O Scheduler**: NOOP/None for minimal overhead
- **Swappiness**: Reduced to 10 for less disk activity
- **USB Autosuspend**: 2-second timeout for rapid sleep

### 3. Network Power Optimization
- **WiFi Power Save**: Aggressive power saving modes
- **Bluetooth LE**: Low energy mode configuration
- **802.15.4**: Sleep modes between transmissions

## Suspend/Resume Functionality

### Suspend Modes Supported
1. **Suspend-to-Idle (S2idle)**: Primary mode for ARM platforms
2. **Runtime Suspend**: Per-device power management
3. **WiFi Keep-Power**: Maintains network connectivity

### Wakeup Sources
1. **WiFi Interrupt**: Network-based wakeup (GPIO4_25)
2. **ZigBee Interrupt**: 802.15.4 wakeup (GPIO4_27)
3. **USB Activity**: LTE modem wakeup
4. **RTC**: Timer-based wakeup
5. **GPIO Keys**: Manual wakeup buttons

### Resume Performance
- **Adaptive Governor**: CPU frequency based on system load
- **Network Restoration**: Automatic WiFi reconnection
- **Device Re-enumeration**: USB and SDIO device restoration
- **Performance Scaling**: Load-based power management

## Build Integration

### Image Features
**File**: `recipes-samples/images/lmp-feature-eink-power.inc`
- Power management packages inclusion
- Power monitoring tools (powertop, htop, iotop)
- CPU frequency utilities
- Network power tools (iw, wireless-tools, ethtool)

### Machine Configuration
**File**: `conf/machine/imx93-jaguar-eink.conf`
- Kernel module autoloading for power management
- Removed audio features to save power
- SPI buffer optimization for ZigBee communication

## Expected Power Consumption

### Active States
- **Full Operation**: ~1.5W (typical eink board usage)
- **WiFi Active**: ~800mW (with power save enabled)
- **Idle State**: ~200mW (CPU powersave, peripherals active)

### Suspend States
- **S2idle with WiFi**: ~50mW (WiFi powered, CPU suspended)
- **Deep Sleep**: ~10mW (MCXC143VFM control, minimal hardware)
- **Power Off**: ~5mW (MCXC143VFM only, system off)

## Testing and Validation

### Power Measurement Commands
```bash
# Check current power settings
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
cat /sys/class/net/*/device/power/control

# Monitor power consumption
powertop
htop
iotop

# Test suspend/resume
systemctl suspend
echo mem > /sys/power/state

# Check wakeup sources
cat /sys/power/wakeup_sources
cat /proc/interrupts
```

### Validation Steps
1. **Build Test**: Compile with new power management configs
2. **Boot Test**: Verify system boots with power services
3. **Suspend Test**: Test suspend/resume cycles
4. **Wakeup Test**: Verify all wakeup sources function
5. **Power Measurement**: Validate power consumption targets
6. **Network Test**: Confirm WiFi wake-on-LAN functionality

## Implementation Status

### ✅ Completed
- [x] Device tree power management configuration
- [x] Kernel power management configuration  
- [x] Suspend/resume scripts and services
- [x] WiFi power optimization service
- [x] System power configuration script
- [x] Build system integration
- [x] Wakeup source configuration

### 📋 Ready for Testing
- [ ] Build image with power management features
- [ ] Hardware testing with power meter
- [ ] Suspend/resume cycle testing
- [ ] Network wakeup functionality testing
- [ ] Performance validation under different loads

## Usage Instructions

### Enable Power Management
```bash
# Power management is automatically enabled on boot
systemctl status eink-power-config.service
systemctl status wifi-power-management.service

# Manual configuration
/usr/bin/eink-power-config.sh
/usr/bin/wifi-power-management.sh
```

### Suspend/Resume
```bash
# Suspend system
systemctl suspend

# Check suspend preparation
systemctl status eink-suspend.service

# Check resume status
systemctl status eink-resume.service
journalctl -u eink-resume.service
```

### Power Monitoring
```bash
# System power status
powertop
cat /sys/power/state
cat /sys/power/mem_sleep

# WiFi power status
iw dev wlan0 get power_save
cat /sys/class/net/wlan0/device/power/control

# CPU power status
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
cat /sys/devices/system/cpu/cpuidle/current_governor
```

## Future Enhancements

### Potential Improvements
1. **Dynamic Frequency Scaling**: Based on eink refresh rates
2. **Predictive Power Management**: ML-based power optimization
3. **Advanced Wake Patterns**: Network packet filtering
4. **Power Profiling**: Real-time power consumption monitoring
5. **Application-Level Power**: Power-aware application framework

### Hardware Enhancements
1. **Power Measurement**: Dedicated power monitoring hardware
2. **Battery Management**: For portable eink applications
3. **Power Domains**: More granular power control
4. **Thermal Optimization**: Temperature-based power scaling

---

*Implementation completed for i.MX93 Jaguar E-ink Board*  
*Ready for build testing and hardware validation*
