# Boot Profiling for Dynamic Devices Boards

## Overview

Comprehensive boot time analysis and optimization system for Dynamic Devices Edge boards. **Target: 1-2 second total boot time**.

## Quick Start

### Serial Boot Logging (Recommended) ✅

For complete boot analysis including pre-network timing:

#### U-Boot Recipe Architecture

The project uses three different U-Boot recipes for different purposes:

**Local Development & Production Builds**
- **Recipe**: `u-boot-fio_%.bbappend` 
- **Used by**: Both local `kas build` and Foundries.io cloud builds
- **Optimizations**: Ethernet removal, reduced boot delay, ELE commands
- **Key insight**: Same recipe applies to both local and production builds

**Manufacturing/Programming**
- **Recipe**: `u-boot-fio-mfgtool_%.bbappend`
- **Used by**: UUU board programming only
- **Special config**: SE050 disabled for programming compatibility
- **Optimizations**: Not needed (brief usage during programming)

**Boot Scripts**
- **Recipe**: `u-boot-ostree-scr-fit.bbappend`
- **Used by**: Foundries.io builds for boot command scripts
- **Contains**: Only `boot.cmd` files, not U-Boot configuration
- **Optimizations**: `setenv silent 1` for reduced output

#### Serial Logging Usage

```bash
# Complete workflow - capture and analyze
./scripts/boot-timing-suite.sh capture --name board-test
# Power cycle board, wait for boot completion
./scripts/boot-timing-suite.sh latest

# Continuous monitoring
./scripts/boot-timing-suite.sh monitor --name consistency-test

# Compare multiple boots
./scripts/boot-timing-suite.sh compare
```

### On-Target Boot Profiling

For detailed post-boot analysis:

```bash
# Set environment variable
export ENABLE_BOOT_PROFILING=1

# Build with profiling enabled
export KAS_MACHINE=imx93-jaguar-eink  # or imx8mm-jaguar-sentai
kas build kas/lmp-dynamicdevices.yml

# Or use the convenience script
./scripts/build-with-boot-profiling.sh imx93-jaguar-eink
```

### Analyze Boot Performance

After flashing and booting:

```bash
# Automatic analysis (runs at boot)
systemctl status boot-profiling

# Manual comprehensive analysis
boot-analysis.sh

# Quick systemd analysis
systemd-analyze
systemd-analyze blame
systemd-analyze critical-chain

# Live monitoring
profile-boot.sh --live

# Generate boot plot
profile-boot.sh --save-plot
```

## What Gets Enabled

### U-Boot Optimizations
- **Boot timing**: `CONFIG_BOOTSTAGE=y` with detailed reporting
- **Fast boot**: `CONFIG_BOOTDELAY=0` (no boot delay)
- **Size optimization**: `CONFIG_LTO=y` for smaller, faster U-Boot
- **Progress reporting**: `CONFIG_SHOW_BOOT_PROGRESS=y`

### Kernel Profiling
- **Timing information**: `CONFIG_PRINTK_TIME=y` for timestamped logs
- **Initcall debugging**: `CONFIG_INITCALL_DEBUG=y` for detailed driver timing
- **Performance events**: `CONFIG_PERF_EVENTS=y` for detailed profiling
- **Scheduler stats**: `CONFIG_SCHEDSTATS=y` for process timing

### Systemd Analysis
- **systemd-analyze**: Built-in boot time analysis
- **Service timing**: Detailed service startup analysis
- **Critical path**: Dependency chain analysis
- **Boot plotting**: SVG timeline generation

### Analysis Tools
- **boot-analysis.sh**: Comprehensive boot report generation
- **profile-boot.sh**: Interactive boot profiling
- **Automatic service**: Runs analysis at each boot
- **Performance tools**: strace, perf, iotop, htop

## Boot Time Breakdown

### Target Timing (1-2s total)
```
U-Boot:    < 0.5s  (bootloader, hardware init)
Kernel:    < 1.0s  (kernel init, driver loading)
Systemd:   < 0.5s  (service startup, user space)
Total:     < 2.0s  (power-on to login prompt)
```

### Current Baseline - i.MX93 Jaguar E-Ink (2025-01-09)
```
U-Boot:    4.7s   (includes 3s autoboot delay) ❌ SLOW
Kernel:    3.4s   (Linux initialization) ⚠️  MODERATE
Systemd:   0.1s   (service startup) ✅ GOOD
Total:     22.7s  (15x over target) ❌ CRITICAL
```

### Optimization Attempt Results (2025-01-15)
```
Previous:  23.266s total (2.879s U-Boot, 15.207s Kernel+Systemd)
Current:   22.936s total (2.884s U-Boot, 15.029s Kernel+Systemd)
Improvement: 0.33s (1.4%) - MINIMAL IMPACT ❌
Issue: U-Boot optimizations not showing expected results
```

**Primary Bottlenecks Identified:**
- **U-Boot autoboot delay**: 3s (easy fix with bootdelay=0)
- **U-Boot initialization**: 1.7s excess (config optimization needed)
- **Kernel boot time**: 3.4s (optimizable with built-in drivers)

### Typical Bottlenecks
1. **U-Boot delays**: Boot menu timeouts, environment loading
2. **Driver initialization**: WiFi, storage, USB enumeration
3. **Filesystem mounting**: Root filesystem and overlays
4. **Service dependencies**: Unnecessary service chains
5. **Console output**: Verbose logging during boot

## Analysis Reports

### Boot Analysis Report
Generated automatically and saved to `/var/log/boot-profiling/boot-analysis-TIMESTAMP.txt`:

```
=== Dynamic Devices Boot Analysis Report ===
Generated: 2024-01-15 10:30:00
Target: 1-2 second total boot time

=== BOOT TIME SUMMARY ===
Kernel boot time: 1.234s (from 0.000s to 1.234s)
Systemd boot analysis:
Startup finished in 2.345s (kernel) + 1.678s (userspace) = 4.023s

=== U-BOOT ANALYSIS ===
[Detailed U-Boot timing information]

=== KERNEL INITIALIZATION ANALYSIS ===
[Driver and subsystem timing]

=== SYSTEMD SERVICE ANALYSIS ===
[Service startup timing and critical path]

=== BOOT OPTIMIZATION RECOMMENDATIONS ===
[Specific optimization suggestions]
```

### Live Monitoring
```bash
profile-boot.sh --live
```
Shows real-time boot analysis with continuous updates.

## Optimization Strategies

### U-Boot Optimizations
1. **Reduce boot delay**: `bootdelay=0` in environment
2. **Minimize environment**: Remove unused variables
3. **Fast storage**: Use eMMC instead of SD cards
4. **Skip unnecessary init**: Optimize hardware initialization

### Kernel Optimizations
1. **Built-in drivers**: Compile critical drivers into kernel (not modules)
2. **Minimal config**: Disable unused subsystems and drivers
3. **Quiet boot**: Use `quiet` kernel parameter to reduce console output
4. **Initramfs**: Use initramfs for faster root filesystem access
5. **Driver order**: Optimize driver initialization order

### Systemd Optimizations
1. **Disable services**: Remove unnecessary systemd services
2. **Parallel startup**: Optimize service dependencies for parallel execution
3. **Fast targets**: Use minimal boot targets
4. **Service timeouts**: Reduce service startup timeouts

### Hardware-Specific
1. **Device tree**: Minimize device tree to essential hardware only
2. **Clock speeds**: Use maximum safe clock frequencies
3. **Memory timing**: Optimize DDR initialization
4. **Storage**: Use fastest available storage interface

## Board-Specific Configurations

### i.MX93 Jaguar E-Ink
- **Optimized for**: Low-power e-ink applications
- **Key optimizations**: Minimal USB, no audio/video, essential drivers only
- **Target**: < 1.5s boot time for suspend/resume cycles

### i.MX8MM Jaguar Sentai  
- **Optimized for**: Audio processing applications
- **Key optimizations**: Audio drivers built-in, minimal graphics
- **Target**: < 2.0s boot time with audio subsystem ready

## Troubleshooting

### Common Issues

#### Slow Boot Despite Optimizations
```bash
# Check for slow services
systemd-analyze blame | head -10

# Check critical path
systemd-analyze critical-chain

# Look for driver delays
dmesg | grep -E "took.*ms"
```

#### Missing Boot Timing Data
```bash
# Verify kernel config
zcat /proc/config.gz | grep -E "(PRINTK_TIME|INITCALL_DEBUG)"

# Check dmesg buffer size
dmesg | wc -l
```

#### U-Boot Timing Not Available
- Check U-Boot configuration includes `CONFIG_BOOTSTAGE=y`
- Verify early console is working
- Look for U-Boot messages in dmesg

### Debug Commands
```bash
# Detailed kernel timing
dmesg -T | grep -E "\[.*\].*took"

# Service analysis
systemctl list-units --failed
systemctl list-units --type=service --state=active

# Hardware timing
cat /proc/uptime
cat /proc/loadavg
```

## Files and Locations

### Configuration Files
- `kas/lmp-dynamicdevices.yml`: KAS environment variable
- `recipes-support/boot-profiling/`: Boot profiling recipe
- `meta-dynamicdevices-bsp/recipes-kernel/linux/*/enable_boot_profiling.cfg`: Kernel configs
- `meta-dynamicdevices-bsp/recipes-bsp/u-boot/*/enable_boot_profiling.cfg`: U-Boot configs

### Runtime Files
- `/usr/bin/boot-analysis.sh`: Comprehensive analysis script
- `/usr/bin/profile-boot.sh`: Interactive profiling tool
- `/var/log/boot-profiling/`: Analysis reports and logs
- `/etc/systemd/system/boot-profiling.service`: Automatic analysis service

### Build Scripts
- `scripts/build-with-boot-profiling.sh`: Convenience build script

### Serial Boot Logging Tools ✅
- `scripts/boot-timing-suite.sh`: Main interface for all boot timing operations
- `scripts/serial-boot-logger.sh`: Serial capture with precise timestamps
- `scripts/analyze-boot-logs.sh`: Detailed log analysis and recommendations
- `scripts/BOOT_TIMING_README.md`: Complete serial logging documentation

## Advanced Usage

### Custom Analysis
```bash
# Generate detailed kernel trace
echo 1 > /sys/kernel/debug/tracing/events/initcall/enable
# Reboot and analyze trace

# Profile specific service
systemd-analyze verify my-service.service
systemd-analyze cat-config my-service.service
```

### Continuous Monitoring
```bash
# Set up boot time monitoring
echo "boot-analysis.sh" >> /etc/rc.local

# Log boot times to file
systemd-analyze >> /var/log/boot-times.log
```

### Integration with CI/CD
```bash
# Build with profiling in CI
export ENABLE_BOOT_PROFILING=1
kas build kas/lmp-dynamicdevices.yml

# Extract boot time from logs
grep "Startup finished" /var/log/boot-profiling/*.txt
```

## Performance Targets

### Acceptable Boot Times
- **Development**: < 5s (with debug enabled)
- **Production**: < 2s (optimized configuration)
- **Suspend/Resume**: < 1s (from suspend state)

### Critical Thresholds
- **U-Boot**: > 1s indicates configuration issues
- **Kernel**: > 2s suggests driver problems
- **Systemd**: > 1s indicates service issues

## Support

For boot optimization support:
- Check analysis reports in `/var/log/boot-profiling/`
- Review systemd service timing with `systemd-analyze blame`
- Examine kernel driver timing in dmesg
- Consider hardware-specific optimizations for your use case
