# E-ink Board Power Management Services

## Overview
Power-controlled system lifecycle management using MCXC143VFM power controller via `eink-power-cli`.

## Services

### eink-restart.service
**Purpose**: Power-controlled system restart  
**Trigger**: `reboot.target` (systemctl reboot, reboot command)  
**Command**: `eink-power-cli board reset`  
**Fallback**: Normal system reboot if power controller fails  

### eink-shutdown.service  
**Purpose**: Power-controlled system shutdown  
**Trigger**: `poweroff.target`, `halt.target` (shutdown, poweroff, halt commands)  
**Command**: `eink-power-cli board shutdown`  
**Fallback**: Normal system shutdown if power controller fails  

## Implementation

### Service Configuration
```ini
# eink-restart.service
[Unit]
Description=E-ink Board Custom Restart Handler
DefaultDependencies=no
Before=systemd-reboot.service
WantedBy=reboot.target

# eink-shutdown.service  
[Unit]
Description=E-ink Board Custom Shutdown Handler
DefaultDependencies=no
Before=systemd-poweroff.service systemd-halt.service
WantedBy=poweroff.target halt.target
```

### Retry Logic
- **Attempts**: 5 retries with 1-second intervals
- **Timeout**: 30 seconds per service
- **Logging**: systemd journal (`journalctl -u eink-restart.service`)

### Power Controller Commands
```bash
# Restart flow
eink-power-cli board reset    # Hardware power cycle reset

# Shutdown flow  
eink-power-cli board shutdown # Deep power-off state
```

## Integration

### Recipe
**File**: `recipes-bsp/eink-power-management/eink-power-management_1.0.bb`  
**Dependencies**: `eink-power-cli`, `bash`  
**Services**: Auto-enabled on boot  

### Scripts
- `/usr/bin/eink-restart.sh` - Restart handler
- `/usr/bin/eink-shutdown.sh` - Shutdown handler

## Behavior

### Normal Operation
1. User issues `reboot` or `shutdown` command
2. systemd triggers appropriate service before system handlers
3. Service executes `eink-power-cli` command
4. MCXC143VFM power controller performs hardware reset/shutdown
5. System power cycles or enters deep sleep

### Failure Handling
1. If `eink-power-cli` fails after 5 attempts
2. Service exits and allows normal systemd operation
3. System performs standard software reboot/shutdown

## Testing

### Restart Test
```bash
systemctl reboot  # Should trigger power controller reset
# Expected: Hard power cycle, faster boot
```

### Shutdown Test  
```bash
systemctl poweroff  # Should trigger power controller shutdown
# Expected: Deep power-off, may require physical wake
```

## Troubleshooting

### Service Status
```bash
systemctl status eink-restart.service
systemctl status eink-shutdown.service
journalctl -u eink-restart.service -f
```

### Manual Testing
```bash
# Test power controller communication
eink-power-cli ping

# Test commands manually
eink-power-cli board reset    # Use with caution
eink-power-cli board shutdown # May require physical wake
```

### Common Issues
- **Service fails**: Check `eink-power-cli` availability and UART permissions
- **No power cycle**: Verify MCXC143VFM firmware and `/dev/ttyLP2` access
- **Immediate restart**: Power controller executed command successfully

## Safety Notes
- **⚠️ Shutdown service may put board in unrecoverable deep sleep**
- **⚠️ Recovery may require physical power cycling or wake mechanisms**
- **✅ Services include fallback to normal operation if power controller fails**
