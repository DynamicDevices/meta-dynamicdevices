# Power Optimization Master Plan - imx93-jaguar-eink
## 5-Year Battery Life Target

### 📊 **Current Status & Findings**

#### Live Board Investigation Results (192.168.0.36)
- **Board**: imx93-jaguar-eink (Linux 6.6.52-lmp-standard)
- **SSH Access**: Configured with key authentication
- **Temperature**: Stable 41-43°C

#### Critical Issues Found
- ❌ **No CPU frequency scaling** - major power waste (CPU at fixed high frequency)
- ❌ **Unnecessary services**: Docker/Containerd, Bluetooth, ModemManager
- ✅ **Good features**: ZRAM swap (1.8GB), WiFi power management ON, Runtime PM auto

#### Immediate Optimizations Applied
- **Disabled services**: Docker, Bluetooth, ModemManager
- **Estimated savings**: 15-25% total system power
- **Note**: Docker may need re-enabling for Foundries.io operations

### 🔧 **Implemented Power Optimizations**

#### 1. CPU Power Management ✅
- **powersave governor** as default
- **CPU frequency scaling** enabled
- **CPU idle states**: WFI, cpu-pd-wait available
- **Expected savings**: 30-50% CPU power reduction

#### 2. Dynamic Voltage/Frequency Scaling (DVFS) ✅
- **Device frequency scaling** enabled
- **DDR frequency scaling** with powersave governor
- **Regulator support** for voltage scaling (PCA9450 PMIC)

#### 3. WiFi Power Management ✅
- **Built-in WiFi** for immediate availability (critical path optimization)
- **Power management enabled** on all interfaces
- **Application-controlled cycling**: `wifi-power-control.sh` (placeholder)

#### 4. Peripheral Power Optimization ✅
- **Unused subsystems disabled**: audio, video, input, CAN, legacy hardware
- **Runtime PM enabled** for active peripherals
- **Network filesystems disabled**

#### 5. Memory Power Optimization ✅
- **ZRAM enabled** for compressed swap
- **ZSWAP enabled** for memory compression
- **CMA reduced** to 16MB (from 32MB)
- **Power-hungry features disabled**: compaction, migration, KSM, transparent hugepages

#### 6. E-Ink Workflow Optimization ✅
- **WiFi priority boot**: Immediate network availability
- **Delayed components**: Non-essential services load after WiFi
- **Kernel command line**: `cpufreq.default_governor=powersave nohz=on rcu_nocbs=0-3`

### 📋 **Planning Questions & Next Steps**

#### Power Measurement & Validation
1. **Power profiling script**: Should we develop automated power measurement tools for deployed boards?
2. **Battery specifications**: What's the target battery capacity? (mAh/Wh)
3. **Baseline measurements**: Need actual power consumption data (idle, active, sleep states)
4. **Environmental factors**: Temperature impact on power consumption?

#### E-Ink Specific Optimization
5. **Update frequency**: What's the target update pattern? (hourly/daily/on-demand)
6. **Display power characteristics**: Power consumption during E-Ink refresh cycles?
7. **Sleep optimization**: How long between update cycles? Deep sleep feasibility?
8. **WiFi cycling implementation**: Complete the `wifi-power-control.sh` script functionality

#### Advanced Power Management
9. **Dynamic optimization**: Voltage scaling based on workload patterns?
10. **Predictive management**: Adjust behavior based on battery level?
11. **Peripheral gating**: Which hardware can be completely powered off?
12. **Temperature optimization**: Slower clocks in hot conditions?

#### Hardware Integration
13. **Microcontroller timeline**: When will separate low-power MCU be implemented?
14. **Hardware power rails**: Which components can be independently controlled?
15. **Wake sources**: What events should wake the system from deep sleep?

### 🎯 **Power Budget Analysis**

#### Target Calculations
- **5-year operation**: 43,800 hours total
- **Duty cycle optimization**: Minimize active time, maximize sleep time
- **Update workflow**: wake → WiFi → download → WiFi off → display → sleep

#### Power States (Estimates - Need Validation)
- **Active (WiFi + CPU)**: ~2-5W (needs measurement)
- **Display update**: ~1-3W during refresh (needs measurement)  
- **Idle (optimized)**: ~0.5-1W (target with our optimizations)
- **Deep sleep**: ~0.01-0.1W (target with microcontroller)

### 🔄 **E-Ink Workflow Power Optimization**

#### Current Workflow
1. **Boot + WiFi**: Immediate network connectivity (optimized)
2. **Image check/download**: Network operations (WiFi power managed)
3. **WiFi disable**: Application-controlled power cycling
4. **Display update**: E-Ink refresh (hardware-dependent)
5. **Sleep/off**: Low power state until next cycle

#### Optimization Opportunities
- **Boot time**: Minimize time to WiFi connectivity
- **Network efficiency**: Batch operations, compression
- **Display optimization**: Partial updates, refresh scheduling
- **Sleep depth**: Maximum power reduction between cycles

### 🚫 **Service Management Strategy**

#### Power vs Functionality Trade-offs
| Service | Power Impact | Foundries.io Need | E-Ink Need | Decision |
|---------|--------------|-------------------|------------|----------|
| Docker | High | Yes (containers) | No | Conditional enable |
| Bluetooth | Medium | No | No | Keep disabled |
| ModemManager | Low | Maybe (cellular) | No | Keep disabled |
| WiFi | High | Yes (updates) | Yes (images) | Keep enabled |

#### Re-enablement Commands
```bash
# For Foundries.io integration when needed
sudo systemctl enable docker containerd
sudo systemctl start docker containerd
```

### 🔮 **Future Microcontroller Integration**

#### Hardware Power Management (TODO)
- **99.9% power reduction** during sleep
- **Complete i.MX93 shutdown** between update cycles
- **Wake scheduling** via low-power MCU
- **Hardware integration** + firmware development required

#### Expected Benefits
- **Sleep power**: <10mW (vs current ~500-1000mW)
- **Battery life**: Dramatic improvement for infrequent updates
- **Reliability**: Hardware watchdog, recovery capabilities

### 📈 **Success Metrics & Real-Time Power Measurement**

#### Coulomb Meter Integration (Hardware: Michael Hull)
- **Hardware present**: Coulomb meter exists on imx93-jaguar-eink board
- **Status**: Currently disabled in firmware - needs enablement
- **Next steps**: Get specifications from Michael Hull (hardware team lead)
- **Goal**: Real-time power feedback during optimization work

#### Real-Time Power Monitoring Framework
```bash
# Power monitoring workflow
baseline_power()           # Measure current consumption
test_optimization()        # Apply change and measure impact  
calculate_savings()        # Quantify improvement
iterate()                  # Try next optimization
```

#### Validation Criteria
1. **CPU frequency scaling**: Verify dynamic frequency changes
2. **Real-time power measurements**: Coulomb meter feedback loop
3. **Battery life modeling**: Extrapolate from measured data
4. **Thermal performance**: Temperature under various loads
5. **Functional verification**: All E-Ink operations work correctly

#### Monitoring Tools
- **Coulomb meter**: Real-time current/power measurement (hardware)
- **Power monitoring scripts**: Automated measurement and feedback
- **Performance validation**: Boot time, network connectivity, display updates
- **Long-term testing**: Extended operation validation

---

### 🔧 **Implementation Status**
- ✅ **Kernel configurations**: All power optimizations applied
- ✅ **Service optimization**: Unnecessary services disabled
- ✅ **Workflow optimization**: WiFi priority, delayed components
- ❌ **Build validation**: Target 2011 mfgtools failed - device tree cm33 node error
- ⏳ **Hardware integration**: Microcontroller power management (future)
- ⏳ **Application integration**: Complete WiFi power cycling script

### 🐦 **Build Debugging Lessons**
- **mfgtools = canary**: Simpler builds fail first, predict main build issues
- **Cancel failed builds early**: Don't waste CI time on builds you know will fail
- **Device tree errors**: Check node references exist in base DTSi files
- **Target 2011 issue**: `&cm33` reference at line 120 doesn't exist in i.MX93
- **Best practice**: Fix root cause immediately and trigger fresh build

*Last Updated: September 21, 2025*
*Contact: info@dynamicdevices.co.uk*

## 🚨 **Multi-Board Compatibility & Revert Strategy**

### **CRITICAL: Never Break Other Boards**
- All changes MUST use machine-specific conditionals (e.g., `:imx93-jaguar-eink`)
- Test that changes don't affect other machines in the project
- Use proper Yocto override syntax in all bbappend files and configs

### **Revert Strategy (Essential)**
1. **Atomic Commits**: Make small, focused commits with clear descriptions
2. **Immediate Monitoring**: Check builds right after commits
3. **Quick Revert**: Use `git revert` or `git reset` to restore working state
4. **Machine Isolation**: Ensure changes are properly scoped to target machine
5. **Build Validation**: Monitor both target machine and other board builds

### **Example Machine-Specific Patterns**
```bash
# Correct: Machine-specific
OSTREE_KERNEL_ARGS:imx93-jaguar-eink ?= "..."
SRC_URI:append:imx93-jaguar-eink = "file://power-optimization.cfg"

# Wrong: Global changes
OSTREE_KERNEL_ARGS ?= "..."  # Affects ALL machines
SRC_URI:append = "file://power-optimization.cfg"  # Affects ALL machines
```

## 🧠 **Memory Management Strategy**

### **Proactive Memory Creation**
- **ALWAYS create memories** when learning something important
- **Immediate capture** - don't wait, record learnings as they happen
- **Two categories**: Global (cross-project) vs Project-specific (Dynamic Devices)

### **Memory Categories**
- **🌍 Global**: Git workflows, debugging patterns, general best practices
- **🎯 Project-specific**: Dynamic Devices hardware, board configurations, specific technologies

### **Memory Rationalization**
- **Periodic review** to remove duplicates and conflicts
- **Newer memories override older ones** when conflicts exist
- **Update or delete** outdated information to keep knowledge base current
- **Optimize for clarity** and usefulness in future work

### **Examples from This Session**
- ✅ **Global**: Submodule push checking for cloud builds
- ✅ **Project-specific**: CM33 confusion pattern on i.MX93
- ✅ **Global**: Multi-board compatibility strategy
- ✅ **Project-specific**: Power optimization for 5-year battery life

## 🧠 **Critical Knowledge Backup (Memory Recovery)**

### **Hardware-Specific Knowledge**
- **i.MX93 GPIO mapping**: Non-logical order - GPIO1=608+x, GPIO2=512+x, GPIO3=544+x, GPIO4=576+x
- **CM33 confusion**: &cm33 node does NOT exist in i.MX93 base device tree - always check DTSi files
- **Coulomb meter**: Present on imx93-jaguar-eink board, needs enablement (contact Michael Hull)

### **Build System Critical Patterns**
- **Submodule push check**: Always verify submodules pushed to Foundries.io before debugging cloud builds
- **mfgtools canary**: Check mfgtools failures first - they predict main build issues
- **Multi-board safety**: Use machine-specific conditionals (:imx93-jaguar-eink) to avoid breaking other boards

### **Power Optimization Strategy**
- **5-year battery life priority**: Power optimization MORE important than boot speed
- **Workflow-specific**: WiFi must be built-in for E-Ink board's wake-update-sleep cycle
- **Security compliance**: Preserve CRA/LmP security features during optimization

### **Development Workflow**
- **kas container scripts**: NEVER use raw kas commands - causes TMPDIR issues
- **Build cache preservation**: NEVER rm -rf build/tmp* - takes hours to rebuild
- **Immediate monitoring**: Check builds right after commits to catch issues early
