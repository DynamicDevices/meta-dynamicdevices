# ALSA Audio Configuration for IMX8MM Jaguar Sentai

This document describes the enhanced ALSA configuration designed for robust audio pipeline operation, particularly for systems running echo cancellation and voice processing applications.

## Overview

The configuration creates a sophisticated audio routing system that separates physical and virtual audio streams, enabling multiple applications to share audio resources while maintaining isolation for echo cancellation processing.

## Audio Architecture

```
Applications → Virtual Mix → Loopback → Echo Cancellation → Physical Output
     ↑                                                           ↓
Virtual Split ← Loopback ← Echo Cancellation ← Physical Input ←──┘
```

### Physical Devices
- **Speaker (`spk`)**: TAS2563 audio amplifier output
- **Microphone (`mic`)**: Microphone array input

### Virtual Devices
- **Mix (`mix`)**: dmix plugin for multiple playback streams
- **Split (`split`)**: dsnoop plugin for shared capture streams
- **Loopback devices**: Four-way loopback for echo cancellation integration

## Key Configuration Changes

### 1. Buffer Management Improvements

**Problem**: Original configuration used tiny buffers (512/128 samples) causing audio dropouts.

**Solution**: Increased buffer sizes significantly:
- **Physical devices**: 4096/1024 samples (~85ms at 48kHz)
- **Virtual devices**: 8192/2048 samples (~170ms at 48kHz)
- **Added 4 periods** for smoother audio flow

```bash
# Before: ~10ms buffering
buffer_size 512
period_size 128

# After: ~170ms buffering
buffer_size 8192
period_size 2048
periods 4
```

### 2. Sample Rate Standardisation

**Problem**: Mixed sample rates (48kHz playback, 16kHz capture) caused sync issues.

**Solution**: Standardised all devices to 48kHz:
```bash
# Global defaults
defaults.pcm.dmix.rate 48000
defaults.pcm.dsnoop.rate 48000
```

### 3. Improved Rate Conversion

**Problem**: Linear rate converter caused long-term clock drift.

**Solution**: Switched to libsamplerate:
```bash
defaults.pcm.rate_converter "samplerate_converter"
```

### 4. Enhanced IPC Management

**Problem**: Shared memory corruption over time.

**Solution**: Added proper IPC permissions and group management:
```bash
ipc_key 1001
ipc_gid audio
ipc_perm 0660
```

### 5. Hardware Abstraction

**Problem**: Hardcoded device indices prone to enumeration changes.

**Solution**: Dynamic card detection and fallback mechanisms:
```bash
# Before: hw:tas2563audio,0
# After: Dynamic resolution with fallbacks
```

### 6. Debugging and Monitoring Support

**Added diagnostic PCM devices**:
- `test_playback`: Direct speaker testing
- `test_capture`: Direct microphone testing
- `monitor_playback`: Playback loopback monitoring
- `monitor_capture`: Capture loopback monitoring

## System-Level Enhancements

### 1. IPC Cleanup Service

Prevents shared memory corruption on system restart:

```bash
# /etc/systemd/system/alsa-ipc-cleanup.service
[Unit]
Description=Clean ALSA IPC segments
Before=sound.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'ipcs -m | grep 1001 | awk "{print \$2}" | xargs -r ipcrm -m'
ExecStart=/bin/sh -c 'ipcs -m | grep 1002 | awk "{print \$2}" | xargs -r ipcrm -m'
RemainAfterExit=yes

[Install]
WantedBy=sound.target
```

**Installation**:
```bash
sudo systemctl enable alsa-ipc-cleanup.service
sudo systemctl start alsa-ipc-cleanup.service
```

### 2. Kernel Module Configuration

Optimise ALSA kernel modules for stability:

```bash
# /etc/modprobe.d/alsa.conf
# Increase loopback devices and buffer sizes
options snd-aloop enable=1,1 pcm_substreams=2,2 pcm_notify=1,1
options snd prealloc_max_size=2097152
```

### 3. Runtime Monitoring

Monitor buffer health and detect issues early:

```bash
#!/bin/bash
# monitor-alsa.sh - Check for audio buffer issues
watch -n 5 'grep -H . /proc/asound/card*/pcm*/sub*/status | grep -E "(XRUN|underrun|overrun)"'
```

**IPC Health Check**:
```bash
# Check shared memory segments
ipcs -m | grep -E "(1001|1002)"

# Clean corrupted segments if needed
ipcs -m | grep 1001 | awk '{print $2}' | xargs -r ipcrm -m
ipcs -m | grep 1002 | awk '{print $2}' | xargs -r ipcrm -m
```

## Testing and Validation

### Device Discovery
```bash
# List all available PCM devices
aplay -L

# Test specific devices
aplay -D test_playbook /usr/share/sounds/alsa/Front_Left.wav
arecord -D test_capture -f S16_LE -r 48000 -c 2 test.wav
```

### Buffer Status Monitoring
```bash
# Check buffer status
cat /proc/asound/card*/pcm*/sub*/status

# Look for these healthy indicators:
# state: RUNNING
# trigger_time: (recent timestamp)
# No "XRUN" entries
```

### Echo Cancellation Integration
```bash
# Monitor loopback streams
arecord -D monitor_playbook -f S32_LE -r 48000 -c 2 playback.wav &
arecord -D monitor_capture -f S32_LE -r 48000 -c 2 capture.wav &
```

## Process Priority Recommendations

For stable echo cancellation pipeline operation:

```bash
# Real-time scheduling (requires root or RT privileges)
chrt -f 50 your_echo_cancellation_process

# Alternative: High priority nice level
nice -n -10 your_echo_cancellation_process

# CPU affinity for dedicated cores
taskset -c 2,3 your_echo_cancellation_process
```

## Troubleshooting

### Common Issues

**1. Audio Dropouts**
- Check buffer status: `cat /proc/asound/card*/pcm*/sub*/status`
- Look for XRUN indicators
- Increase buffer sizes if needed

**2. No Audio Output**
- Verify hardware devices: `aplay -l`
- Test direct hardware: `aplay -D spk_hw test.wav`
- Check loopback module: `lsmod | grep snd_aloop`

**3. Echo Cancellation Stops**
- Check IPC segments: `ipcs -m`
- Monitor loopback streams: `arecord -D monitor_*`
- Restart IPC cleanup service

**4. Device Not Found Errors**
- Check card enumeration: `cat /proc/asound/cards`
- Verify device names in configuration
- Check hardware connection and drivers

### Log Analysis

**System logs**:
```bash
journalctl -u sound.target -f
dmesg | grep -i alsa
```

**ALSA debugging**:
```bash
# Enable ALSA debug output
echo 1 > /proc/asound/card0/debug

# Check for buffer issues
grep -r "buffer" /proc/asound/
```

## Performance Tuning

### Latency vs Stability Trade-offs

| Buffer Size | Period Size | Periods | Latency | Stability |
|-------------|-------------|---------|---------|-----------|
| 1024        | 256         | 3       | ~21ms   | Low       |
| 2048        | 512         | 3       | ~43ms   | Medium    |
| 4096        | 1024        | 4       | ~85ms   | High      |
| 8192        | 2048        | 4       | ~170ms  | Very High |

### System Resource Requirements

- **Memory**: ~4MB per active audio stream
- **CPU**: <5% on modern ARM processors
- **Real-time scheduling**: Recommended for echo cancellation processes

## Integration Notes

This configuration is designed to work with:
- **PulseAudio**: Can use ALSA devices as sinks/sources
- **GStreamer**: Direct ALSA device access
- **Custom applications**: Use default PCM or specific named devices
- **Voice assistants**: Alexa, Google Assistant compatible

## Version History

- **v1.0**: Original configuration (512/128 buffers)
- **v2.0**: Enhanced buffer management and stability improvements
- **v2.1**: Added debugging tools and system integration
- **v2.2**: Hardware abstraction and fallback mechanisms

## Contributing

When modifying this configuration:
1. Test thoroughly with your specific echo cancellation pipeline
2. Monitor system logs for ALSA errors
3. Validate buffer health over extended periods
4. Document any hardware-specific requirements