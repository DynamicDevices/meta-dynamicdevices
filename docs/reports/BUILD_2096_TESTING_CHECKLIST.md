# Build 2096 Testing Checklist - Exceptional Engineering Validation

## **Pre-Testing Requirements**
- [ ] Build 2096 completed successfully in Foundries.io
- [ ] Board flashed with Build 2096
- [ ] Network connectivity to 192.168.0.36 established
- [ ] SSH access verified (fio@192.168.0.36)

## **Phase 1: Hardware Verification**
**Objective**: Validate all hardware functionality is working correctly

### UART Validation
```bash
# Expected: 3 UARTs (ttyLP0, ttyLP1, ttyLP2)
ls -la /dev/ttyLP*
```
**Success Criteria**: All 3 UARTs present and accessible

### Bluetooth MAYA W2 Validation
```bash
# Expected: No timeout errors, proper initialization
hciconfig -a
dmesg | grep bluetooth | grep -E "(error|fail|timeout)"
```
**Success Criteria**: Bluetooth controller initialized, no critical errors

### WiFi Regulatory Validation
```bash
# Expected: Interface up, regulatory DB loaded
ip addr show wlan0
dmesg | grep "regulatory.db"
```
**Success Criteria**: WiFi interface operational, regulatory compliance active

### SPI1 E-Ink DMA Validation
```bash
# Expected: No DMA channel errors
dmesg | grep "fsl_lpspi.*DMA"
```
**Success Criteria**: SPI1 with DMA channels properly configured

---

## **Phase 2: Power Optimization Validation**
**Objective**: Verify all power optimizations are active and effective

### CPU Frequency Scaling
```bash
# Expected: powersave governor active
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq
```
**Success Criteria**: Powersave governor active, DVFS operational

### Filesystem Optimizations
```bash
# Expected: noatime mount, commit=60, swappiness=10
mount | grep -E "(noatime|commit)"
cat /proc/sys/vm/swappiness
```
**Success Criteria**: All filesystem optimizations active

### WiFi Power Management
```bash
# Expected: Power save enabled, service active
iw dev wlan0 get power_save
systemctl status wifi-power-management --no-pager
```
**Success Criteria**: WiFi power saving active during idle

### Service Optimizations
```bash
# Expected: ModemManager disabled, aktualizr enabled
systemctl is-enabled ModemManager.service || echo "ModemManager disabled ✓"
systemctl is-enabled aktualizr-lite.service && echo "aktualizr enabled ✓"
```
**Success Criteria**: Non-essential services disabled, critical services preserved

---

## **Phase 3: Boot Quality Check**
**Objective**: Verify clean boot with minimal errors

### Error Analysis
```bash
# Expected: Minimal critical errors
dmesg | grep -E "(error|fail|warn)" | head -10
```

### Specific Issue Checks
```bash
# Expected: No conflicts or failures
dmesg | grep -i "pin.*already requested" || echo "No pin conflicts ✓"
dmesg | grep "can't get the TX DMA channel" || echo "No SPI DMA errors ✓"
dmesg | grep "Opcode 0x0c03 failed" || echo "No Bluetooth timeouts ✓"
```
**Success Criteria**: Clean boot, no critical hardware initialization failures

---

## **Phase 4: Power Assessment**
**Objective**: Measure system resources and validate power optimization effectiveness

### System Resources
```bash
# Monitor current system state
uptime
free -h
cat /proc/loadavg
```

### Power Status
```bash
# Check current CPU frequencies and thermal status
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq
cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null || echo "Thermal N/A"
```

### Power Consumption Analysis
**Manual Measurement Required**: 
- Baseline power consumption measurement
- Optimized power consumption measurement  
- Calculate percentage reduction
- Validate 50-80% power reduction target

**Success Criteria**: 50-80% power reduction achieved, 5-year battery life projection met

---

## **Production Deployment Decision Matrix**

### GO Criteria (All must pass):
- [ ] All hardware functional (UARTs, Bluetooth, WiFi, SPI)
- [ ] All power optimizations active
- [ ] Clean boot with no critical errors
- [ ] 50-80% power reduction achieved
- [ ] System stable under normal operation
- [ ] 5-year battery life target achievable

### NO-GO Criteria (Any triggers hold):
- [ ] Critical hardware failure
- [ ] Power optimizations not effective (<30% reduction)
- [ ] Boot errors causing system instability
- [ ] Performance degradation affecting E-Ink workflow
- [ ] Thermal issues or system reliability concerns

---

## **Test Execution Commands**
**Copy-paste ready command sequence for comprehensive testing:**

```bash
# Phase 1: Hardware Verification
echo "=== PHASE 1: HARDWARE VERIFICATION ==="
ls -la /dev/ttyLP*
hciconfig -a && dmesg | grep bluetooth | grep -E "(error|fail|timeout)"
ip addr show wlan0 && dmesg | grep "regulatory.db"
dmesg | grep "fsl_lpspi.*DMA"

# Phase 2: Power Optimization Validation  
echo "=== PHASE 2: POWER OPTIMIZATION VALIDATION ==="
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
mount | grep -E "(noatime|commit)" && cat /proc/sys/vm/swappiness
iw dev wlan0 get power_save && systemctl status wifi-power-management --no-pager
systemctl is-enabled ModemManager.service || echo "ModemManager disabled ✓"
systemctl is-enabled aktualizr-lite.service && echo "aktualizr enabled ✓"

# Phase 3: Boot Quality Check
echo "=== PHASE 3: BOOT QUALITY CHECK ==="
dmesg | grep -E "(error|fail|warn)" | head -10
dmesg | grep -i "pin.*already requested" || echo "No pin conflicts ✓"
dmesg | grep "can't get the TX DMA channel" || echo "No SPI DMA errors ✓"
dmesg | grep "Opcode 0x0c03 failed" || echo "No Bluetooth timeouts ✓"

# Phase 4: Power Assessment
echo "=== PHASE 4: POWER ASSESSMENT ==="
uptime && free -h && cat /proc/loadavg
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq
cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null || echo "Thermal N/A"
```

---

**Framework**: Exceptional Embedded Engineering - Data-driven validation  
**Target**: Production deployment readiness assessment  
**Standard**: Zero tolerance for unverified assumptions
