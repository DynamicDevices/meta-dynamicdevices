# E-Ink Board Power Optimization Testing Plan
## Release Candidate v1.0.0-rc1 - Build 2096

### **🎯 Testing Objectives**
Verify that Build 2096 delivers the complete 5-year battery life solution with all hardware functionality working correctly and maximum power efficiency achieved.

---

## **📋 Pre-Test Setup**

### **Hardware Requirements**
- imx93-jaguar-eink board
- Power measurement equipment (if available)
- Serial console access
- WiFi network access
- SSH connectivity

### **Software Requirements**
- Build 2096 deployed to target board
- SSH access configured
- Serial console monitoring capability

### **Test Environment**
- Network: WiFi connectivity required
- Power: Battery or external power with measurement capability
- Console: Serial console access via `/dev/ttyLP0`

---

## **🔧 PHASE 1: Hardware Functionality Verification**

### **1.1 Serial Port Functionality**
**Objective**: Verify all 3 UART devices are present and functional

**Test Steps**:
```bash
# Check UART devices exist
ls -la /dev/ttyLP*
# Expected: /dev/ttyLP0, /dev/ttyLP1, /dev/ttyLP2

# Verify console UART (ttyLP0)
dmesg | grep "44380000.serial"
# Expected: Console UART working

# Check Bluetooth UART (ttyLP1) - may not appear in /dev (consumed by Bluetooth)
dmesg | grep "42590000.serial" 
# Expected: LPUART5 initialized for Bluetooth

# Verify PMU UART (ttyLP2) 
echo "test" > /dev/ttyLP2 2>/dev/null && echo "PMU UART accessible" || echo "PMU UART issue"
# Expected: PMU UART accessible for userspace
```

**Success Criteria**: 
- ✅ `/dev/ttyLP0` present (console)
- ✅ `/dev/ttyLP2` present (PMU - MCXC143VFM)
- ✅ LPUART5 initialized for Bluetooth (may not appear in /dev)
- ✅ No "serial out of range" errors in dmesg

### **1.2 Bluetooth Functionality**
**Objective**: Verify MAYA W2 Bluetooth works without timeout errors

**Test Steps**:
```bash
# Check Bluetooth service status
systemctl status bluetooth --no-pager

# Check HCI interface
hciconfig -a

# Look for Bluetooth errors (should be none)
dmesg | grep -i bluetooth | grep -E "(error|fail|timeout)"
# Expected: No timeout errors (Opcode 0x0c03 failed: -110 should be gone)

# Check Bluetooth initialization
journalctl -u bluetooth --no-pager | tail -10
```

**Success Criteria**:
- ✅ Bluetooth service active
- ✅ HCI interface present (hci0)
- ✅ No "Opcode 0x0c03 failed: -110" errors
- ✅ No "Setting wake-up method failed" errors

### **1.3 WiFi Functionality**
**Objective**: Verify WiFi connectivity and regulatory database

**Test Steps**:
```bash
# Check WiFi interface
ip addr show wlan0

# Check for regulatory database errors (should be none)
dmesg | grep "regulatory.db"
# Expected: No "failed to load regulatory.db" errors

# Test WiFi connectivity
ping -c 3 8.8.8.8

# Check WiFi power management status
/usr/bin/wifi-power-management.sh status
```

**Success Criteria**:
- ✅ WiFi interface up and connected
- ✅ No regulatory database errors
- ✅ Internet connectivity working
- ✅ WiFi power management service active

### **1.4 SPI/E-Ink Display**
**Objective**: Verify SPI1 functionality for E-Ink display

**Test Steps**:
```bash
# Check for SPI DMA errors (should be none)
dmesg | grep "fsl_lpspi.*DMA"
# Expected: No "can't get the TX DMA channel" errors

# Check SPI device
ls -la /dev/spidev*

# Verify SPI1 configuration
cat /sys/class/spi_master/spi1/device/modalias 2>/dev/null || echo "SPI1 info not available"
```

**Success Criteria**:
- ✅ No SPI DMA channel errors
- ✅ SPI devices present
- ✅ Clean SPI initialization in dmesg

---

## **⚡ PHASE 2: Power Optimization Verification**

### **2.1 CPU Frequency Scaling**
**Objective**: Verify CPU frequency scaling is active and working

**Test Steps**:
```bash
# Check CPU frequency scaling is available
ls /sys/devices/system/cpu/cpu*/cpufreq/

# Check current governor (should be powersave)
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Check available frequencies
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_available_frequencies

# Monitor frequency changes under load
watch -n 1 'cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq'
# Run some CPU load and observe frequency scaling
```

**Success Criteria**:
- ✅ CPU frequency scaling directories present
- ✅ Powersave governor active by default
- ✅ Multiple frequency levels available
- ✅ Frequency scaling responds to load changes

### **2.2 Filesystem Optimizations**
**Objective**: Verify filesystem mount options and I/O optimizations

**Test Steps**:
```bash
# Check mount options
mount | grep -E "(noatime|commit)"
# Expected: noatime and commit=60 options present

# Check I/O scheduler
cat /sys/block/mmcblk*/queue/scheduler
# Expected: mq-deadline or deadline selected

# Check VM settings
cat /proc/sys/vm/swappiness
# Expected: 10 (reduced from default 60)

cat /proc/sys/vm/dirty_expire_centisecs
# Expected: 6000 (60 seconds)

# Verify filesystem optimizations service
systemctl status filesystem-optimizations --no-pager
```

**Success Criteria**:
- ✅ noatime mount option active
- ✅ commit=60 for batched writes
- ✅ Optimized I/O scheduler (mq-deadline/deadline)
- ✅ Reduced swappiness (10)
- ✅ Filesystem optimizations service active

### **2.3 WiFi Power Management**
**Objective**: Verify WiFi power saving is active

**Test Steps**:
```bash
# Check WiFi power management service
systemctl status wifi-power-management --no-pager

# Check WiFi power saving status
iw dev wlan0 get power_save
# Expected: Power save: on

# Test power management script
/usr/bin/wifi-power-management.sh status

# Check for power management in iwconfig (if available)
iwconfig wlan0 | grep -i power || echo "iwconfig power info not available"
```

**Success Criteria**:
- ✅ WiFi power management service active
- ✅ Power saving enabled (iw shows "Power save: on")
- ✅ WiFi power management script working

### **2.4 Service Optimizations**
**Objective**: Verify unnecessary services are disabled

**Test Steps**:
```bash
# Check service optimization service
systemctl status service-optimizations --no-pager

# Verify unnecessary services are disabled
systemctl is-enabled ModemManager.service || echo "ModemManager disabled (good)"
systemctl is-enabled ninfod.service || echo "ninfod disabled (good)"
systemctl is-enabled rdisc.service || echo "rdisc disabled (good)"
systemctl is-enabled sysstat.service || echo "sysstat disabled (good)"

# Verify critical services are still enabled
systemctl is-enabled aktualizr-lite.service && echo "aktualizr-lite enabled (good)"
systemctl is-enabled NetworkManager.service && echo "NetworkManager enabled (good)"
systemctl is-enabled bluetooth.service && echo "bluetooth enabled (good)"
systemctl is-enabled docker.service && echo "docker enabled (good)"

# Count total running services
systemctl list-units --type=service --state=running --no-pager | wc -l
```

**Success Criteria**:
- ✅ Service optimizations service active
- ✅ Unnecessary services disabled (ModemManager, ninfod, rdisc, sysstat)
- ✅ Critical services still enabled (aktualizr-lite, NetworkManager, bluetooth, docker)
- ✅ Reduced total service count

---

## **🚫 PHASE 3: Error-Free Boot Verification**

### **3.1 Boot Error Analysis**
**Objective**: Verify clean boot with no errors or warnings

**Test Steps**:
```bash
# Check for any boot errors
dmesg | grep -E "(error|Error|ERROR|fail|Fail|FAIL|warn|Warn|WARN)" | head -20

# Specific checks for previously fixed issues:

# 1. No pin conflicts
dmesg | grep -i "pin.*already requested" || echo "No pin conflicts (good)"

# 2. No SPI DMA errors  
dmesg | grep "can't get the TX DMA channel" || echo "No SPI DMA errors (good)"

# 3. No GPT errors
dmesg | grep "GPT.*error" || echo "No GPT errors (good)"

# 4. No regulatory database errors
dmesg | grep "failed to load regulatory.db" || echo "No regulatory DB errors (good)"

# 5. No Bluetooth timeout errors
dmesg | grep "Opcode 0x0c03 failed" || echo "No Bluetooth timeout errors (good)"
```

**Success Criteria**:
- ✅ No pin conflict errors
- ✅ No SPI DMA channel errors
- ✅ No GPT partition table errors
- ✅ No WiFi regulatory database errors
- ✅ No Bluetooth timeout errors
- ✅ Minimal or no warnings in dmesg

### **3.2 System Health Check**
**Objective**: Verify overall system stability and health

**Test Steps**:
```bash
# Check for failed services
systemctl --failed --no-pager

# Check system load and memory
uptime
free -h

# Check disk usage
df -h

# Verify container functionality
docker ps

# Check Foundries.io connectivity
systemctl status aktualizr-lite --no-pager
```

**Success Criteria**:
- ✅ No failed systemd services
- ✅ Low system load average
- ✅ Reasonable memory usage
- ✅ Sufficient disk space
- ✅ Docker containers running
- ✅ Foundries.io updates working

---

## **🔋 PHASE 4: Power Consumption Testing**

### **4.1 Power Measurement (if equipment available)**
**Objective**: Measure actual power consumption improvements

**Test Steps**:
```bash
# Baseline measurement
# 1. Measure idle power consumption
# 2. Measure active WiFi power consumption  
# 3. Measure CPU load power consumption

# Compare with previous builds if data available
# Expected: 50-80% reduction in power consumption

# Monitor power-related metrics
cat /sys/class/power_supply/*/capacity 2>/dev/null || echo "Battery info not available"
cat /sys/class/power_supply/*/status 2>/dev/null || echo "Power status not available"
```

**Success Criteria**:
- ✅ Significant power reduction vs baseline
- ✅ Power consumption within 5-year battery life targets
- ✅ Power management features active

### **4.2 Thermal Performance**
**Objective**: Verify thermal management is working

**Test Steps**:
```bash
# Check thermal zones
ls /sys/class/thermal/thermal_zone*/

# Monitor temperatures
cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null || echo "Thermal info not available"

# Check thermal policies
cat /sys/class/thermal/thermal_zone*/policy 2>/dev/null || echo "Thermal policy info not available"

# Verify thermal management under load
# Run CPU stress test and monitor temperatures
```

**Success Criteria**:
- ✅ Thermal zones detected
- ✅ Reasonable operating temperatures
- ✅ Thermal throttling working if needed

---

## **📊 PHASE 5: Performance Validation**

### **5.1 Boot Time Analysis**
**Objective**: Verify boot optimizations are effective

**Test Steps**:
```bash
# Check boot time (if systemd-analyze available)
systemd-analyze 2>/dev/null || echo "systemd-analyze not available"

# Check kernel command line optimizations
cat /proc/cmdline
# Expected: quiet, fastboot, powersave governor, etc.

# Monitor boot process via serial console
# Time from power-on to login prompt
```

**Success Criteria**:
- ✅ Fast boot time achieved
- ✅ Boot optimizations active
- ✅ Clean boot process

### **5.2 Network Performance**
**Objective**: Verify WiFi performance with power management

**Test Steps**:
```bash
# Test WiFi throughput
# Download speed test
wget -O /dev/null http://speedtest.wdc01.softlayer.com/downloads/test10.zip

# Ping latency test
ping -c 10 8.8.8.8

# Check WiFi signal strength
iwconfig wlan0 | grep -E "(Signal|Quality)" || echo "WiFi signal info not available"
```

**Success Criteria**:
- ✅ Acceptable download speeds
- ✅ Low ping latency
- ✅ Good WiFi signal strength
- ✅ Power management not significantly impacting performance

---

## **✅ PHASE 6: Integration Testing**

### **6.1 E-Ink Workflow Simulation**
**Objective**: Test the complete E-Ink board workflow

**Test Steps**:
```bash
# Simulate E-Ink update workflow:
# 1. Wake from low power
# 2. Connect to WiFi
# 3. Download image update
# 4. Process image
# 5. Return to low power

# Test PMU communication
echo "test_command" > /dev/ttyLP2 && echo "PMU UART communication working"

# Test SPI communication (if tools available)
# Verify E-Ink display SPI interface

# Monitor power consumption during workflow
```

**Success Criteria**:
- ✅ Complete workflow executes successfully
- ✅ PMU UART communication working
- ✅ SPI interface functional
- ✅ Power optimization active throughout workflow

### **6.2 Long-term Stability Test**
**Objective**: Verify system stability over extended operation

**Test Steps**:
```bash
# Run system for extended period (several hours minimum)
# Monitor for:
# - Memory leaks
# - Service failures
# - Hardware issues
# - Power consumption stability

# Check system uptime and stability
uptime
cat /proc/loadavg

# Monitor logs for issues
journalctl --since "1 hour ago" | grep -E "(error|fail|warn)" | wc -l
```

**Success Criteria**:
- ✅ System stable over extended operation
- ✅ No memory leaks or resource exhaustion
- ✅ Consistent power consumption
- ✅ No recurring errors or warnings

---

## **📋 Test Results Summary Template**

### **Hardware Functionality Results**
- [ ] All UARTs present and functional
- [ ] Bluetooth working without timeout errors
- [ ] WiFi connectivity and regulatory database working
- [ ] SPI/E-Ink interface functional

### **Power Optimization Results**
- [ ] CPU frequency scaling active (Governor: _____)
- [ ] Filesystem optimizations applied (noatime: _____, commit: _____)
- [ ] WiFi power management active (Power save: _____)
- [ ] Service optimizations applied (Services disabled: _____)

### **Boot Quality Results**
- [ ] No pin conflict errors
- [ ] No SPI DMA errors
- [ ] No GPT partition errors
- [ ] No regulatory database errors
- [ ] No Bluetooth timeout errors
- [ ] Boot time: _____ seconds

### **Power Consumption Results**
- [ ] Idle power consumption: _____ mW
- [ ] Active power consumption: _____ mW
- [ ] Power savings vs baseline: _____%
- [ ] Estimated battery life: _____ years

### **Overall Assessment**
- [ ] **PASS**: Ready for production deployment
- [ ] **CONDITIONAL**: Minor issues need addressing
- [ ] **FAIL**: Major issues require fixes

---

## **🚀 Success Criteria for Release**

**The E-Ink Board Power Optimization v1.0.0-rc1 is considered successful if:**

1. ✅ **All hardware functionality working** (UARTs, Bluetooth, WiFi, SPI)
2. ✅ **Clean boot with no errors** (pin conflicts, DMA, GPT, regulatory, Bluetooth)
3. ✅ **Power optimizations active** (CPU scaling, FS opts, WiFi mgmt, service opts)
4. ✅ **50-80% power reduction achieved** (measured or estimated)
5. ✅ **System stability confirmed** (extended operation without issues)
6. ✅ **5-year battery life target achievable** (based on power measurements)

**If all criteria are met, this release candidate is approved for production deployment.**

---

**Testing Team**: ________________  
**Test Date**: ________________  
**Build Version**: 2096  
**Release Candidate**: v1.0.0-rc1-eink-power-optimization  
**Board Serial**: ________________
