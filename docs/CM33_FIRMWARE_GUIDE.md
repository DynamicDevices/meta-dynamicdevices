# Cortex-M33 Firmware Loading Guide

**Board:** imx93-jaguar-eink  
**Target:** CM33 firmware development and deployment  
**Audience:** Embedded developers

## Overview

The i.MX93 Jaguar E-Ink board supports loading and running firmware on the Cortex-M33 co-processor. This guide covers both U-Boot and Linux kernel methods for CM33 firmware management.

## Hardware Configuration

### Memory Layout
The CM33 core has access to:
- **TCM (Tightly Coupled Memory)**: 0x201E0000 - 0x201FFFFF (128KB)
- **System RAM**: Shared with A55 cores via reserved memory regions
- **Peripherals**: Direct access to many i.MX93 peripherals

### Reserved Memory Regions
The device tree configures these memory regions for CM33:
```dts
reserved-memory {
    rsc_table: rsc-table@1fff8000 {
        reg = <0 0x1fff8000 0 0x1000>;
        no-map;
    };
    
    vdev0vring0: vdev0vring0@aff00000 {
        reg = <0 0xaff00000 0 0x8000>;
        no-map;
    };
    
    vdev0vring1: vdev0vring1@aff08000 {
        reg = <0 0xaff08000 0 0x8000>;
        no-map;
    };
    
    vdevbuffer: vdevbuffer@a8400000 {
        compatible = "shared-dma-pool";
        reg = <0 0xa8400000 0 0x100000>;
        no-map;
    };
    
    m33_reserved: m33_noncacheable_section@a8600000 {
        no-map;
        reg = <0 0xa8600000 0 0x1000000>;
    };
};
```

## Method 1: U-Boot Firmware Loading

### Prerequisites
- CM33 firmware binary (`.bin` or `.elf` format)
- Firmware stored on SD card, eMMC, or loaded via TFTP

### U-Boot Commands

#### Load and Start CM33 Firmware
```bash
# 1. Load firmware from SD card
=> fatload mmc 1:1 ${loadaddr} cm33_firmware.bin

# 2. Copy firmware to CM33 TCM
=> cp.b ${loadaddr} 0x201e0000 ${filesize}

# 3. Start CM33 core
=> bootaux 0x201e0000 0
```

#### Alternative: Load ELF Firmware
```bash
# Load ELF format firmware (automatically handles memory layout)
=> fatload mmc 1:1 ${loadaddr} cm33_firmware.elf
=> bootelf ${loadaddr}
```

#### Environment Variables for Automation
Add these to U-Boot environment for automated CM33 startup:
```bash
# Set firmware path and load address
=> setenv cm33_firmware cm33_firmware.bin
=> setenv cm33_loadaddr 0x80000000

# Create boot script for CM33
=> setenv boot_cm33 'fatload mmc 1:1 ${cm33_loadaddr} ${cm33_firmware}; cp.b ${cm33_loadaddr} 0x201e0000 ${filesize}; bootaux 0x201e0000 0'

# Auto-start CM33 during boot
=> setenv bootcmd 'run boot_cm33; run distro_bootcmd'
=> saveenv
```

### U-Boot Configuration
The following U-Boot features are enabled for CM33 support:
- `CONFIG_IMX_BOOTAUX=y` - Auxiliary core support
- `CONFIG_CMD_BOOTAUX=y` - bootaux command
- `CONFIG_CMD_ELF=y` - ELF loading support
- `CONFIG_CMD_MEMORY=y` - Memory operations
- File system support for firmware loading

## Method 2: Linux Kernel Remoteproc

### Prerequisites
- CM33 firmware in ELF format
- Firmware placed in `/lib/firmware/`
- Remoteproc kernel support enabled

### Kernel Configuration
The following kernel features are enabled:
```
CONFIG_REMOTEPROC=y
CONFIG_REMOTEPROC_CDEV=y
CONFIG_IMX_REMOTEPROC=y
CONFIG_RPMSG=y
CONFIG_RPMSG_CHAR=y
CONFIG_RPMSG_CTRL=y
CONFIG_RPMSG_NS=y
```

### Runtime Commands

#### Check Remoteproc Status
```bash
# List available remoteproc devices
ls /sys/class/remoteproc/

# Check current state
cat /sys/class/remoteproc/remoteproc0/state
# Possible states: offline, running, crashed, invalid
```

#### Load and Start CM33 Firmware
```bash
# 1. Copy firmware to /lib/firmware/
cp cm33_firmware.elf /lib/firmware/

# 2. Set firmware name
echo "cm33_firmware.elf" > /sys/class/remoteproc/remoteproc0/firmware

# 3. Start CM33 core
echo "start" > /sys/class/remoteproc/remoteproc0/state
```

#### Stop CM33 Core
```bash
# Stop CM33 core
echo "stop" > /sys/class/remoteproc/remoteproc0/state
```

#### Monitor CM33 Status
```bash
# Check remoteproc status
cat /sys/class/remoteproc/remoteproc0/state

# View remoteproc information
cat /sys/class/remoteproc/remoteproc0/name
cat /sys/class/remoteproc/remoteproc0/firmware

# Check kernel messages
dmesg | grep remoteproc
dmesg | grep rpmsg
```

## Inter-Processor Communication (RPMSG)

### RPMSG Channels
Once CM33 is running with RPMSG support, communication channels appear:
```bash
# List RPMSG devices
ls /dev/rpmsg*

# Example devices:
# /dev/rpmsg_ctrl0 - Control channel
# /dev/rpmsg0 - Data channel
```

### RPMSG Communication Example
```bash
# Send data to CM33
echo "Hello CM33" > /dev/rpmsg0

# Read data from CM33
cat /dev/rpmsg0
```

### RPMSG TTY Console
If CM33 firmware supports TTY console:
```bash
# Check for RPMSG TTY devices
ls /dev/ttyRPMSG*

# Connect to CM33 console
minicom -D /dev/ttyRPMSG0
```

## Firmware Development

### CM33 Firmware Requirements
Your CM33 firmware should:
1. **Link to TCM address**: Start at 0x201E0000
2. **Initialize stack pointer**: Set up stack in TCM or SRAM
3. **Configure vector table**: Set VTOR register
4. **Handle RPMSG**: Implement RPMSG protocol for communication

### Example Linker Script (cm33.ld)
```ld
MEMORY
{
    TCM (rwx) : ORIGIN = 0x201E0000, LENGTH = 128K
    SRAM (rwx) : ORIGIN = 0xA8600000, LENGTH = 16M
}

SECTIONS
{
    .text : {
        . = ALIGN(4);
        *(.vectors)
        *(.text*)
        . = ALIGN(4);
    } > TCM
    
    .data : {
        . = ALIGN(4);
        *(.data*)
        . = ALIGN(4);
    } > TCM
    
    .bss : {
        . = ALIGN(4);
        *(.bss*)
        . = ALIGN(4);
    } > TCM
}
```

### Build Commands
```bash
# Compile CM33 firmware
arm-none-eabi-gcc -mcpu=cortex-m33 -mthumb -T cm33.ld -o cm33_firmware.elf main.c

# Convert to binary format for U-Boot
arm-none-eabi-objcopy -O binary cm33_firmware.elf cm33_firmware.bin
```

## Debugging

### U-Boot Debugging
```bash
# Check if bootaux command is available
=> help bootaux

# Verify firmware loading
=> md.b 0x201e0000 0x100

# Check CM33 core status
=> bootaux 0x201e0000 0
# Should show "## Starting auxiliary core..." message
```

### Linux Debugging
```bash
# Check remoteproc driver loading
lsmod | grep remoteproc

# Check device tree CM33 node
cat /proc/device-tree/cm33/status

# Check mailbox devices
ls /sys/class/mailbox/

# Monitor kernel messages during firmware loading
dmesg -w &
echo "start" > /sys/class/remoteproc/remoteproc0/state
```

### Common Issues

**Firmware Not Starting:**
1. Check firmware load address (must be 0x201E0000 for TCM)
2. Verify firmware format (binary for U-Boot, ELF for remoteproc)
3. Check memory permissions and reserved regions

**RPMSG Communication Fails:**
1. Verify CM33 firmware implements RPMSG protocol
2. Check vring buffer configuration in device tree
3. Ensure mailbox devices are working

**Remoteproc State "crashed":**
1. Check CM33 firmware for exceptions
2. Verify memory layout and stack configuration
3. Check for resource table in ELF firmware

## Example Use Cases

### 1. Real-Time Data Processing
Use CM33 for time-critical tasks while A55 handles Linux applications:
```bash
# Start real-time firmware
echo "realtime_processor.elf" > /sys/class/remoteproc/remoteproc0/firmware
echo "start" > /sys/class/remoteproc/remoteproc0/state

# Send sensor data to CM33
echo "sensor_data" > /dev/rpmsg0
```

### 2. Power Management
Use CM33 for low-power monitoring while A55 cores sleep:
```bash
# Load power management firmware
echo "power_manager.elf" > /sys/class/remoteproc/remoteproc0/firmware
echo "start" > /sys/class/remoteproc/remoteproc0/state
```

### 3. Peripheral Control
Dedicate CM33 to handle specific peripherals:
```bash
# Load peripheral controller firmware
echo "peripheral_ctrl.elf" > /sys/class/remoteproc/remoteproc0/firmware
echo "start" > /sys/class/remoteproc/remoteproc0/state
```

## Integration with Build System

### Adding CM33 Firmware to Image
Create a recipe to include CM33 firmware in the root filesystem:

```bitbake
# recipes-bsp/cm33-firmware/cm33-firmware.bb
SUMMARY = "CM33 firmware for imx93-jaguar-eink"
LICENSE = "CLOSED"

SRC_URI = "file://cm33_firmware.elf"

do_install() {
    install -d ${D}/lib/firmware
    install -m 0644 ${WORKDIR}/cm33_firmware.elf ${D}/lib/firmware/
}

FILES:${PN} = "/lib/firmware/cm33_firmware.elf"
```

### Auto-Start CM33 on Boot
Create a systemd service:

```ini
# /etc/systemd/system/cm33-autostart.service
[Unit]
Description=Auto-start CM33 firmware
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo cm33_firmware.elf > /sys/class/remoteproc/remoteproc0/firmware'
ExecStart=/bin/sh -c 'echo start > /sys/class/remoteproc/remoteproc0/state'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

## Performance Considerations

### Memory Access
- **TCM**: Fastest access, limited to 128KB
- **SRAM**: Good performance, larger capacity
- **DDR**: Slowest but largest capacity

### Communication Overhead
- **RPMSG**: Higher-level protocol, easier to use
- **Shared Memory**: Lower overhead, requires synchronization
- **Mailbox**: Lowest overhead, interrupt-based

### Power Management
- CM33 can run while A55 cores are in low-power states
- Implement proper clock gating in CM33 firmware
- Use WFI instruction when CM33 is idle

For questions or issues, contact the software team with specific error messages and firmware details.
