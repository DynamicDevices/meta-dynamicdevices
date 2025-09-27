# i.MX93 Jaguar E-Ink Serial Console Scripts

This directory contains Python scripts for testing and interacting with the i.MX93 Jaguar E-Ink board via local serial console access.

## Prerequisites

- Python 3.6 or later
- `pyserial` library: `pip install pyserial`
- Board connected via USB serial adapter to `/dev/ttyUSB1` (configurable)
- Board must be in **boot mode** (not programming mode)

## Boot Pin Configuration

After programming the board, you need to change the boot pin settings:

1. **Programming Mode**: Boot pins set for UUU programming
2. **Boot Mode**: Boot pins set for normal boot from eMMC/SD

Consult the hardware documentation for the specific boot pin configuration for your board.

## Scripts Overview

### 1. `check_board_status.py` - Quick Board Status Check

Quickly determine if the board is responsive and in what state.

```bash
# Basic status check
python3 check_board_status.py

# Use different serial device
python3 check_board_status.py -d /dev/ttyUSB0

# Just monitor output for 30 seconds
python3 check_board_status.py --monitor 30

# Test basic communication only
python3 check_board_status.py --test-comm
```

**Output States:**
- `BOOTING` - Board is currently booting up
- `RESPONSIVE` - Board is ready and responding to commands
- `ACTIVE` - Board is outputting data but not responding to commands
- `UNRESPONSIVE` - No activity detected

### 2. `test_boot_process.py` - Comprehensive Boot Testing

Monitor and analyze the complete boot process with timing and stage detection.

```bash
# Full boot test with default settings
python3 test_boot_process.py

# Use different serial device and timeout
python3 test_boot_process.py -d /dev/ttyUSB0 -t 180

# Monitor only (no analysis)
python3 test_boot_process.py --monitor-only

# Don't save log file
python3 test_boot_process.py --no-log
```

**Features:**
- Automatic boot stage detection (SPL, U-Boot, Kernel, Systemd, Login)
- Boot timing analysis
- Error detection (kernel panic, RCU stalls, ELE errors)
- Automatic log file generation
- Login interaction testing

**Boot Stages Detected:**
1. **SPL Start** - U-Boot SPL initialization
2. **U-Boot Start** - Main U-Boot bootloader
3. **Kernel Start** - Linux kernel loading
4. **Kernel Init** - Kernel initialization
5. **Systemd Start** - System manager starting
6. **Services Start** - System services loading
7. **Login Ready** - Login prompt available
8. **Boot Complete** - Full system ready

### 3. `serial_console.py` - Interactive Serial Console

Interactive terminal for real-time communication with the board.

```bash
# Interactive console
python3 serial_console.py

# Start with logging enabled
python3 serial_console.py -l boot_session.log

# Enable timestamps
python3 serial_console.py -t

# Send file contents to board
python3 serial_console.py --send-file commands.txt
```

**Interactive Controls:**
- `Ctrl+]` - Exit console
- `Ctrl+L` - Toggle logging on/off
- `Ctrl+T` - Toggle timestamps on received data

## Usage Workflow

### 1. After Programming the Board

```bash
# 1. Change boot pins from programming mode to boot mode
# (Hardware step - consult board documentation)

# 2. Quick status check
python3 check_board_status.py

# 3. If board is responsive, run full boot test
python3 test_boot_process.py

# 4. For interactive debugging
python3 serial_console.py
```

### 2. Troubleshooting Boot Issues

```bash
# Monitor boot process with extended timeout
python3 test_boot_process.py -t 300

# Check for any activity
python3 check_board_status.py --monitor 60

# Interactive console for manual debugging
python3 serial_console.py -l debug_session.log -t
```

### 3. Automated Testing

```bash
#!/bin/bash
# Example automated test script

echo "Checking board status..."
if python3 check_board_status.py; then
    echo "Board is responsive, testing boot process..."
    if python3 test_boot_process.py -t 180; then
        echo "Boot test PASSED"
        exit 0
    else
        echo "Boot test FAILED"
        exit 1
    fi
else
    echo "Board is not responsive"
    exit 1
fi
```

## Configuration

### Serial Device

Default: `/dev/ttyUSB1`

Common alternatives:
- `/dev/ttyUSB0` - First USB serial adapter
- `/dev/ttyACM0` - USB CDC ACM device
- `/dev/ttyS0` - Hardware serial port

### Baud Rate

Default: `115200`

The i.MX93 typically uses 115200 baud for console output.

### Timeouts

- **Boot timeout**: 120 seconds (configurable with `-t`)
- **Communication timeout**: 5 seconds
- **Monitoring timeout**: 10 seconds (configurable)

## Log Files

### Boot Test Logs

Format: `boot_log_YYYYMMDD_HHMMSS.txt`

Contains:
- Boot timing summary
- Full boot log with timestamps
- Error detection results

### Serial Console Logs

Format: `serial_log_YYYYMMDD_HHMMSS.txt`

Contains:
- All transmitted and received data
- Timestamps for each transaction
- Direction indicators (TX/RX)

## Common Issues and Solutions

### Permission Denied

```bash
# Add user to dialout group
sudo usermod -a -G dialout $USER
# Log out and back in

# Or run with sudo (not recommended)
sudo python3 check_board_status.py
```

### Device Not Found

```bash
# List available serial devices
ls -la /dev/ttyUSB* /dev/ttyACM*

# Check dmesg for USB device detection
dmesg | grep -i usb | tail -10
```

### No Response from Board

1. **Check boot pins** - Ensure board is in boot mode, not programming mode
2. **Check power** - Verify board is powered on
3. **Check connections** - Verify USB cable and serial adapter
4. **Try reset** - Hardware reset the board
5. **Check baud rate** - Try different baud rates (9600, 38400, 115200)

### Boot Hangs

Common hang points and solutions:

1. **U-Boot hang** - Check U-Boot configuration, may need different bootloader
2. **Kernel panic** - Check device tree and kernel configuration
3. **RCU stall** - Often indicates hardware initialization issues
4. **ELE errors** - EdgeLock Enclave initialization problems

## Integration with Build Testing

These scripts can be integrated into the build testing workflow:

```bash
# After programming with fio-program-board.sh
./scripts/fio-program-board.sh 2043 imx93-jaguar-eink --program

# Change boot pins (manual step)
echo "Please change boot pins from programming to boot mode"
read -p "Press Enter when ready..."

# Test the boot process
./scripts/serial_console/test_boot_process.py

# If boot test passes, the build is validated
```

## Dependencies

Install required Python packages:

```bash
pip install pyserial
```

Or using the system package manager:

```bash
# Ubuntu/Debian
sudo apt install python3-serial

# CentOS/RHEL
sudo yum install python3-pyserial
```

## Troubleshooting

### Import Error: No module named 'serial'

```bash
pip install pyserial
# NOT pip install serial (that's a different package)
```

### Permission Issues

```bash
# Check device permissions
ls -la /dev/ttyUSB1

# Should show something like:
# crw-rw---- 1 root dialout 188, 1 Sep 27 10:30 /dev/ttyUSB1

# Add user to dialout group
sudo usermod -a -G dialout $USER
```

### Board Not Responding

1. Verify hardware connections
2. Check boot pin configuration
3. Try different baud rates
4. Use oscilloscope/logic analyzer to verify signal levels
5. Check board power supply voltage and current

## Advanced Usage

### Custom Boot Stage Detection

Modify the `boot_patterns` dictionary in `test_boot_process.py` to detect custom boot stages specific to your firmware.

### Automated Log Analysis

The boot logs can be parsed programmatically for automated analysis:

```python
import re
from datetime import datetime

def analyze_boot_log(log_file):
    with open(log_file, 'r') as f:
        content = f.read()
    
    # Extract boot timing
    timing_section = re.search(r'=== BOOT TIMING SUMMARY ===\n(.*?)\n\n', content, re.DOTALL)
    if timing_section:
        # Parse timing data
        pass
    
    # Check for errors
    errors = re.findall(r'\[ERROR\].*', content)
    return errors
```

### Integration with CI/CD

These scripts can be integrated into continuous integration pipelines for automated hardware-in-the-loop testing.
