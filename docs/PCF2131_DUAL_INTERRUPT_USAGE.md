# PCF2131 Dual Interrupt Support (INTA# and INTB#)

## Overview

This patch adds comprehensive support for the PCF2131's dual interrupt outputs, enabling flexible interrupt routing and advanced power management scenarios.

## Features

### 🔧 **Hardware Support**
- **INTA# (pin 3)**: Traditional alarm/interrupt output
- **INTB# (pin 4)**: Secondary interrupt output for flexible routing
- **Independent Configuration**: Each interrupt output can be configured independently
- **Runtime Control**: Interrupt routing can be changed at runtime via sysfs

### 🔧 **Interrupt Sources**
Both INTA# and INTB# can be configured to handle any combination of:
- **Alarm Interrupts** (AIEA/AIEB): RTC alarm events
- **Battery Interrupts** (BIEA/BIEB): Battery status changes
- **Battery Low Interrupts** (BLIEA/BLIEB): Low battery warnings
- **Second Interrupts** (SIA/SIB): Per-second timing events
- **Minute Interrupts** (MIA/MIB): Per-minute timing events
- **Watchdog Interrupts** (WD_CDA/WD_CDB): Watchdog timeout events
- **Timestamp Interrupts** (TSIE1A-4A/TSIE1B-4B): External event timestamps

## Device Tree Configuration

### Single Interrupt Mode (INTA# only)
```dts
pcf2131: rtc@53 {
    compatible = "nxp,pcf2131";
    reg = <0x53>;
    interrupt-parent = <&gpio4>;
    interrupts = <22 IRQ_TYPE_LEVEL_LOW>;
    interrupt-names = "inta";
    nxp,inta-mask = <0x07 0x00>;  /* Alarms + battery on INTA# */
    wakeup-source;
};
```

### Dual Interrupt Mode (INTA# and INTB#)
```dts
pcf2131: rtc@53 {
    compatible = "nxp,pcf2131";
    reg = <0x53>;
    interrupt-parent = <&gpio4>;
    interrupts = <22 IRQ_TYPE_LEVEL_LOW>, <23 IRQ_TYPE_LEVEL_LOW>;
    interrupt-names = "inta", "intb";
    nxp,inta-mask = <0x04 0x00>;  /* Alarms only on INTA# */
    nxp,intb-mask = <0x03 0x0F>;  /* Battery + timestamps on INTB# */
    wakeup-source;
};
```

### PMIC Integration Example
```dts
pcf2131: rtc@53 {
    compatible = "nxp,pcf2131";
    reg = <0x53>;
    interrupt-parent = <&gpio4>;
    interrupts = <22 IRQ_TYPE_LEVEL_LOW>, <23 IRQ_TYPE_LEVEL_LOW>;
    interrupt-names = "inta", "intb";
    /* INTA#: CPU gets alarms + battery low for system wake */
    nxp,inta-mask = <0x05 0x00>;  /* AIEA + BLIEA */
    /* INTB#: PMIC gets battery status + timestamps for power mgmt */
    nxp,intb-mask = <0x02 0x0F>;  /* BIEA + all timestamps */
    wakeup-source;
};
```

## Interrupt Mask Bit Definitions

### MASK1 Register (0x31 for INTA, 0x33 for INTB)
| Bit | Name     | Description                    |
|-----|----------|--------------------------------|
| 0   | BLIEA/B  | Battery low interrupt enable   |
| 1   | BIEA/B   | Battery interrupt enable       |
| 2   | AIEA/B   | Alarm interrupt enable         |
| 3   | WD_CDA/B | Watchdog countdown enable      |
| 4   | SIA/B    | Second interrupt enable        |
| 5   | MIA/B    | Minute interrupt enable        |
| 6-7 | Reserved | Must be 0                      |

### MASK2 Register (0x32 for INTA, 0x34 for INTB)
| Bit | Name      | Description                   |
|-----|-----------|-------------------------------|
| 0   | TSIE4A/B  | Timestamp 4 interrupt enable  |
| 1   | TSIE3A/B  | Timestamp 3 interrupt enable  |
| 2   | TSIE2A/B  | Timestamp 2 interrupt enable  |
| 3   | TSIE1A/B  | Timestamp 1 interrupt enable  |
| 4-7 | Reserved  | Must be 0                     |

## Runtime Configuration (Sysfs Interface)

### Reading Current Configuration
```bash
# Check INTA# configuration
cat /sys/class/rtc/rtc0/inta_mask1
cat /sys/class/rtc/rtc0/inta_mask2

# Check INTB# configuration  
cat /sys/class/rtc/rtc0/intb_mask1
cat /sys/class/rtc/rtc0/intb_mask2
```

### Changing Configuration at Runtime
```bash
# Route alarms to INTA# only
echo 0x04 > /sys/class/rtc/rtc0/inta_mask1  # Enable AIEA
echo 0x00 > /sys/class/rtc/rtc0/inta_mask2
echo 0x00 > /sys/class/rtc/rtc0/intb_mask1  # Disable INTB#
echo 0x00 > /sys/class/rtc/rtc0/intb_mask2

# Route battery events to INTB# only
echo 0x00 > /sys/class/rtc/rtc0/inta_mask1  # Disable INTA#
echo 0x00 > /sys/class/rtc/rtc0/inta_mask2
echo 0x03 > /sys/class/rtc/rtc0/intb_mask1  # Enable BIEB + BLIEB
echo 0x00 > /sys/class/rtc/rtc0/intb_mask2

# Route timestamps to INTB# for logging
echo 0x04 > /sys/class/rtc/rtc0/inta_mask1  # Alarms on INTA#
echo 0x00 > /sys/class/rtc/rtc0/inta_mask2
echo 0x00 > /sys/class/rtc/rtc0/intb_mask1  # No MASK1 events on INTB#
echo 0x0F > /sys/class/rtc/rtc0/intb_mask2  # All timestamps on INTB#
```

## Common Use Cases

### 1. **System Wake + PMIC Power Management**
```dts
/* INTA#: System wake events */
nxp,inta-mask = <0x05 0x00>;  /* Alarms + battery low */
/* INTB#: PMIC power management */
nxp,intb-mask = <0x02 0x0F>;  /* Battery status + timestamps */
```

### 2. **Dual CPU Architecture**
```dts
/* INTA#: Main CPU (critical events) */
nxp,inta-mask = <0x04 0x00>;  /* Alarms only */
/* INTB#: Secondary CPU (monitoring) */
nxp,intb-mask = <0x3B 0x0F>;  /* All other events */
```

### 3. **Event Logging System**
```dts
/* INTA#: Real-time events */
nxp,inta-mask = <0x34 0x00>;  /* Alarms + periodic */
/* INTB#: Timestamp logging */
nxp,intb-mask = <0x00 0x0F>;  /* All timestamps */
```

### 4. **Power-Optimized Wake**
```dts
/* INTA#: Critical wake events only */
nxp,inta-mask = <0x01 0x00>;  /* Battery low only */
/* INTB#: All other events (can be masked during sleep) */
nxp,intb-mask = <0x3E 0x0F>;  /* Everything else */
```

## Testing and Verification

### Check Driver Loading
```bash
# Verify PCF2131 detection
dmesg | grep pcf2131

# Check interrupt registration
cat /proc/interrupts | grep pcf2131

# Verify sysfs interface
ls -la /sys/class/rtc/rtc0/int*_mask*
```

### Test Interrupt Routing
```bash
# Set alarm for 30 seconds from now
date -d '+30 seconds' +%s > /sys/class/rtc/rtc0/wakealarm

# Monitor interrupt counts
watch -n 1 'cat /proc/interrupts | grep pcf2131'

# Check kernel messages
dmesg -w | grep -i "pcf2131\|rtc\|alarm"
```

### Verify Dual Interrupt Mode
```bash
# Check if both interrupts are registered
cat /proc/interrupts | grep -E "pcf2131-(inta|intb)"

# Test INTB# routing (if configured)
echo 0x00 > /sys/class/rtc/rtc0/inta_mask1  # Disable INTA#
echo 0x04 > /sys/class/rtc/rtc0/intb_mask1  # Enable alarms on INTB#

# Set alarm and verify INTB# triggers
date -d '+10 seconds' +%s > /sys/class/rtc/rtc0/wakealarm
```

## Power Consumption Impact

### Interrupt Routing Optimization
- **INTA# to CPU**: Direct system wake capability
- **INTB# to PMIC**: Can be processed without waking main CPU
- **Selective Routing**: Minimize unnecessary CPU wake events

### Recommended Power-Optimized Configuration
```dts
/* Minimal CPU wake events */
nxp,inta-mask = <0x05 0x00>;  /* Alarms + battery low only */
/* PMIC handles routine events */
nxp,intb-mask = <0x3A 0x0F>;  /* Battery status + timestamps + periodic */
```

## Troubleshooting

### Common Issues

1. **INTB# not working**
   - Check device tree has two interrupts defined
   - Verify interrupt-names includes "intb"
   - Ensure GPIO is properly configured

2. **Sysfs files not appearing**
   - Confirm PCF2131 is detected (not PCF2127/2129)
   - Check driver loaded successfully
   - Verify patch is applied correctly

3. **Interrupts not triggering**
   - Check interrupt mask configuration
   - Verify GPIO interrupt routing
   - Confirm wakeup-source is enabled

### Debug Commands
```bash
# Check device tree compilation
cat /proc/device-tree/soc@0/bus@42000000/i2c@42530000/rtc@53/interrupt-names

# Verify interrupt configuration
hexdump -C /sys/class/rtc/rtc0/inta_mask1
hexdump -C /sys/class/rtc/rtc0/intb_mask1

# Monitor real-time interrupt activity
cat /proc/interrupts | grep gpio-vf610 | grep "22\|23"
```

## Integration with Existing Code

### Backward Compatibility
- Existing PCF2131 configurations continue to work unchanged
- Single interrupt mode is the default
- No changes required for PCF2127/PCF2129 devices

### Migration Path
1. **Phase 1**: Deploy patch with existing single interrupt configuration
2. **Phase 2**: Update device tree to add INTB# interrupt
3. **Phase 3**: Configure interrupt routing via device tree or sysfs
4. **Phase 4**: Optimize power management based on interrupt routing

This comprehensive dual interrupt support enables advanced power management scenarios while maintaining full backward compatibility with existing PCF2131 deployments.
