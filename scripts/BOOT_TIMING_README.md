# Boot Timing Tools for Dynamic Devices Boards

Simple, reliable tools for capturing and analyzing boot performance over serial connection before networking is available.

## Quick Start

### 1. Check Setup
```bash
./scripts/boot-timing-suite.sh status
```

### 2. Capture Boot Log
```bash
# Connect serial cable to board (default: /dev/ttyUSB1)
./scripts/boot-timing-suite.sh capture --name imx93-eink-test

# Power cycle or reset the board
# Wait for boot to complete or timeout
```

### 3. Analyze Results
```bash
# Analyze the most recent boot log
./scripts/boot-timing-suite.sh latest

# Compare multiple boot logs
./scripts/boot-timing-suite.sh compare
```

## Tools Overview

### `boot-timing-suite.sh` - Main Interface
- **Purpose**: Simple command interface for all boot timing operations
- **Usage**: `./boot-timing-suite.sh [command] [options]`
- **Commands**: `capture`, `analyze`, `latest`, `compare`, `monitor`, `status`

### `serial-boot-logger.sh` - Serial Capture
- **Purpose**: Captures boot output over serial with precise timestamps
- **Features**: 
  - Configurable serial device and baud rate
  - Automatic boot completion detection
  - Timestamped logging with relative timing
  - Basic analysis generation
- **Output**: Raw log, timing log, and initial analysis

### `analyze-boot-logs.sh` - Log Analysis
- **Purpose**: Detailed analysis of captured boot logs
- **Features**:
  - Boot phase breakdown (U-Boot, Kernel, Systemd)
  - Service timing analysis
  - Optimization recommendations
  - Multi-log comparison and trends

## Usage Examples

### Basic Boot Timing
```bash
# Capture boot with custom device
./scripts/boot-timing-suite.sh capture --device /dev/ttyUSB0 --name board-v2

# Analyze specific log file
./scripts/boot-timing-suite.sh analyze ./boot-logs/boot_20240115_143022_timing.log
```

### Continuous Monitoring
```bash
# Monitor multiple boot cycles for consistency testing
./scripts/boot-timing-suite.sh monitor --name consistency-test
```

### Troubleshooting Serial Connection
```bash
# Check available serial devices and permissions
ls -la /dev/ttyUSB* /dev/ttyACM*

# Fix permissions (choose one)
sudo chmod 666 /dev/ttyUSB1
sudo usermod -a -G dialout $USER  # then logout/login

# Test serial connection
screen /dev/ttyUSB1 115200  # Ctrl+A, K to exit
```

## Output Files

### Directory Structure
```
boot-logs/
├── board-name_20240115_143022_raw.log      # Raw serial output
├── board-name_20240115_143022_timing.log   # Timestamped output
└── board-name_20240115_143022_analysis.txt # Initial analysis

boot-analysis/
├── analysis_board-name_20240115_143022_20240115_144500.txt  # Detailed analysis
└── boot_comparison_20240115_144600.txt                      # Multi-log comparison
```

### Log Format
```
[0.000] U-Boot 2023.04 (Dec 19 2024 - 10:30:00 +0000)
[0.123] CPU:   i.MX93 rev1.0 at 1700 MHz
[2.456] Linux version 6.6.52-lmp-standard
[5.789] systemd[1]: Startup finished in 2.345s (kernel) + 1.234s (userspace) = 3.579s
[6.012] Welcome to LmP 4.0.15 (kirkstone)!
[6.234] imx93-jaguar-eink-12345678 login:
```

## Boot Time Targets

| Board | Target | U-Boot | Kernel | Systemd | Total |
|-------|--------|--------|--------|---------|-------|
| i.MX93 E-Ink | < 1.5s | < 0.5s | < 1.0s | < 0.5s | < 2.0s |
| i.MX8MM Sentai | < 2.0s | < 0.5s | < 1.2s | < 0.8s | < 2.5s |

## Analysis Output

### Boot Phase Analysis
- **Key Timing Points**: U-Boot start, kernel start/end, systemd start, boot complete
- **Phase Durations**: Time spent in each boot phase
- **Service Analysis**: Systemd service startup timing
- **Driver Timing**: Kernel driver initialization timing

### Optimization Recommendations
- **Excellent (< 1.5s)**: Target achieved, minimal optimization needed
- **Good (1.5-2.0s)**: Minor optimizations possible
- **Moderate (2.0-5.0s)**: Optimization recommended
- **Slow (> 5.0s)**: Immediate optimization needed

### Comparison Analysis
- **Statistics**: Min, max, average boot times across multiple logs
- **Variation**: Boot time consistency analysis
- **Trends**: Performance patterns over time

## Integration with Build System

### Enable Boot Profiling in Build
```bash
# Build with comprehensive boot profiling
export ENABLE_BOOT_PROFILING=1
./scripts/build-with-boot-profiling.sh imx93-jaguar-eink
```

### On-Target Analysis (after networking)
```bash
# These tools run on the target board after boot
systemd-analyze
systemd-analyze blame
boot-analysis.sh
```

## Troubleshooting

### Common Issues

#### Serial Device Not Found
```bash
# Check USB serial devices
lsusb | grep -i serial
dmesg | grep tty

# Try different device
./scripts/boot-timing-suite.sh capture --device /dev/ttyACM0
```

#### Permission Denied
```bash
# Quick fix (temporary)
sudo chmod 666 /dev/ttyUSB1

# Permanent fix
sudo usermod -a -G dialout $USER
# Then logout and login again
```

#### No Boot Completion Detected
- Check if board actually boots to login prompt
- Verify serial cable connection
- Try longer timeout: `--timeout 300`
- Check baud rate matches board configuration

#### Analysis Shows "Could not determine boot time"
- Boot may not have completed successfully
- Check raw log for actual boot progress
- Look for error messages or stuck services
- May need manual analysis of timing log

## Advanced Usage

### Custom Boot Markers
Edit the scripts to detect custom boot completion markers:
```bash
# In serial-boot-logger.sh, modify this line:
if echo "$line" | grep -q -E "(your-custom-marker|login:)"; then
```

### Integration with CI/CD
```bash
# Automated boot time testing
./scripts/boot-timing-suite.sh capture --timeout 180 --name ci-test-$BUILD_ID
BOOT_TIME=$(./scripts/boot-timing-suite.sh latest | grep "Total boot time" | cut -d: -f2)
echo "Boot time: $BOOT_TIME" >> build-metrics.log
```

### Multiple Board Testing
```bash
# Test multiple boards in sequence
for board in board1 board2 board3; do
    echo "Testing $board..."
    ./scripts/boot-timing-suite.sh capture --name "$board" --device "/dev/ttyUSB$i"
    # Switch to next board or prompt for manual switch
done
./scripts/boot-timing-suite.sh compare
```

## Dependencies

- `bc` - Floating point calculations
- `stty` - Serial port configuration  
- `timeout` - Command timeout handling
- Standard Unix tools: `grep`, `sed`, `sort`, `wc`, `find`

Install on Ubuntu/Debian:
```bash
sudo apt-get install bc coreutils findutils grep sed
```

## Files Created

- `scripts/serial-boot-logger.sh` - Serial capture tool
- `scripts/analyze-boot-logs.sh` - Log analysis tool  
- `scripts/boot-timing-suite.sh` - Main interface
- `scripts/BOOT_TIMING_README.md` - This documentation

## Why This Approach Works

### Simplicity
- Uses basic Unix tools (`cat`, `timeout`, `stty`)
- Avoids complex terminal handling that caused previous issues
- No dependencies on Python, expect, or other complex tools

### Reliability  
- Direct serial port access with minimal processing
- Robust error handling and cleanup
- Works with any serial device and baud rate

### Flexibility
- Configurable timeouts and devices
- Multiple analysis modes
- Easy integration with existing workflows

### Pre-Network Operation
- Captures complete boot sequence from power-on
- No dependency on network connectivity
- Works even when networking fails during boot

This approach has been designed to avoid the complexity issues encountered in previous implementations while providing comprehensive boot timing analysis capabilities.
