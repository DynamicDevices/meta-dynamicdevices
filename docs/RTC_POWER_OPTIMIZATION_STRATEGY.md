# RTC Power Optimization Strategy for i.MX93 E-Ink Board

## Overview
This document outlines the Real-Time Clock (RTC) power optimization strategy implemented for the i.MX93 E-Ink board to achieve the target 5-year battery life.

## Power Consumption Analysis - ENHANCED WITH DATASHEET VERIFICATION

| RTC Component | Power Consumption | Usage | Datasheet Verified |
|---------------|------------------|-------|-------------------|
| **Internal i.MX93 RTC** | ~100µA | ❌ DISABLED (too high) | ✅ User specification |
| **External PCF2131 RTC** | **83-104nA @ 3.3V** | ✅ PRIMARY (**1,205x** more efficient) | ✅ **Datasheet confirmed** |
| **MCXC143VFM PMU RTC** | Always powered | ✅ WAKE SCHEDULING | ✅ Hardware specification |

### **🎯 CRITICAL DISCOVERY:** 
**Actual PCF2131 power consumption is 83-104nA @ 3.3V**, which is **significantly better** than the original 600nA specification! This provides a **1,205x improvement** over the internal i.MX93 RTC.

## Hardware Architecture

### PCF2131 External RTC
- **I2C Address:** 0x53 on LPI2C3
- **Communication:** GPIO_IO28 (SDA), GPIO_IO29 (SCL)
- **Wake Sources:**
  - **INTA#** → GPIO4_IO22 (MX93_PAD_ENET2_RX_CTL) - Wake i.MX93 from sleep
  - **INTB#** → PTC5/LLWU_P9 (MCXC143VFM) - Wake PMU from low power
- **Power:** VBAT battery backup for continuous operation

### MCXC143VFM PMU Internal RTC
- **Location:** Internal to PMU microcontroller
- **Power:** Always powered (part of PMU)
- **Purpose:** Wake scheduling and time synchronization backup

## Operational Strategy

### 1. Primary Timekeeping (PCF2131)
- i.MX93 uses PCF2131 as primary RTC source
- Always accurate time even when i.MX93 is powered down
- 600nA power consumption enables 5-year battery operation

### 2. Time Synchronization
- When i.MX93 powers up, it reads accurate time from PCF2131
- Periodically syncs time with PMU internal RTC
- Ensures PMU has accurate time for wake scheduling

### 3. Wake Scheduling
- i.MX93 programs wake schedules into PMU before sleep
- PMU can use either:
  - Internal RTC for wake timing
  - PCF2131 INTB# interrupt for precise wake events
- Enables complete i.MX93 power shutdown

### 4. Power Management Modes
- **Active Mode:** i.MX93 + PCF2131 + PMU all active
- **Sleep Mode:** i.MX93 suspended, PCF2131 + PMU maintain time
- **Deep Sleep:** i.MX93 powered off, PCF2131 + PMU maintain time/wake
- **Ultra Deep:** Complete system off except PCF2131 VBAT backup

## Implementation Details

### Device Tree Configuration
```dts
&lpi2c3 {
    pcf2131: rtc@53 {
        compatible = "nxp,pcf2131";
        reg = <0x53>;
        interrupt-parent = <&gpio4>;
        interrupts = <22 IRQ_TYPE_LEVEL_LOW>; /* GPIO4_IO22 - INTA# */
        interrupt-names = "alarm";
        wakeup-source;                         /* Enable wake capability */
    };
};
```

### Kernel Configuration
```bash
# Primary RTC: PCF2131 (600nA)
CONFIG_RTC_DRV_PCF2127=y                 # PCF2131 support
CONFIG_RTC_HCTOSYS=y                     # Use as system time source
CONFIG_RTC_HCTOSYS_DEVICE="rtc0"         # PCF2131 as primary

# Disable high-power internal RTCs (Save ~100µA)
# CONFIG_RTC_DRV_SNVS is not set         # Disable SNVS RTC
# CONFIG_RTC_DRV_BBNSM is not set        # Disable Battery-Backed RTC
# CONFIG_RTC_DRV_IMX_SC is not set       # Disable System Controller RTC
# CONFIG_RTC_DRV_IMX_RPMSG is not set    # Disable RPMSG RTC
```

### Power Savings Calculation - UPDATED WITH DATASHEET VALUES
```
Power Reduction: 100µA → 83nA = 1,205x improvement!
Annual Energy Savings: 
- Old: 100µA × 24h × 365d = 876 mAh/year
- New: 0.083µA × 24h × 365d = 0.73 mAh/year
- Savings: 875.27 mAh/year

With 40Ah battery:
- Old RTC only: ~45 years (unrealistic due to other consumption)
- New RTC only: ~54,795 years (theoretical maximum)
```

## Advanced PCF2131 Power Optimizations (From Datasheet Analysis)

### Power Management Mode Selection
The PCF2131 supports multiple power management modes via PWRMNG[2:0] bits:

| Mode | PWRMNG[2:0] | Description | Power Impact |
|------|-------------|-------------|--------------|
| **Standard** | 000 | Default mode with VDD monitoring | Higher power |
| **Direct Switching** | 011 | No VDD/Vth monitoring | **LOWER POWER** ✅ |

**Recommendation:** Use Direct Switching Mode (011) for minimum power consumption.

### Temperature Compensation Control
The PCF2131 temperature compensation can be disabled for ultra-low power:

| Setting | TC_DIS | Accuracy | Power | Recommendation |
|---------|--------|----------|-------|----------------|
| **Enabled** | 0 | ±1ppm | Higher | Default |
| **Disabled** | 1 | ±3ppm | **ULTRA-LOW** ✅ | For battery life |

**Trade-off Analysis:** ±3ppm accuracy is acceptable for E-Ink display timing requirements while providing additional power savings.

### Battery Voltage Optimization
Current consumption varies with VBAT voltage:

| VBAT Voltage | Current Consumption | Notes |
|--------------|-------------------|-------|
| 1.2V | 107nA | Ultra-low voltage |
| **3.3V** | **83-104nA** | ✅ **Optimal for our design** |
| 5.5V | 91nA | Higher voltage |

**Our Configuration:** 3.3V VBAT provides the lowest current consumption at 83-104nA.

## Software Integration

### System Time Management
1. **Boot:** PCF2131 provides accurate time immediately
2. **Runtime:** System uses PCF2131 as primary time source
3. **Sync:** Periodic sync with PMU internal RTC
4. **Sleep:** PCF2131 maintains accurate time during power-down

### Wake Event Programming
1. **Schedule:** Application sets next wake time
2. **Program PMU:** i.MX93 sends wake schedule to PMU
3. **Sleep:** i.MX93 enters sleep/power-down
4. **Wake:** PMU or PCF2131 wakes i.MX93 at scheduled time

### Error Handling
- **PCF2131 Failure:** Fall back to PMU internal RTC
- **I2C Failure:** Retry communication, log errors
- **Power Loss:** VBAT backup maintains PCF2131 operation
- **Time Drift:** Periodic synchronization corrects drift

## Benefits

### Power Optimization
- **166x reduction** in RTC power consumption
- **~100µA savings** enables 5-year battery life
- **Complete i.MX93 power-down** possible while maintaining time

### Reliability
- **Battery backup** ensures time is never lost
- **Dual wake sources** (PMU + PCF2131) provide redundancy
- **Hardware timekeeping** independent of software failures

### Flexibility
- **Programmable wake schedules** for optimal power management
- **Multiple power modes** from active to ultra-deep sleep
- **Time synchronization** between i.MX93 and PMU

## Testing and Validation

### Power Measurement
- Verify 600nA consumption with PCF2131 only
- Confirm ~100µA savings vs internal RTC
- Validate complete i.MX93 power-down capability

### Functional Testing
- Time accuracy over extended periods
- Wake functionality from various sleep states
- I2C communication reliability
- Battery backup operation

### Integration Testing
- PMU communication and synchronization
- Application-level wake scheduling
- System recovery from deep sleep states
- Error handling and fallback scenarios

## Conclusion

The PCF2131-based RTC architecture provides a 166x improvement in RTC power consumption, enabling the target 5-year battery life for the i.MX93 E-Ink board. The combination of external low-power RTC, PMU internal RTC, and sophisticated wake scheduling creates a robust, power-efficient timekeeping system that supports complete i.MX93 power shutdown while maintaining accurate time and wake capability.
