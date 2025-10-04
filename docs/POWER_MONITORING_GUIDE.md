# E-Ink Board Power Monitoring Guide

## Overview

This guide describes how to monitor power consumption of the imx93-jaguar-eink board during firmware optimization using the Keysight 34461A digital multimeter.

## Equipment Setup

### Hardware
- **Power Meter**: Keysight 34461A Digital Multimeter
- **Network**: Connected at 192.168.1.116:5025
- **Interface**: SCPI over TCP/IP
- **Measurement**: Current sensing with 5V supply voltage assumption

### Access Setup
- **Monitoring Host**: Michael's laptop (oliver-XPS-13-9380)
- **SSH Access**: `ssh michael-laptop` (multiplexed connection)
- **Location**: 62.3.79.162:23

## Power Monitoring Script

### Installation
The power monitoring script is located on Michael's laptop at `~/power_monitor.sh`.

### Usage
```bash
# Connect to monitoring laptop
ssh michael-laptop

# Basic monitoring (2-second intervals, 5 minutes)
./power_monitor.sh

# Custom intervals and duration
./power_monitor.sh [interval_seconds] [duration_seconds]

# Examples:
./power_monitor.sh 1 60        # 1-second intervals for 1 minute
./power_monitor.sh 5 1800      # 5-second intervals for 30 minutes
```

### Output Format
The script provides human-readable output with:
- **Time**: Current timestamp
- **Current**: Formatted with appropriate units (mA, µA, nA, pA)
- **Power**: Calculated power consumption (W, mW, µW, nW)
- **Status**: Power state indicator

```
========================================
E-Ink Board Power Monitoring
========================================
Time                 Current      Power (5V)   Status         
--------------------------------------------------------------------
15:46:16            10.2 nA      51.0 nW      SLEEP/OFF      
15:46:18            12.5 nA      62.5 nW      SLEEP/OFF      
15:46:20            850.3 µA     4.3 mW       ACTIVE         
```

### Status Indicators
- **HIGH POWER**: > 100 mA (active processing, WiFi transmission)
- **ACTIVE**: 10-100 mA (normal operation, WiFi connected)
- **LOW POWER**: 1-10 mA (idle with optimizations)
- **IDLE**: 1 µA - 1 mA (deep idle, minimal activity)
- **SLEEP/OFF**: < 1 µA (suspend/sleep modes)

### Data Logging
All measurements are automatically logged to CSV files with format:
`eink_power_YYYYMMDD_HHMMSS.log`

CSV columns:
- `timestamp`: Full timestamp
- `current_A`: Raw current in amperes
- `power_W`: Calculated power in watts
- `current_readable`: Human-readable current
- `power_readable`: Human-readable power

## Firmware Optimization Workflow

### 1. Baseline Measurement
Before implementing power optimizations:
```bash
ssh michael-laptop
./power_monitor.sh 2 600  # 10-minute baseline
```

### 2. Deploy Optimized Build
Flash new firmware to E-Ink board and restart monitoring:
```bash
./power_monitor.sh 2 600  # 10-minute optimized measurement
```

### 3. Comparative Analysis
Compare log files to quantify power reduction:
- **Target**: 50-80% power reduction
- **Goal**: 5-year battery life capability
- **Baseline**: Previous build measurements
- **Optimized**: Current build measurements

### 4. Power State Analysis
Monitor different operational states:
- **Boot sequence**: Power consumption during startup
- **WiFi connection**: Network initialization power
- **Idle state**: Background power consumption
- **E-Ink update**: Display refresh power usage
- **Sleep mode**: Suspend/resume power levels

## Manual SCPI Commands

For advanced debugging, direct SCPI commands can be sent:

```bash
# Get device identification
echo '*IDN?' | nc -w 5 192.168.1.116 5025

# Get current reading
echo 'READ?' | nc -w 5 192.168.1.116 5025

# Check measurement configuration
echo 'CONF?' | nc -w 5 192.168.1.116 5025

# Set measurement range (if needed)
echo 'CONF:CURR 0.1' | nc -w 5 192.168.1.116 5025
```

## Power Optimization Targets

### Current Measurements (Build 2097)
- **Baseline**: ~10 nA (very low, possibly sleep mode)
- **Expected Active**: 10-100 mA depending on activity
- **Target Reduction**: 50-80% from baseline active power

### Battery Life Estimation
For 5Ah battery capacity:
- **Current draw**: Measured average current
- **Battery life**: 5Ah / average_current_A = hours
- **Target**: 5+ years (43,800+ hours)
- **Required**: < 114 µA average current

### Key Optimization Areas
1. **CPU Frequency Scaling**: 30-50% reduction potential
2. **WiFi Power Management**: 15-25% reduction potential  
3. **Filesystem Optimizations**: 10-20% reduction potential
4. **Service Optimizations**: 5-10% reduction potential

## Troubleshooting

### Connection Issues
```bash
# Test meter connectivity
ping 192.168.1.116

# Test SCPI interface
echo '*IDN?' | nc -w 5 192.168.1.116 5025
```

### Measurement Issues
- **Very low readings (nA)**: Board may be in sleep mode or disconnected
- **No readings**: Check meter configuration and connections
- **Erratic readings**: Verify stable power supply and connections

### Script Issues
- **Python errors**: Ensure python3 is available on monitoring laptop
- **Network timeouts**: Check network connectivity to meter
- **Permission errors**: Ensure script is executable (`chmod +x power_monitor.sh`)

## Integration with Build Process

### Automated Testing
Power monitoring can be integrated into the build validation process:

1. **Pre-deployment**: Baseline measurement of current build
2. **Post-deployment**: Optimized measurement of new build  
3. **Validation**: Automatic comparison and reporting
4. **Decision**: GO/NO-GO based on power reduction targets

### Continuous Monitoring
For long-term validation:
```bash
# 24-hour continuous monitoring
./power_monitor.sh 60 1440  # 1-minute intervals for 24 hours
```

This enables validation of:
- Power consumption over full operational cycles
- Battery life projections under real usage
- Thermal stability and power efficiency
- Sleep/wake cycle optimization

---

**Last Updated**: October 4, 2025  
**Build Context**: Build 2098 power optimization validation  
**Target**: 5-year battery life achievement through 50-80% power reduction
