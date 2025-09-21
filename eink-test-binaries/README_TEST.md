# EL133UF1 E-Ink Driver Test Package

## Updated Build - Chip Select Timing Fixed

This test package contains the updated e-ink driver with **chip select timing fixes**:
- ✅ Chip selects are INACTIVE during reset sequence
- ✅ No CS activity during reset pulse
- ✅ CS0 only activates after reset completion and BUSY HIGH

## Files Included

### Applications
- **`el133uf1_test`** - Comprehensive test application
- **`el133uf1_demo`** - User-friendly demo application  
- **`el133uf1_display_image`** - Image display utility

### Library
- **`libel133uf1.so`** - Shared library (copy to `/usr/lib/` if needed)

## Quick Test Commands

### 1. Basic Hardware Test
```bash
# Test SPI communication and GPIO setup
./el133uf1_test --test-spi -v
```

### 2. Controller Status Check
```bash
# Read controller status (requires hardware)
./el133uf1_test --test-status -v
```

### 3. Reset Test (Fixed Timing)
```bash
# Test hardware reset with proper CS timing
./el133uf1_demo reset
```

### 4. Display Test
```bash
# Display white screen
./el133uf1_demo white

# Display other colors
./el133uf1_demo black
./el133uf1_demo red
```

### 5. Custom Configuration
```bash
# Use different GPIO pins or SPI device
./el133uf1_demo -d /dev/spidev0.0 -r 10 -b 11 white
```

## Expected Oscilloscope Behavior (Fixed)

With the timing fix, you should now see:
- **Reset pulse**: RST LOW (20ms) → HIGH (20ms)
- **Chip selects**: HIGH (inactive) during entire reset
- **CS activation**: Only AFTER BUSY goes HIGH
- **Clean timing**: No CS activity during reset sequence

## Hardware Setup

Default GPIO configuration:
- **Reset GPIO**: 8 (configurable with `-r`)
- **Busy GPIO**: 7 (configurable with `-b`) 
- **CS0 GPIO**: 0 (configurable with `-0`)
- **CS1 GPIO**: 1 (configurable with `-1`)
- **SPI Device**: `/dev/spidev1.0` (configurable with `-d`)

## Installation on Target

```bash
# Copy files to target
scp el133uf1_* libel133uf1.so root@<target-ip>:/tmp/

# On target, make executable
chmod +x /tmp/el133uf1_*

# Copy library (if needed)
cp /tmp/libel133uf1.so /usr/lib/

# Test
cd /tmp
./el133uf1_test --test-status -v
```

## Troubleshooting

### Permission Issues
```bash
# Fix SPI permissions
chmod 666 /dev/spidev1.0

# Fix GPIO permissions  
echo 8 > /sys/class/gpio/export
echo "out" > /sys/class/gpio/gpio8/direction
```

### Library Issues
```bash
# Check library path
export LD_LIBRARY_PATH=/tmp:$LD_LIBRARY_PATH

# Or copy to system location
cp libel133uf1.so /usr/lib/
ldconfig
```

## Changes in This Build

1. **Chip Select Timing**: Fixed CS signals during reset
2. **Reset Sequence**: Proper timing per E Ink specification  
3. **Error Handling**: Better SPI/GPIO error reporting
4. **Logging**: Enhanced debug output for timing analysis

## Build Information

- **Built**: $(date)
- **Commit**: Latest with CS timing fixes
- **Target**: Linux userspace (any architecture)
- **Dependencies**: libgpiod (optional, falls back to sysfs)

Test this build and capture new oscilloscope traces to verify the chip select timing is now correct!
