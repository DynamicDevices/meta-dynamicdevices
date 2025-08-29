# E-ink Board Power Management

## Overview
Low power consumption and suspend/resume for i.MX93 Jaguar E-ink board.

## Device Tree PM ✅
- **Regulators**: WiFi (MCXC143VFM), BT/802.15.4, LTE power control
- **Sleep States**: UART, USDHC, SPI low-power pin configs
- **Wakeup**: WiFi GPIO, ZigBee interrupt, GPIO keys, Wake-on-LAN

## Kernel PM ✅
- **CPU**: Idle governors, SCHEDUTIL, thermal management
- **System**: S2idle suspend, runtime PM, power domains
- **Wireless**: MOAL/MLAN power save, MAC80211, SDIO sequencing

## Services ✅
- **WiFi PM**: `wifi-power-management` (IW612 optimization, Wake-on-LAN)
- **System PM**: Suspend/resume scripts, GPIO wakeup config

## Hardware ✅
- **MCXC143VFM**: External power controller, WiFi independent control
- **Power Domains**: MLMix, USB, SDIO power control

## Optimizations ✅
- **Disabled**: Audio, graphics, unnecessary USB, high-freq timers
- **Settings**: Powersave governor, NOOP scheduler, reduced swappiness
- **Network**: Aggressive WiFi/BT power save, 802.15.4 sleep modes

## Suspend/Resume ✅
- **Modes**: S2idle, runtime suspend, WiFi keep-power
- **Wakeup**: WiFi (GPIO4_25), ZigBee (GPIO4_27), USB, RTC, GPIO keys
- **Resume**: Adaptive governor, network restoration, device re-enumeration

## Power Targets ✅
- **Active**: 1.5W (full), 800mW (WiFi), 200mW (idle)
- **Suspend**: 50mW (S2idle+WiFi), 10mW (deep), 5mW (off)

## Testing
```bash
powertop  # Monitor consumption
systemctl suspend  # Test suspend/resume
cat /sys/power/wakeup_sources  # Check wakeup sources
```

## Status ✅
- **Complete**: DT config, kernel PM, services, WiFi optimization, wakeup sources
- **Ready**: Build testing, hardware validation, suspend/resume testing
