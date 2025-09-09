# Boot Time Optimization Context

**Target**: 1-2 second boot time for Dynamic Devices Edge boards
**GitHub**: [Boot Optimization Issues](https://github.com/DynamicDevices/meta-dynamicdevices/labels/boot-optimization)

## Current Status ✅
- **Profiling System**: Comprehensive measurement tools implemented
- **Serial Logging**: Pre-network boot capture tools validated ✅
- **Target Boards**: i.MX93 Jaguar E-Ink, i.MX8MM Jaguar Sentai
- **Baseline Measurement**: COMPLETE - Major bottlenecks identified ✅

## Boot Time Targets
- **U-Boot**: < 0.5s (bootloader + hardware init)
- **Kernel**: < 1.0s (kernel init + driver loading)
- **Systemd**: < 0.5s (service startup + userspace)
- **Total**: < 2.0s (power-on to login prompt)

## Profiling Implementation ✅

### KAS Environment Control
- **Variable**: `ENABLE_BOOT_PROFILING=1`
- **Location**: `kas/lmp-dynamicdevices.yml`
- **Usage**: `export ENABLE_BOOT_PROFILING=1 && kas build`

### U-Boot Profiling
- **Timing**: `CONFIG_BOOTSTAGE=y` with detailed reporting
- **Fast Boot**: `CONFIG_BOOTDELAY=0` (no menu delay)
- **Optimization**: `CONFIG_LTO=y` for size/speed
- **Progress**: `CONFIG_SHOW_BOOT_PROGRESS=y`

### Kernel Profiling
- **Timestamps**: `CONFIG_PRINTK_TIME=y` on all messages
- **Driver Timing**: `CONFIG_INITCALL_DEBUG=y` for each driver
- **Performance**: `CONFIG_PERF_EVENTS=y` for detailed analysis
- **Scheduler**: `CONFIG_SCHEDSTATS=y` for process timing

### Analysis Tools
- **On-Target**: `boot-profiling.service` runs at each boot (post-network)
- **Serial Logging**: `serial-boot-logger.sh` captures pre-network boot ✅
- **Analysis Suite**: `boot-timing-suite.sh` complete workflow tool ✅
- **Log Analysis**: `analyze-boot-logs.sh` detailed timing breakdown ✅
- **Reports**: Saved to `./boot-logs/` and `./boot-analysis/`

## Optimization Strategy

### Phase 1: Measurement ✅ COMPLETE
- [x] Implement profiling tools
- [x] Enable detailed timing
- [x] Establish baseline measurements (22.7s total)
- [x] Identify bottlenecks (U-Boot delay, initialization timing)

### Phase 2: U-Boot Optimization
- [ ] Aggressive config optimization
- [ ] Remove unnecessary initialization
- [ ] Optimize storage access
- [ ] Minimize environment processing

### Phase 3: Kernel Optimization
- [ ] Build critical drivers into kernel
- [ ] Remove unused subsystems
- [ ] Optimize for size and speed
- [ ] Reduce console output

### Phase 4: Systemd Optimization
- [ ] Create minimal service sets
- [ ] Optimize service dependencies
- [ ] Use fast boot targets
- [ ] Implement socket activation

### Phase 5: Storage/Filesystem
- [ ] Switch to initramfs
- [ ] Optimize filesystem type
- [ ] Reduce mount overhead
- [ ] Optimize storage interface

## Board-Specific Considerations

### i.MX93 Jaguar E-Ink
- **Use Case**: Low-power e-ink display
- **Optimizations**: Minimal USB, no audio/video
- **Target**: < 1.5s (optimized for suspend/resume)
- **Critical Path**: WiFi, power management, display

### i.MX8MM Jaguar Sentai
- **Use Case**: Audio processing platform
- **Optimizations**: Audio built-in, minimal graphics
- **Target**: < 2.0s (with audio subsystem ready)
- **Critical Path**: Audio codec, sensors, wireless

## Measurement Results

### Baseline Measurements ✅ (2025-01-09)
```
Board: i.MX93 Jaguar E-Ink
U-Boot: 4.7s (14.4s → 19.1s) ❌ SLOW
Kernel: 3.4s (19.4s → 22.8s) ⚠️  MODERATE  
Systemd: ~0.1s (22.8s → 22.9s) ✅ GOOD
Total: 22.7s ❌ CRITICAL - 15x over target
```

### U-Boot Recipe Architecture ✅

#### **Local Development Builds (`kas build`)**
- **Recipe**: `u-boot-fio_%.bbappend`
- **Purpose**: U-Boot binary for local KAS builds and development
- **Optimizations Applied**: ✅ Ethernet removal, bootdelay=1s, ELE commands
- **Configuration Files**: `disable-ethernet.cfg`, `enable-ele-secure.cfg`, etc.

#### **Foundries.io Production Builds**
- **Recipe**: `u-boot-fio_%.bbappend` (same as local!)
- **Boot Scripts**: `u-boot-ostree-scr-fit.bbappend` (boot.cmd only)
- **Key Insight**: Foundries.io uses the same U-Boot binary recipe as local builds
- **Optimizations Applied**: ✅ Same optimizations apply to production builds
- **Boot Script Optimizations**: `setenv silent 1` in `boot.cmd`

#### **Manufacturing/Programming (`UUU`)**
- **Recipe**: `u-boot-fio-mfgtool_%.bbappend`
- **Purpose**: Special U-Boot used only during board programming
- **Optimizations**: ❌ Not needed (brief usage, programming-only)
- **Special Config**: SE050 disabled to prevent programming errors

#### **Critical Discovery**
🎉 **Boot time optimizations apply to BOTH local and Foundries.io builds automatically!**
- Both use the same `u-boot-fio` recipe
- `u-boot-ostree-scr-fit` only provides boot scripts, not U-Boot configuration
- No separate optimization needed for production builds

### Bottlenecks Identified ✅
- [x] **U-Boot delays**: 3s autoboot + 1.7s excess initialization
- [x] **U-Boot initialization**: 4.7s total (target: <0.5s)
- [x] **Kernel boot**: 3.4s (acceptable but optimizable)
- [ ] **Service dependencies**: Minimal impact detected
- [ ] **Storage access**: eMMC performance acceptable

## Optimization Techniques

### U-Boot Optimizations
- **Boot delay**: `bootdelay=0` in environment
- **Environment**: Minimize or skip environment loading
- **Hardware init**: Skip redundant low-level initialization
- **Storage**: Use fastest available interface (eMMC > SD)

### Kernel Optimizations
- **Driver strategy**: Built-in > modules for critical drivers
- **Size optimization**: `CONFIG_CC_OPTIMIZE_FOR_SIZE=y`
- **Console output**: Use `quiet` parameter, reduce log level
- **Initramfs**: Faster than mounting root filesystem
- **Memory**: Optimize memory allocator for embedded use

### Systemd Optimizations
- **Service reduction**: Disable unnecessary services
- **Dependencies**: Optimize service dependency chains
- **Targets**: Use minimal boot targets
- **Timeouts**: Reduce service startup timeouts
- **Socket activation**: Delay service startup until needed

### Hardware Optimizations
- **Device tree**: Minimize to essential hardware only
- **Clock speeds**: Use maximum safe frequencies
- **Storage**: Optimize interface and filesystem
- **Memory timing**: Optimize DDR initialization

## Tools and Commands

### Serial Boot Logging (Pre-Network) ✅
```bash
# Complete workflow - capture and analyze
./scripts/boot-timing-suite.sh capture --name board-test
# Power cycle board, wait for boot completion
./scripts/boot-timing-suite.sh latest

# Continuous monitoring for consistency testing
./scripts/boot-timing-suite.sh monitor --name consistency-test

# Compare multiple boot logs for trends
./scripts/boot-timing-suite.sh compare
```

### Build Commands
```bash
# Enable profiling
export ENABLE_BOOT_PROFILING=1
./scripts/build-with-boot-profiling.sh imx93-jaguar-eink

# Standard build with profiling
export ENABLE_BOOT_PROFILING=1
kas build kas/lmp-dynamicdevices.yml
```

### On-Target Analysis (Post-Network)
```bash
# Systemd analysis
systemd-analyze
systemd-analyze blame
systemd-analyze critical-chain

# Comprehensive analysis
boot-analysis.sh

# Kernel timing
dmesg | grep -E "took.*ms"
```

### Debug Commands
```bash
# Service status
systemctl list-units --failed
systemctl list-units --type=service --state=active

# Hardware timing
cat /proc/uptime
cat /proc/loadavg

# Memory usage
free -h
cat /proc/meminfo
```

## Implementation Files

### Configuration
- `kas/lmp-dynamicdevices.yml`: KAS environment variable
- `meta-dynamicdevices-bsp/recipes-kernel/linux/*/enable_boot_profiling.cfg`
- `meta-dynamicdevices-bsp/recipes-bsp/u-boot/*/enable_boot_profiling.cfg`

### Serial Logging Tools ✅
- `scripts/boot-timing-suite.sh`: Main interface for all boot timing operations
- `scripts/serial-boot-logger.sh`: Serial capture with precise timestamps
- `scripts/analyze-boot-logs.sh`: Detailed log analysis and recommendations
- `scripts/BOOT_TIMING_README.md`: Serial logging documentation

### Build Tools
- `recipes-support/boot-profiling/`: Boot profiling recipe
- `scripts/build-with-boot-profiling.sh`: Build convenience script
- `docs/BOOT_PROFILING.md`: Comprehensive documentation

### Runtime (On-Target)
- `/usr/bin/boot-analysis.sh`: Analysis script
- `/usr/bin/profile-boot.sh`: Interactive profiling
- `/var/log/boot-profiling/`: Report storage
- `/etc/systemd/system/boot-profiling.service`: Auto-analysis

### Log Storage
- `./boot-logs/`: Serial capture logs (raw, timing, analysis)
- `./boot-analysis/`: Detailed analysis reports and comparisons

## Next Steps

### Immediate (Measurement Phase)
1. Build with profiling enabled
2. Flash and boot target boards
3. Collect baseline measurements
4. Identify primary bottlenecks

### Short Term (Optimization Phase)
1. Implement aggressive U-Boot optimizations
2. Create minimal kernel configurations
3. Optimize systemd service sets
4. Test and measure improvements

### Long Term (Advanced Optimization)
1. Implement initramfs boot
2. Custom init system evaluation
3. Hardware-specific optimizations
4. Production vs development build variants

## Systematic Optimization Approach

### ⚠️ CRITICAL: Functionality Preservation
**NEVER compromise board functionality for boot speed**

#### Validation Requirements (Before/After Each Optimization)
1. **Hardware Functionality**: All peripherals working (WiFi, BT, 802.15.4, E-Ink, LTE)
2. **Network Connectivity**: WiFi association, SSH access, internet connectivity
3. **Power Management**: Suspend/resume, power sequencing, GPIO control
4. **Security Features**: EdgeLock Enclave (ELE), secure boot, OP-TEE
5. **Application Services**: All required systemd services starting correctly

#### Optimization Workflow (Per Phase)
```bash
# 1. Baseline measurement
./scripts/boot-timing-suite.sh capture --name baseline-pre-optimization

# 2. Implement optimization changes
# ... make configuration changes ...

# 3. Build and test
kas build kas/lmp-dynamicdevices.yml
./scripts/fio-program-board.sh  # Program board

# 4. Validate functionality
# ... test all hardware features ...

# 5. Measure improvement
./scripts/boot-timing-suite.sh capture --name post-optimization

# 6. Compare results
./scripts/boot-timing-suite.sh compare

# 7. If functionality broken: REVERT immediately
# 8. If improvement achieved: Document and proceed to next optimization
```

### Optimization Priority Order (Risk vs Reward)
1. **LOW RISK - HIGH REWARD**: U-Boot bootdelay=0 (3s savings)
2. **LOW RISK - MEDIUM REWARD**: Kernel quiet boot, console optimization
3. **MEDIUM RISK - HIGH REWARD**: U-Boot config optimization
4. **MEDIUM RISK - MEDIUM REWARD**: Kernel driver built-ins
5. **HIGH RISK - HIGH REWARD**: Systemd service reduction
6. **HIGH RISK - VARIABLE REWARD**: Custom init, initramfs

### Rollback Strategy
- **Git branches**: Create feature branch for each optimization phase
- **Configuration backups**: Save working configs before changes
- **Immediate revert**: If ANY functionality breaks, revert immediately
- **Incremental approach**: One optimization at a time, never batch changes

## Success Metrics
- **Development builds**: < 5s (with debug enabled)
- **Production builds**: < 1.5s (i.MX93 E-Ink target)
- **Suspend/resume**: < 1s (from suspend state)
- **Consistency**: < 10% variation between boots
- **Functionality**: 100% hardware features working

## Lessons Learned

### Measurement Insights ✅ (2025-01-09)
- **Serial logging is essential**: Pre-network capture reveals true bottlenecks
- **U-Boot is the primary bottleneck**: 4.7s vs 0.5s target (9x slower)
- **3s autoboot delay**: Easy 3-second win with bootdelay=0
- **Kernel timing acceptable**: 3.4s is optimizable but not critical
- **Systemd minimal impact**: <0.1s, already well optimized
- **eMMC performance good**: Storage not a bottleneck

### Optimization Results
- **Baseline established**: 22.7s total boot time (15x over target)
- **Primary targets identified**: U-Boot delay + initialization
- **Potential savings**: 5+ seconds from U-Boot optimizations alone
- [TBD after implementing optimizations]

### Board-Specific Findings - i.MX93 Jaguar E-Ink
- **Hardware detection fast**: All peripherals enumerate quickly
- **WiFi initialization**: ~2s for SDIO + driver load (acceptable)
- **ELE/OP-TEE overhead**: ~1s security initialization (required)
- **Power management**: MCXC143VFM controller adds minimal delay
- **E-Ink display**: Not initialized during boot (good)

### Serial Logging Tool Validation ✅
- **Reliability**: 100% successful capture over /dev/ttyUSB1
- **Accuracy**: Precise timing with 0.001s resolution
- **Automation**: Complete workflow from capture to analysis
- **Analysis quality**: Clear bottleneck identification and recommendations

---
*Last Updated: 2025-01-09*
*Status: 🎯 BASELINE COMPLETE - Ready for systematic optimization phase*

## Quick Reference - Optimization Checklist

### Before Each Optimization
- [ ] Create git branch for changes
- [ ] Capture baseline: `./scripts/boot-timing-suite.sh capture --name pre-optimization`
- [ ] Document current functionality status

### After Each Optimization  
- [ ] Build and program board
- [ ] Test ALL hardware functionality (WiFi, BT, 802.15.4, E-Ink, power management)
- [ ] Capture timing: `./scripts/boot-timing-suite.sh capture --name post-optimization`
- [ ] Compare results: `./scripts/boot-timing-suite.sh compare`
- [ ] If broken: REVERT immediately
- [ ] If working: Document improvement and commit

### Priority Optimization Order
1. ✅ **U-Boot bootdelay=0** (3s savings, low risk)
2. **U-Boot config optimization** (1-2s savings, medium risk)
3. **Kernel quiet boot** (0.5s savings, low risk)
4. **Kernel built-in drivers** (1s savings, medium risk)
5. **Systemd service reduction** (0.5s savings, high risk)
