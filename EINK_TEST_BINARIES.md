# EL133UF1 E-Ink Driver Test Binaries

## 📍 Location
Test binaries are available in: **`./eink-test-binaries/`**

## 🚀 Quick Start

```bash
cd /data_drive/dd/meta-dynamicdevices/eink-test-binaries/

# Basic hardware test
./el133uf1_test --test-spi -v

# Controller status (requires hardware)
./el133uf1_test --test-status -v

# Reset test (with fixed CS timing)
./el133uf1_demo reset

# Display test
./el133uf1_demo white
```

## 📋 Files Available

- **`el133uf1_test`** - Comprehensive test application
- **`el133uf1_demo`** - User-friendly demo application  
- **`el133uf1_display_image`** - Image display utility
- **`libel133uf1.so`** - Shared library
- **`README_TEST.md`** - Detailed testing instructions

## 🔧 Key Fix Applied

✅ **Chip Select Timing Fixed**: CS signals are now INACTIVE during reset sequence

## 📊 Expected Oscilloscope Results

With this build, you should see:
- Reset pulse: RST LOW (20ms) → HIGH (20ms)
- **CS signals HIGH (inactive) during entire reset**
- CS0 activation only AFTER BUSY goes HIGH

## 📱 Copy to Target Device

```bash
# Copy to target for testing
scp eink-test-binaries/* root@<target-ip>:/tmp/

# On target
cd /tmp
chmod +x el133uf1_*
./el133uf1_test --test-status -v
```

See `./eink-test-binaries/README_TEST.md` for complete testing instructions.
