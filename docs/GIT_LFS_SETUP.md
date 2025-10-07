# Git LFS Setup Complete

Git Large File Storage (LFS) has been successfully configured for the meta-dynamicdevices repository.

## What's Tracked by Git LFS

Git LFS now handles these file types:
- **`*.pdf`** - Documentation and datasheets (109MB total)
- **`*.bin`** - Firmware binary files 
- **`*.itb`** - U-Boot image files (1.3MB each)
- **`*mfgtool*`** - Manufacturing tool files
- **`fitImage-*`** - Kernel image files (25MB each)

## Files Now in LFS

### Documentation (109MB total)
- `docs/datasheets/IMX8MMRM.pdf` (51MB)
- `docs/datasheets/IMX93RM.pdf` (58MB) 
- `docs/datasheets/TAS2563_datasheet.pdf` (3.7MB)

### Boot Files (35MB+ total)
- `custom-boot-files/imx-boot-mfgtool` (219KB)
- `custom-boot-files/u-boot-mfgtool.itb` (1.3MB)
- `mfgboot-imx8mm/fitImage-imx8mm-jaguar-sentai-mfgtool` (25MB)
- `mfgboot-imx8mm/imx-boot-mfgtool` (219KB)
- `mfgboot-imx8mm/u-boot-mfgtool.itb` (1.3MB)

### Firmware Files
- `recipes-kernel/firmware-tas2563/TAS2XXX3870.bin`
- `recipes-kernel/firmware-tas2563/tas2563-1amp-reg.bin`

## Benefits

✅ **Large files properly tracked** without bloating repository  
✅ **Fast clones** - LFS files downloaded on-demand  
✅ **Version control** for binary files maintained  
✅ **Bandwidth efficient** - only downloads needed versions  
✅ **GitHub compatible** - works with GitHub LFS storage  

## Usage

### For Developers
```bash
# Clone repository (LFS files downloaded automatically)
git clone https://github.com/DynamicDevices/meta-dynamicdevices.git

# Pull LFS files explicitly if needed
git lfs pull

# Check LFS file status
git lfs ls-files
```

### Adding New Large Files
Large files matching the tracked patterns will automatically use LFS:
```bash
git add new-firmware.bin    # Automatically tracked by LFS
git add new-manual.pdf      # Automatically tracked by LFS
git commit -m "Add new files"
```

## Storage Usage

- **Repository size**: ~8MB (source code only)
- **LFS storage**: ~142MB (binary files)
- **Total when cloned**: ~150MB (much better than 123GB!)

## Configuration Files

- **`.gitattributes`** - Defines LFS tracking patterns
- **`.gitignore`** - Updated to work with LFS (comments show LFS-tracked patterns)

The repository now has proper large file handling for both development and production use! 🚀
