# TAS2563 Audio Driver Context

## Status ✅
- **Driver**: Android TAS2563 (kernel-module-tas2563) 
- **Hardware**: i.MX8MM Sentai, TAS2563 @ 0x4C, SAI3, I2S
- **Config**: Mono, GPIO5_4 shutdown control

## Configuration
- **Kernel**: `CONFIG_SND_SOC_TAS2562=m` (upstream driver)
- **DT**: `lmp-device-tree/imx8mm-jaguar-sentai.dts` (simple-audio-card, SAI3)
- **ALSA**: `asound.conf` (tas2563audio card, -60dB to 0dB range)
- **Service**: `audio-driver.service` (driver loading)

## Custom Driver Available
- **Source**: `tas2563-android-driver.git` (Android-based)
- **Firmware**: `tas2563_uCDSP.bin`
- **Enable**: Add `"tas2563"` to `MACHINE_FEATURES`

## Firmware ✅
- **Current**: Upstream driver (bypass-DSP mode)
- **Available**: Custom `tas2563_uCDSP.bin` (full DSP features)
- **Location**: `/lib/firmware/` when custom driver enabled

## Issues Fixed ✅
- Driver loading mismatch (snd-soc-tas2562 vs snd-soc-tas2563)
- Audio system functioning with upstream driver
- Cards detected: Loopback, tas2563audio, micfilaudio

## Test Hardware Support ✅
- **Dual Config**: Supports both PDM (i.MX8MM) and TAS2563 direct microphones
- **Auto-Detection**: `scripts/detect-audio-hardware.sh` script
- **Single Image**: Same build works for both hardware variants
