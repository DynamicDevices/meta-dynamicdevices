# imx93-jaguar-eink Board Context

**GitHub**: [Edge EInk Milestone](https://github.com/DynamicDevices/meta-dynamicdevices/milestone/2)

## Hardware
- **SoC**: i.MX93, **Wireless**: ublox MAYA W2 (IW612), **Power**: MCXC143VFM
- **Features**: WiFi 6, BT 5.4, 802.15.4, LTE modem, 13" E-ink display
- **Security**: EdgeLock Enclave (ELE) enabled for secure functionality, Cortex-M33 enabled for co-processing

## Pin Mapping ✅
- **WiFi SDIO**: USDHC2 (SD2_CLK/CMD/DATA[0-3]), IRQ: GPIO4_IO25, RST: GPIO4_IO26
- **802.15.4 SPI**: LPSPI3 (GPIO_IO08-11), IRQ: GPIO4_IO27, RST: GPIO4_IO24  
- **Bluetooth UART**: LPUART5 (DAP_TDO/TDI/TCLK/TMS pins)

## Key Files ✅
- **DT**: `lmp-device-tree/imx93-jaguar-eink.dts` - Complete rewrite for MAYA W2
- **Kernel**: `linux-lmp-fslc-imx/imx93-jaguar-eink/*.cfg` - WiFi/BT/802.15.4/LTE configs
- **Critical**: `fix_soc_imx9.cfg` - Configures ELE for proper operation
- **Optimized**: Minimal USB/display drivers for fast boot

## WiFi Firmware Config ✅
- **Production**: `NXP_WIFI_SECURE_FIRMWARE="1"` → `.se` files (secure)
- **Development**: `NXP_WIFI_SECURE_FIRMWARE="0"` → `.bin` files (standard)
- **KAS Local**: Set to "0" in `kas/lmp-dynamicdevices.yml` (no production impact)

## WiFi Fixes ✅
- **Firmware Loading**: Fixed signed builds with explicit `fw_name` module parameter
- **Reboot Stability**: Fixed GPIO4_26 conflict, removed regulator GPIO control
- **Interface Management**: `mlan0` kept down by default, `uap0` ignored by NetworkManager

## Hostname Generation ✅
- **Solution**: Uses Foundries `lmp-auto-hostname` service (built-in)
- **Source**: `/sys/devices/soc0/serial_number` via OCOTP/NVMEM
- **Format**: `imx93-jaguar-eink-{uid}`

## U-Boot Config ✅
- **Files**: `u-boot-fio/imx93-jaguar-eink/*.cfg` (SPI, I2C, custom DTB)
- **Fix**: `disable-fiovb.cfg` prevents boot command error

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

---
*Last Updated: 2025-08-29*
*Status: ✅ OCOTP ISSUES RESOLVED - Removed problematic patch, confirmed enclave driver enabled, configured WiFi firmware for development*
