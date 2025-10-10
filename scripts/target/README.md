# Target Scripts for WiFi Recovery and Diagnostics

These scripts are designed to be deployed to the i.MX93 E-Ink target board for WiFi troubleshooting and recovery.

## Scripts

### `wifi-recovery.sh`
Complete WiFi driver reinitialization script with 5 progressive recovery levels:

1. **Level 1**: Network interface reset (ip link down/up, NetworkManager restart)
2. **Level 2**: Driver module reload (remove and reload mwifiex modules)
3. **Level 3**: SDIO bus reset (unbind/bind SDIO device)
4. **Level 4**: Hardware reset (GPIO reset, MMC host reset)
5. **Level 5**: Power cycle via MCXC143VFM (using eink-power-cli)

**Usage:**
```bash
sudo ./wifi-recovery.sh
```

The script automatically tests connectivity after each level and stops when WiFi is recovered.

### `wifi-suspend-diag.sh`
Diagnostic script to capture detailed WiFi state before/after suspend for analysis.

**Usage:**
```bash
# Before suspend
sudo ./wifi-suspend-diag.sh pre

# Perform suspend test
sudo rtcwake -m freeze -s 10

# After resume  
sudo ./wifi-suspend-diag.sh post

# Compare states
./wifi-suspend-diag.sh compare

# Clean up diagnostic data
./wifi-suspend-diag.sh clean
```

## Deployment

Copy these scripts to the target board:
```bash
scp scripts/target/*.sh fio@192.168.0.36:/tmp/
```

Or include them in a Yocto recipe for permanent deployment.

## Hardware-Specific Notes

- **MMC Host**: Script uses `42850000.mmc` for i.MX93 USDHC2 (WiFi interface)
- **GPIO Reset**: Assumes WiFi reset on GPIO26 (may need adjustment)
- **MCXC143VFM**: Uses `eink-power-cli` for power management if available

## Expected WiFi Issue Pattern

After suspend/resume:
- ✅ WiFi interface appears up
- ✅ Can send packets (ping command succeeds)  
- ❌ No response received (packets lost)
- ❌ Association may be lost
- ❌ Driver may be in inconsistent state

The recovery script addresses these issues systematically.
