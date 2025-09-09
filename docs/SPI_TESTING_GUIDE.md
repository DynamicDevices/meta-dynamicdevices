# E-Ink Display SPI Interface Testing Guide

**Board:** imx93-jaguar-eink  
**Target:** Hardware validation and signal integrity testing  
**Audience:** Hardware engineers

## Overview

This document provides test procedures for validating the E-Ink display SPI interfaces on the imx93-jaguar-eink board. The board provides two SPI options:

1. **QSPI (FlexSPI1)** - Preferred, up to 80 MHz, 4-bit data width
2. **Standard SPI (LPSPI1)** - Backup, up to 10 MHz, 1-bit data width

## Hardware Configuration

### Current Working Status ✅❌
- ❌ **FlexSPI1 (QSPI)**: **DISABLED** - Not compatible with standard SPI tools (see FlexSPI incompatibility section)
- ✅ **LPSPI1 (Standard SPI)**: **PRIMARY** - Should create `/dev/spidev1.0` for standard SPI testing

**Configuration Change**: FlexSPI1 has been **disabled** in the device tree to avoid conflicts. LPSPI1 is now the **primary** interface for E-Ink display testing with standard SPI tools.

**Expected Result**: With this configuration, `/dev/spidev1.0` should be available for standard SPI testing tools like `spidev_test`.

### Board Switch Settings

For **LPSPI1 (Standard SPI)** testing, configure the hardware switches:

**Current Configuration - Standard SPI:**
- Board SPI Mode Switches: 4=X, 3=OFF, 2=ON, 1=ON  
- Display Mode Switches: BS1=OFF, BS0=ON

**Note**: QSPI mode is disabled in software but preserved for reference:
- QSPI switches would be: 4=X, 3=ON, 2=ON, 1=OFF (BS1=OFF, BS0=OFF)

### Signal Connections for Oscilloscope/Logic Analyzer

#### QSPI Interface (FlexSPI1)
| Signal | i.MX93 Pin | Test Point | Expected Voltage |
|--------|------------|------------|------------------|
| QSPI_CLK | MX93_PAD_SD3_CLK | TP_QSPI_CLK | 1.8V → 3.3V |
| QSPI_CS | MX93_PAD_SD3_CMD | TP_QSPI_CS | 1.8V → 3.3V |
| QSPI_D0 | MX93_PAD_SD3_DATA0 | TP_QSPI_D0 | 1.8V → 3.3V |
| QSPI_D1 | MX93_PAD_SD3_DATA1 | TP_QSPI_D1 | 1.8V → 3.3V |
| QSPI_D2 | MX93_PAD_SD3_DATA2 | TP_QSPI_D2 | 1.8V → 3.3V |
| QSPI_D3 | MX93_PAD_SD3_DATA3 | TP_QSPI_D3 | 1.8V → 3.3V |

#### Standard SPI Interface (LPSPI1)
| Signal | i.MX93 Pin | Test Point | Expected Voltage |
|--------|------------|------------|------------------|
| SPI1_CLK | MX93_PAD_SAI1_TXD0 | TP_SPI1_CLK | 1.8V → 3.3V |
| SPI1_CS | MX93_PAD_SAI1_TXFS | TP_SPI1_CS | 1.8V → 3.3V |
| SPI1_MOSI | MX93_PAD_SAI1_RXD0 | TP_SPI1_MOSI | 1.8V → 3.3V |
| SPI1_MISO | MX93_PAD_SAI1_TXC | TP_SPI1_MISO | 1.8V → 3.3V |

#### Control GPIOs
| Signal | i.MX93 Pin | Test Point | Expected Voltage |
|--------|------------|------------|------------------|
| RES_DIS# | MX93_PAD_GPIO_IO08 | TP_RESET | 1.8V → 3.3V |
| BUSY | MX93_PAD_GPIO_IO09 | TP_BUSY | 1.8V → 3.3V |
| DC | MX93_PAD_GPIO_IO10 | TP_DC | 1.8V → 3.3V |
| POWER_EN | MX93_PAD_GPIO_IO11 | TP_PWR_EN | 1.8V → 3.3V |

## Software Test Commands

### Prerequisites

#### SSH Setup for Automated Testing

For efficient testing and deployment, configure passwordless SSH access to the target board:

```bash
# Copy SSH public key to target board (replace IP as needed)
echo "fio" | ssh-copy-id -f fio@192.168.0.36

# Configure passwordless sudo for fio user
ssh fio@192.168.0.36 "echo 'fio' | sudo -S sh -c 'echo \"fio ALL=(ALL) NOPASSWD: ALL\" > /etc/sudoers.d/fio'"
```

**Benefits:**
- Enables automated testing scripts without password prompts
- Faster iterative development and testing cycles
- Required for CI/CD integration and automated deployment

#### SPI Interface Verification

SSH into the board and ensure SPI interfaces are available:

```bash
# Check available SPI devices
ls -la /dev/spi*

# Expected output:
# /dev/spidev0.0  <- QSPI interface (FlexSPI1) - PRIMARY INTERFACE
```

**Current Status**:
- ✅ **FlexSPI1 (QSPI)**: `/dev/spidev0.0` - **Working and preferred for E-Ink display**
- ❌ **LPSPI1 (Standard SPI)**: Not available - backup interface, not critical

**Note**: The device tree uses `"spidev"` compatible strings for direct hardware testing access. The FlexSPI1 QSPI interface is the primary interface for the E-Ink display and provides higher performance with quad data lines.

### Test 1: GPIO Control Signal Testing

Test the display control GPIOs first:

```bash
# Test Reset signal (GPIO2_14 = 78)
echo 78 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio78/direction

# Reset pulse - should see LOW then HIGH on oscilloscope
echo 0 > /sys/class/gpio/gpio78/value  # Reset active (LOW)
sleep 0.1
echo 1 > /sys/class/gpio/gpio78/value  # Reset inactive (HIGH)

# Test Data/Command signal (GPIO2_15 = 79)
echo 79 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio79/direction

# Toggle DC signal - should see transitions on oscilloscope
echo 0 > /sys/class/gpio/gpio79/value  # Command mode
sleep 0.1
echo 1 > /sys/class/gpio/gpio79/value  # Data mode

# Test Left/Right Select (GPIO2_16 = 80)
echo 80 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio80/direction

# Toggle L/R selection - should see transitions on oscilloscope
echo 0 > /sys/class/gpio/gpio80/value  # Left panel
sleep 0.1
echo 1 > /sys/class/gpio/gpio80/value  # Right panel

# Test Busy Status (GPIO2_17 = 81) - Input only
echo 81 > /sys/class/gpio/export
echo in > /sys/class/gpio/gpio81/direction
cat /sys/class/gpio/gpio81/value  # Read busy status (0=busy, 1=ready)

# Test Power Enable (GPIO2_11 = 75)
echo 75 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio75/direction

# Power cycle - should see LOW then HIGH on oscilloscope
echo 0 > /sys/class/gpio/gpio75/value  # Power off
sleep 0.5
echo 1 > /sys/class/gpio/gpio75/value  # Power on

# Cleanup
echo 72 > /sys/class/gpio/unexport
echo 74 > /sys/class/gpio/unexport
echo 75 > /sys/class/gpio/unexport
```

### Test 2: QSPI Interface Testing ❌ (Disabled)

**Status**: FlexSPI1 QSPI interface is **DISABLED** in device tree for standard SPI testing

**Configuration**: FlexSPI1 has been disabled to avoid conflicts with standard SPI tools and to focus testing on LPSPI1.

**FIXED**: SPI device is now properly configured and working on i.MX93 E-Ink board.

## Device Tree Configuration Fix

The issue was resolved by fixing the device tree configuration:

1. **Machine Configuration**: Added missing `KERNEL_MODULE_AUTOLOAD:imx93-jaguar-eink = " spidev"`
2. **Device Tree Compatible**: Changed from `"spidev"` to `"rohm,dh2228fv"` for proper driver binding
3. **Interface Selection**: Using LPSPI1 (standard SPI) instead of FlexSPI1 (memory-mapped interface)

**Current Working Configuration**:
- **SPI Controller**: LPSPI1 at address `44360000.spi` (mapped as `spi0`)
- **Device Node**: `/dev/spidev0.0` (automatically created after boot)
- **Max Speed**: 10 MHz (configurable up to higher speeds)
- **Mode**: Standard SPI with CPHA and CPOL support
- **GPIO Control**: Reset, DC, Busy, and LR-select pins properly configured

**FlexSPI vs LPSPI**:
- **FlexSPI**: Memory-mapped interface for flash devices, uses MTD subsystem (`/dev/mtd*`)
- **LPSPI**: Standard SPI controller, uses spidev subsystem (`/dev/spidev*`)

```bash
# Install spi-tools if not available
# opkg install spi-tools

# Test SPI with simple data pattern
# This will generate clock and data signals on LPSPI1

# Single byte test - should see 8 clock pulses
echo -n -e '\x55' | spi-pipe -d /dev/spidev0.0 -s 1000000 -b 8

# Pattern test - should see alternating pattern on data lines
echo -n -e '\xAA\x55\xFF\x00' | spi-pipe -d /dev/spidev0.0 -s 5000000 -b 8

# High frequency test - test at maximum speed
echo -n -e '\x01\x02\x04\x08\x10\x20\x40\x80' | spi-pipe -d /dev/spidev0.0 -s 80000000 -b 8

# Continuous pattern for signal integrity testing
for i in {1..100}; do
    echo -n -e '\xAA\x55\xAA\x55' | spi-pipe -d /dev/spidev0.0 -s 10000000 -b 8
    sleep 0.01
done
```

### Test 3: Standard SPI Interface Testing ✅ (Primary)

**Status**: LPSPI1 is now the **primary** interface for E-Ink display testing

**Expected Device**: `/dev/spidev1.0` (LPSPI1)

**Pre-Test Check**:
```bash
# Verify spidev device exists
ls -la /dev/spidev1.0
# Expected: /dev/spidev1.0

# Check SPI device in sysfs
ls -la /sys/bus/spi/devices/spi1.0
```

**SPI Communication Tests**:

```bash
# Test standard SPI with simple data pattern
# This will generate clock, MOSI, and CS signals

# Single byte test - should see 8 clock pulses on SPI1_CLK
echo -n -e '\x55' | spi-pipe -d /dev/spidev1.0 -s 1000000 -b 8

# Pattern test - should see data pattern on MOSI line
echo -n -e '\xAA\x55\xFF\x00' | spi-pipe -d /dev/spidev1.0 -s 5000000 -b 8

# Maximum frequency test for standard SPI
echo -n -e '\x01\x02\x04\x08\x10\x20\x40\x80' | spi-pipe -d /dev/spidev1.0 -s 10000000 -b 8

# Continuous pattern for signal integrity testing
for i in {1..100}; do
    echo -n -e '\xF0\x0F\xF0\x0F' | spi-pipe -d /dev/spidev1.0 -s 8000000 -b 8
    sleep 0.01
done
```

### Test 4: Frequency Sweep Testing

Test different frequencies to verify signal integrity:

```bash
# QSPI frequency sweep
echo "Testing QSPI at different frequencies..."
for freq in 1000000 5000000 10000000 20000000 40000000 80000000; do
    echo "Testing QSPI at ${freq} Hz"
    echo -n -e '\xAA\x55\xAA\x55' | spi-pipe -d /dev/spidev0.0 -s $freq -b 8
    sleep 0.5
done

# Standard SPI frequency sweep  
echo "Testing Standard SPI at different frequencies..."
for freq in 1000000 2000000 5000000 8000000 10000000; do
    echo "Testing SPI at ${freq} Hz"
    echo -n -e '\xAA\x55\xAA\x55' | spi-pipe -d /dev/spidev1.0 -s $freq -b 8
    sleep 0.5
done
```

### Test 5: Level Shifter Direction Testing

Test autosensing vs fixed direction level shifters:

```bash
# This test attempts to read from the SPI device
# Autosensing buffers should handle bidirectional signals
# Fixed direction buffers will only work for write operations

# Test read operation (requires autosensing buffers)
echo "Testing SPI read operation (requires autosensing level shifters)..."

# Send command and try to read response
# This will fail with fixed direction buffers
spi-pipe -d /dev/spidev0.0 -s 1000000 -b 8 -r 4 <<< $'\x9F\x00\x00\x00'

# If the above command returns data, autosensing buffers are working
# If it times out or returns zeros, you may have fixed direction buffers
```

## Expected Signal Characteristics

### Timing Requirements

**QSPI Interface:**
- **Clock Frequency**: 1 MHz to 80 MHz
- **Setup Time**: > 2 ns
- **Hold Time**: > 2 ns
- **CS Setup**: > 5 ns before first clock edge
- **CS Hold**: > 5 ns after last clock edge

**Standard SPI Interface:**
- **Clock Frequency**: 1 MHz to 10 MHz  
- **Setup Time**: > 5 ns
- **Hold Time**: > 5 ns
- **CS Setup**: > 10 ns before first clock edge
- **CS Hold**: > 10 ns after last clock edge

### Signal Integrity Checks

**Voltage Levels:**
- **i.MX93 Side**: 1.8V ±10% (1.62V - 1.98V)
- **Display Side**: 3.3V ±10% (2.97V - 3.63V)
- **Logic High**: > 70% of VDD
- **Logic Low**: < 30% of VDD

**Signal Quality:**
- **Rise/Fall Time**: < 10% of clock period
- **Overshoot**: < 20% of VDD
- **Undershoot**: < 20% of VDD
- **Jitter**: < 5% of clock period

## Troubleshooting

### SPI Device Not Found (FIXED)

**Issue**: `/dev/spidev0.0` doesn't exist after boot

**Root Cause**: Missing kernel module autoload and incorrect device tree compatible string

**Solution Applied**:
1. **Machine Configuration Fix** (`imx93-jaguar-eink.conf`):
   ```
   KERNEL_MODULE_AUTOLOAD:imx93-jaguar-eink = " spidev"
   ```

2. **Device Tree Fix** (`imx93-jaguar-eink.dts`):
   ```dts
   eink_display_spi: eink@0 {
       compatible = "rohm,dh2228fv";  // Changed from "spidev"
       reg = <0>;
       spi-max-frequency = <10000000>;
       // ... rest of configuration
   };
   ```

**Manual Workaround** (if needed on older builds):
```bash
# Set driver override
echo spidev | sudo tee /sys/bus/spi/devices/spi0.0/driver_override

# Bind the driver
echo spi0.0 | sudo tee /sys/bus/spi/drivers/spidev/bind

# Fix permissions
sudo chmod 666 /dev/spidev0.0
```

### Common Issues

**No SPI Activity:**
1. Check hardware switch settings
2. Verify power supply (3.3V and 1.8V rails)
3. Check device tree configuration
4. Verify GPIO control signals

**Signal Integrity Issues:**
1. Check level shifter power supplies
2. Verify ground connections
3. Check for proper termination
4. Measure signal integrity at both sides of level shifters

**Level Shifter Direction Issues:**
1. Autosensing buffers may need pull-up/pull-down resistors
2. Check if attached devices affect direction sensing
3. Consider switching to fixed direction buffers for write-only operation

### Debug Commands

```bash
# Check SPI driver status
cat /proc/interrupts | grep spi

# Check device tree configuration
cat /proc/device-tree/soc@0/bus@42000000/spi@42360000/status
cat /proc/device-tree/soc@0/bus@42000000/flexspi@425e0000/status

# Check GPIO status
cat /sys/kernel/debug/gpio

# Monitor kernel messages
dmesg | grep -i spi
```

## Test Report Template

Document your test results using this template:

```
SPI Interface Test Report
========================
Date: ___________
Tester: ___________
Board Serial: ___________

Hardware Configuration:
- Board SPI Mode Switches: ___________
- Display Mode Switches: ___________
- Level Shifter Type: ___________

QSPI Interface Tests:
- GPIO Control Signals: PASS/FAIL
- 1 MHz Operation: PASS/FAIL  
- 10 MHz Operation: PASS/FAIL
- 80 MHz Operation: PASS/FAIL
- Signal Integrity: PASS/FAIL
- Voltage Levels: _____ V (i.MX93), _____ V (Display)

Standard SPI Interface Tests:
- GPIO Control Signals: PASS/FAIL
- 1 MHz Operation: PASS/FAIL
- 10 MHz Operation: PASS/FAIL  
- Signal Integrity: PASS/FAIL
- Voltage Levels: _____ V (i.MX93), _____ V (Display)

Level Shifter Tests:
- Direction Sensing: PASS/FAIL
- Bidirectional Operation: PASS/FAIL

Issues Found:
___________

Recommendations:
___________
```

## Safety Notes

- **ESD Protection**: Use proper ESD protection when probing signals
- **Probe Loading**: Use high-impedance probes (>1MΩ) to avoid signal loading
- **Power Sequencing**: Ensure proper power-up sequence (1.8V before 3.3V)
- **Hot Plugging**: Do not connect/disconnect probes while system is powered

For questions or issues, contact the software team with test results and oscilloscope captures.
