# E-Ink Display Chip Select Routing Test Plan

## Overview

This document outlines the testing approach for the i.MX93 Jaguar E-Ink board's dual chip select routing system, based on hardware engineer feedback about level shifters and the L#R_SEL_DIS signal.

## Hardware Architecture

### Level Shifters (1.8V → 3.3V)
The display interface uses level shifters to convert i.MX93's 1.8V signals to 3.3V for the display:

- **Autosensing Direction**: Required for reading display registers (can be temperamental)
- **Fixed Direction**: More reliable but no register read capability
- **Recommendation**: Start with fixed direction buffers for initial testing

### Chip Select Routing
- **Display Controllers**: Left (CS_M) and Right (CS_S)
- **Single CS Line**: Only one chip select from i.MX93 SPI controller
- **Routing Control**: `L#R_SEL_DIS` signal (GPIO2_IO16) routes CS:
  - `LOW (0)` → CS routes to **left controller** (CS_M)
  - `HIGH (1)` → CS routes to **right controller** (CS_S)

## GPIO Mappings (i.MX93)

| Function | GPIO | Number | Signal | Notes |
|----------|------|--------|--------|-------|
| Reset | GPIO2_IO14 | 526 | RES_DIS# | Active-Low |
| Data/Command | GPIO2_IO15 | 527 | D/C#_DIS | LO=Cmd, HI=Data |
| **L/R Select** | **GPIO2_IO16** | **528** | **L#R_SEL_DIS** | **LO=Left, HI=Right** |
| Busy Status | GPIO2_IO17 | 529 | BUSY_DIS# | LO=Busy (Input) |
| Power Enable | GPIO2_IO11 | 523 | POWER_EN | Display power |

*GPIO2 base address: 512 (e.g., GPIO2_IO16 = 512 + 16 = 528)*

## Changes Made

### 1. Device Tree Updates (`imx93-jaguar-eink.dts`)

#### Added Chip Select Routing Control Node
```dts
/* E-Ink Chip Select Routing Control */
eink_cs_routing: eink-cs-routing {
    compatible = "gpio-controller";
    pinctrl-names = "default";
    pinctrl-0 = <&pinctrl_eink_cs_routing>;
    
    /* L#R_SEL_DIS GPIO control
     * LOW (0)  = Route CS to left controller (CS_M)
     * HIGH (1) = Route CS to right controller (CS_S)
     */
    lr-sel-gpio = <&gpio2 16 GPIO_ACTIVE_HIGH>; /* GPIO2_IO16 */
    
    /* Default to left controller for initial testing */
    lr-sel-default = <0>;
};
```

#### Added Pinctrl Configuration
```dts
/* E-Ink chip select routing control */
pinctrl_eink_cs_routing: eink_cs_routing_grp {
    fsl,pins = <
        MX93_PAD_GPIO_IO16__GPIO2_IO16    0x31e  /* L#R_SEL_DIS - Chip Select Routing Control */
    >;
};
```

### 2. Test Script (`scripts/test-eink-cs-routing.sh`)

Created comprehensive test script with:
- **Individual Controller Testing**: Test left and right controllers separately
- **Level Shifter Validation**: Test signal integrity on both routing paths
- **Rapid Switching Test**: Validate routing reliability
- **GPIO Management**: Proper export/unexport and cleanup

#### Usage Examples
```bash
# Set routing to left controller
./scripts/test-eink-cs-routing.sh left

# Set routing to right controller  
./scripts/test-eink-cs-routing.sh right

# Run comprehensive test
./scripts/test-eink-cs-routing.sh test

# Clean up GPIO exports
./scripts/test-eink-cs-routing.sh cleanup
```

## Testing Procedure

### Phase 1: Basic Connectivity
1. **Power On**: Verify display power regulator is working
2. **GPIO Export**: Ensure all GPIO pins can be exported and controlled
3. **SPI Interface**: Verify SPI communication is functional

### Phase 2: Level Shifter Testing
1. **Signal Integrity**: Test GPIO signal transitions on both routing paths
2. **Direction Detection**: Verify autosensing vs fixed direction behavior
3. **Timing Analysis**: Check for signal delays or glitches

### Phase 3: Controller Access Testing
1. **Left Controller (CS_M)**:
   - Set `L#R_SEL_DIS = LOW`
   - Attempt SPI communication
   - Verify busy signal response
   
2. **Right Controller (CS_S)**:
   - Set `L#R_SEL_DIS = HIGH`
   - Attempt SPI communication
   - Verify busy signal response

### Phase 4: Rapid Switching
1. **Routing Reliability**: Test rapid switching between controllers
2. **Level Shifter Stability**: Ensure buffers handle direction changes
3. **Signal Integrity**: Verify no cross-talk or interference

## Expected Results

### Success Indicators
- ✅ Both controllers respond to SPI commands
- ✅ Busy signal changes appropriately for each controller
- ✅ No GPIO export/control errors
- ✅ Clean switching between left and right routing

### Failure Indicators
- ❌ Only one controller responds → Check level shifter configuration
- ❌ Neither controller responds → Check SPI wiring and power
- ❌ GPIO control fails → Check device tree and pinctrl
- ❌ Signal integrity issues → May need autosensing buffers

## Troubleshooting Guide

### Issue: Only Left Controller Responds
- **Cause**: Fixed direction level shifters may not support right controller
- **Solution**: Switch to autosensing level shifters

### Issue: Neither Controller Responds  
- **Cause**: SPI wiring, power, or level shifter configuration
- **Solution**: Check power supply, SPI connections, and level shifter enable signals

### Issue: Intermittent Response
- **Cause**: Level shifter timing or signal integrity
- **Solution**: Add delays, check signal quality, verify power supply stability

### Issue: GPIO Control Fails
- **Cause**: Device tree configuration or pin conflicts
- **Solution**: Verify pinctrl settings and check for pin conflicts

## Next Steps

1. **Build and Deploy**: Compile device tree changes and deploy to target
2. **Run Tests**: Execute test script to validate chip select routing
3. **Level Shifter Optimization**: Based on results, optimize level shifter configuration
4. **Display Driver Integration**: Once routing is validated, integrate with display driver
5. **Performance Tuning**: Optimize SPI timing and signal integrity

## Files Modified

- `meta-dynamicdevices-bsp/recipes-bsp/device-tree/lmp-device-tree/imx93-jaguar-eink.dts`
- `scripts/test-eink-cs-routing.sh` (new)
- `docs/EINK_CS_ROUTING_TEST_PLAN.md` (this document)

## Environment Variables

```bash
export TARGET_IP="192.168.1.100"      # Target board IP
export TARGET_USER="fio"               # Target username  
export SPI_DEVICE="/dev/spidev1.0"    # SPI device path
```

---

**Author**: Dynamic Devices Ltd  
**Date**: $(date)  
**License**: Creative Commons Non Commercial  
**Copyright**: Dynamic Devices Ltd 2025
