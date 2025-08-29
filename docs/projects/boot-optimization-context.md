# Boot Time Optimization Context

**Target**: 1-2 second boot time for Dynamic Devices Edge boards
**GitHub**: [Boot Optimization Issues](https://github.com/DynamicDevices/meta-dynamicdevices/labels/boot-optimization)

## Current Status ✅
- **Profiling System**: Comprehensive measurement tools implemented
- **Target Boards**: i.MX93 Jaguar E-Ink, i.MX8MM Jaguar Sentai
- **Measurement Phase**: Complete - tools ready for baseline analysis

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
- **Automatic**: `boot-profiling.service` runs at each boot
- **Manual**: `boot-analysis.sh` for comprehensive reports
- **Interactive**: `profile-boot.sh --live` for monitoring
- **Reports**: Saved to `/var/log/boot-profiling/`

## Optimization Strategy

### Phase 1: Measurement ✅
- [x] Implement profiling tools
- [x] Enable detailed timing
- [ ] Establish baseline measurements
- [ ] Identify bottlenecks

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

### Baseline (To be measured)
```
Board: [TBD]
U-Boot: [TBD]s
Kernel: [TBD]s  
Systemd: [TBD]s
Total: [TBD]s
```

### Bottlenecks Identified
- [ ] U-Boot delays: [TBD]
- [ ] Slow drivers: [TBD]
- [ ] Service dependencies: [TBD]
- [ ] Storage access: [TBD]

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

### Build Commands
```bash
# Enable profiling
export ENABLE_BOOT_PROFILING=1
./scripts/build-with-boot-profiling.sh imx93-jaguar-eink

# Standard build with profiling
export ENABLE_BOOT_PROFILING=1
kas build kas/lmp-dynamicdevices.yml
```

### Analysis Commands
```bash
# Comprehensive analysis
boot-analysis.sh

# Systemd analysis
systemd-analyze
systemd-analyze blame
systemd-analyze critical-chain

# Live monitoring
profile-boot.sh --live

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

### Tools
- `recipes-support/boot-profiling/`: Boot profiling recipe
- `scripts/build-with-boot-profiling.sh`: Build convenience script
- `docs/BOOT_PROFILING.md`: Comprehensive documentation

### Runtime
- `/usr/bin/boot-analysis.sh`: Analysis script
- `/usr/bin/profile-boot.sh`: Interactive profiling
- `/var/log/boot-profiling/`: Report storage
- `/etc/systemd/system/boot-profiling.service`: Auto-analysis

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

## Success Metrics
- **Development builds**: < 5s (with debug enabled)
- **Production builds**: < 2s (optimized configuration)
- **Suspend/resume**: < 1s (from suspend state)
- **Consistency**: < 10% variation between boots

## Lessons Learned

### Measurement Insights
- [TBD after initial measurements]

### Optimization Results
- [TBD after implementing optimizations]

### Board-Specific Findings
- [TBD based on per-board analysis]

---
*Last Updated: 2024-12-19*
*Status: 🔧 PROFILING TOOLS READY - Ready for baseline measurement phase*
