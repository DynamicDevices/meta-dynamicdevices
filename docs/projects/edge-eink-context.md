# imx93-jaguar-eink Board Context

**GitHub**: [Edge EInk Milestone](https://github.com/DynamicDevices/meta-dynamicdevices/milestone/2)

## Hardware
- **SoC**: i.MX93, **Wireless**: ublox MAYA W2 (IW612), **Power**: MCXC143VFM
- **Features**: WiFi 6, BT 5.4, 802.15.4, LTE modem, 13" E-ink display
- **Security**: EdgeLock Enclave (ELE) enabled for secure functionality, Cortex-M33 enabled for co-processing

## Pin Mapping ✅
- **WiFi SDIO**: USDHC2 (SD2_CLK/CMD/DATA[0-3]), IRQ: GPIO4_IO25, RST: GPIO4_IO26
- **802.15.4 SPI**: LPSPI3 (GPIO_IO08-11), IRQ: GPIO4_IO27, RST: GPIO4_IO24 ✅ CONFIGURED
- **Bluetooth UART**: LPUART5 (DAP_TDO/TDI/TCLK/TMS pins)

## Key Files ✅
- **DT**: `lmp-device-tree/imx93-jaguar-eink.dts` - Complete rewrite for MAYA W2
- **Kernel**: `linux-lmp-fslc-imx/imx93-jaguar-eink/*.cfg` - WiFi/BT/802.15.4/LTE configs
- **Critical**: `fix_soc_imx9.cfg` - Configures ELE for proper operation
- **Optimized**: Minimal USB/display drivers for fast boot
- **Testing**: `docs/SPI_TESTING_GUIDE.md` - Hardware validation procedures for E-Ink display interfaces
- **E-Ink Driver**: `eink-spectra6` recipe with corrected chip select routing implementation

## WiFi Firmware Config ✅
- **Production**: `NXP_WIFI_SECURE_FIRMWARE="1"` → `.se` files (secure)
- **Development**: `NXP_WIFI_SECURE_FIRMWARE="0"` → `.bin` files (standard)
- **KAS Local**: Set to "0" in `kas/lmp-dynamicdevices.yml` (no production impact)

## WiFi Fixes ✅
- **Firmware Loading**: Fixed signed builds with explicit `fw_name` module parameter
- **Reboot Stability**: Fixed GPIO4_26 conflict, removed regulator GPIO control
- **Interface Management**: `mlan0` kept down by default, `uap0` ignored by NetworkManager

## Bluetooth Fixes ✅
- **UART Configuration**: Fixed incorrect `&lpuart4` → `&lpuart5` assignment (commit fdbb5b2)
- **Hardware RTS/CTS**: Hardware pinout issue resolved, device tree pinout verified correct
- **Pin Mapping**: All DAP pins correctly mapped to LPUART5 (TX/RX/CTS/RTS)
- **Reset Control**: BT_RST on GPIO4_IO24 managed by MCXC143VFM power controller

## Hostname Generation ✅
- **Solution**: Uses Foundries `lmp-auto-hostname` service (built-in)
- **Source**: `/sys/devices/soc0/serial_number` via OCOTP/NVMEM
- **Format**: `imx93-jaguar-eink-{uid}`

## U-Boot Config ✅
- **Files**: `u-boot-fio/imx93-jaguar-eink/*.cfg` (SPI, I2C, custom DTB)
- **Fix**: `disable-fiovb.cfg` prevents boot command error

## E-Ink Display Integration ✅

### Hardware Architecture
- **Display**: EL133UF1 13.3" E-Ink with dual controllers (left/right)
- **SPI Interface**: LPSPI1 (`/dev/spidev0.0`) at 10 MHz
- **Chip Select Routing**: Single CS line + L/R select GPIO for controller routing
- **GPIO Mapping**: Reset=558, Busy=561, DC=559, L/R=560, Power=555 (GPIO2 base=544)

### Software Implementation ✅ FIXED
- **Driver**: `eink-spectra6` recipe with corrected chip select routing
- **Routing Logic**: L/R select GPIO set before CS activation
- **Sequential Access**: Controllers accessed one at a time (not simultaneously)
- **Hardware Match**: Software now correctly implements hardware design

### Key Changes Applied
1. **Fixed CS Routing**: Single CS + L/R routing instead of dual independent CS
2. **Correct GPIO Numbers**: Updated for i.MX93 GPIO2 base address (544)
3. **Sequential Operation**: L/R select → CS activate → SPI transfer → CS deactivate
4. **Backward Compatibility**: Existing API maintained for applications

### Testing Commands
```bash
# Test E-Ink with corrected GPIO numbers
sudo el133uf1_test -d /dev/spidev0.0 -r 558 -b 561 -0 559 -1 560 --test-spi

# Board configuration info
el133uf1_test --board-info

# Test 802.15.4 SPI interface
ls -la /dev/spidev2.0
echo -n -e '\x55' | spi-pipe -d /dev/spidev2.0 -s 1000000 -b 8
```

## 802.15.4 Interface ✅ CONFIGURED

### Hardware Configuration
- **SPI Interface**: LPSPI3 (`/dev/spidev2.0`) at 12 MHz
- **Pin Mapping**: GPIO_IO08 (CS), GPIO_IO09 (MOSI), GPIO_IO10 (MISO), GPIO_IO11 (SCK)
- **Interrupt**: GPIO4_IO27 (ENET2_RD3) - ZB_INT signal
- **Reset**: Shared with Bluetooth (GPIO4_IO24, controlled by MCXC143VFM)

### Software Implementation ✅ ADDED
- **Device Tree**: LPSPI3 configured with proper pinctrl settings
- **SPI Device**: `/dev/spidev2.0` available for 802.15.4 communication
- **IW612 Support**: ublox MAYA W2 module provides 802.15.4 functionality
- **Kernel Config**: 802.15.4 subsystem enabled in kernel configuration

## Status ✅
- **Build**: SUCCESS (complete with 4GB partition support)
- **Boot**: SUCCESS (automatic device tree loading fixed)
- **WiFi**: WORKING (firmware loading, reboot stability fixed)
- **Hostname**: WORKING (OCOTP + lmp-auto-hostname)
- **EdgeLock Enclave**: WORKING (secure functionality confirmed)
- **Cortex-M33**: ENABLED (remoteproc and RPMSG support configured)
- **Partition Size**: FIXED (4GB root partition prevents image overflow)

## Boot Fixes ✅
- **U-Boot DTB**: Added missing `01-customise-dtb.patch` to set `fdt_file=imx93-jaguar-eink.dtb`
- **Boot Script**: Explicit `fdt_file` setting in boot.cmd for reliable device tree loading
- **Partition Size**: Custom WIC file `imx93-jaguar-eink-large.wks` with 4GB root partition
- **Image Size**: `IMAGE_ROOTFS_EXTRA_SPACE` increased to prevent "Image too large" errors

## EdgeLock Enclave & Cortex-M33 Configuration ✅
- **ELE Memory Region**: `ele_reserved@90000000` (1MB) for secure enclave operations
- **M33 Memory Regions**: Resource table, vring buffers, and 16MB non-cacheable section
- **Device Tree**: `s4muap` enabled for ELE Message Unit, `imx93_cm33` configured for remoteproc
- **Kernel Config**: `fix_soc_imx9.cfg` enables ELE support, `enable_m33_support.cfg` adds remoteproc/RPMSG
- **Communication**: RPMSG framework for inter-processor communication with M33 core

## TODO: Dynamic Partition Sizing
- **GitHub Issue**: [#20](https://github.com/DynamicDevices/meta-dynamicdevices/issues/20)
- **Optimization**: Replace fixed 4GB partition with calculated size + auto-resize on boot
- **Benefits**: Smaller image files, faster flashing, automatic expansion to available space
- **Implementation**: Use systemd-growfs or similar to expand root partition on first boot
- **WIC Enhancement**: Calculate minimum required size based on actual rootfs content

## Implementation Notes
- **Wireless**: IW612 MOAL/MLAN drivers, 802.15.4 subsystem, BT UART HCI
- **Power**: MCXC143VFM controller, fixed regulators, shared BT/ZB reset
- **Removed**: Audio, camera, HDMI/DSI, dual ethernet, extra USB
- **Security**: EdgeLock Enclave enabled and functional for secure operations
- **Security**: EdgeLock Enclave (ELE) enabled for secure functionality, Cortex-M33 disabled, ELE-based OCOTP for fuse access

## Fixed Issues ✅
- Machine config syntax, module autoloading, ZigBee support
- U-Boot fdt_file approach, kernel panic (ELE), device tree compilation
- U-Boot fiovb error, WiFi firmware loading, GPIO conflicts

## Build Commands
```bash
export KAS_MACHINE=imx93-jaguar-eink
./kas-build-base.sh
```

## Key Paths
- **DT**: `lmp-device-tree/imx93-jaguar-eink.dts`
- **Machine**: `conf/machine/imx93-jaguar-eink.conf`  
- **Kernel**: `linux-lmp-fslc-imx/imx93-jaguar-eink/*.cfg`
- **Images**: `build/tmp/deploy/images/imx93-jaguar-eink/`

## Recent Fixes (2025-08-29) ✅

### OCOTP Patch Issue
- **Problem**: `01-add-imx93-ocotp-support.patch` failed (kernel version mismatch)
- **Solution**: Removed patch, use existing kernel OCOTP drivers + config
- **Result**: ELE support enabled via `CONFIG_IMX_SEC_ENCLAVE=y`, `CONFIG_NVMEM_IMX_OCOTP_FSB_S400=y`

### WiFi Firmware Warning  
- **Problem**: KAS builds showed secure firmware warning
- **Solution**: Set `NXP_WIFI_SECURE_FIRMWARE="0"` in `kas/lmp-dynamicdevices.yml`
- **Result**: Local builds use `.bin` files, production unaffected

### Key Learnings
- Prefer kernel config over custom patches
- KAS config only affects local development builds

## SSH Testing Setup ✅

For automated testing and deployment to target boards, proper SSH configuration is essential:

### Required Setup Steps
1. **Use `fio` user**: All SSH connections should use the `fio` user account
2. **Copy SSH public key**: Enable passwordless authentication
3. **Configure passwordless sudo**: Allow `fio` user to run commands without password prompts

### Setup Commands
```bash
# Copy SSH public key to target board
echo "fio" | ssh-copy-id -f fio@192.168.0.36

# Configure passwordless sudo for fio user
ssh fio@192.168.0.36 "echo 'fio' | sudo -S sh -c 'echo \"fio ALL=(ALL) NOPASSWD: ALL\" > /etc/sudoers.d/fio'"
```

### Benefits
- **Automated testing**: Scripts can run without manual password entry
- **Faster development**: No password prompts during iterative testing
- **CI/CD ready**: Enables automated deployment and testing pipelines
- **Consistent workflow**: Same setup across all target boards

### Usage Example
```bash
# Deploy and test E-Ink application
scp el133uf1_test fio@192.168.0.36:/tmp/
ssh fio@192.168.0.36 "cd /tmp && chmod +x el133uf1_test && sudo ./el133uf1_test --test-spi"
```

### Security Notes
- SSH key authentication is more secure than password authentication
- Passwordless sudo is acceptable for development/testing environments
- Production deployments should use more restrictive sudo configurations

---
*Last Updated: 2025-01-09*
*Status: ✅ SSH TESTING SETUP DOCUMENTED - Added automated testing workflow for target board deployment*
