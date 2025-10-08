# i.MX93 Low Power Modes - Implementation Guide

Based on **AN13917: i.MX 93 Power Consumption Measurement (Rev. 3 — 29 February 2024)**

## 🎯 Key Low Power Modes for E-Ink Board

### 1. **Deep Sleep Mode (DSM) - 7.6 mW** ⭐ *PRIMARY MODE*

**What it is:**
- CA55 cluster is OFF
- MEDIAMIX is OFF  
- NICMIX is OFF
- WAKEUPMIX is ON (for wake sources)
- PLL is OFF
- 24M OSC is OFF
- PMIC is in STBY mode
- DDR is in Retention mode

**How to enter:**
```bash
# Boot with DSM device tree
# Boot the Linux image with imx93-11x11-evk-DSM.dtb

# Enter Deep Sleep Mode
echo mem > /sys/power/state
```

**Wake sources:** RTC, GPIO interrupts, other enabled wake sources

---

### 2. **Battery Mode (BBSM) - 0.1 mW** ⭐ *ULTRA LOW POWER*

**What it is:**
- Only BBSM domain remains on
- All power supplies except NVCC_BBSM_1P8 are off externally
- Secure real-time clock (SRTC) is maintained and running
- Tamper logic is retained
- SNVS is at 1.8V DGO (VBAT input: 3V)

**How to enter:**
```bash
# Boot normal Linux image
# Boot the Linux image with imx93-11x11-evk.dtb

# Enter Battery mode
# Press the ON/OFF key for 3 seconds
```

---

### 3. **System Idle Modes (Display Off)**

#### **LD Mode (DDR lowest + SWFFC) - 199.9 mW** ⭐ *BEST IDLE*
```bash
# Boot with LD device tree
# Boot the Linux image with imx93-11x11-evk-ld.dtb

# Run setup
./setup.sh

# Enter LD mode with lowest DDR speed
echo 3 > /sys/devices/platform/imx93-lpm/mode

# Enable auto clock gating
echo 256 > /sys/devices/platform/imx93-lpm/auto_clk_gating
```

#### **ND Mode - 288.1 mW**
```bash
# Boot normal device tree
# Boot the Linux image with imx93-11x11-evk.dtb

# Run setup
./setup.sh

# Enter ND mode
echo 1 > /sys/devices/platform/imx93-lpm/mode
```

#### **OD Mode - 345.6 mW**
```bash
# Boot normal device tree
# Boot the Linux image with imx93-11x11-evk.dtb

# Run setup
./setup.sh

# Enable auto clock gating (OD is default)
echo 256 > /sys/devices/platform/imx93-lpm/auto_clk_gating
```

---

## 🔧 Configuration Scripts

### **setup.sh** - Basic Power Optimization
```bash
#!/bin/bash
# Set CPU to max frequency (1.7 GHz) for best performance
# Disable Ethernet interfaces
# Stop Weston service
# Blank display
# Set 512kB read-ahead for storage

partitions=`lsblk |awk '$1 !~/-/{print $1}' |grep 'blk\|sd'`
for partition in $partitions; do
    echo 512 > /sys/block/$partition/queue/read_ahead_kb
done

systemctl stop weston.service
if [ -f /sys/class/graphics/fb0/blank ]; then
    echo 1 > /sys/class/graphics/fb0/blank
fi

for eth in `ls /sys/class/net/ | grep eth`; do
    ifconfig $eth down
done
```

### **DDRC_625MTS_setup.sh** - Low Bus Mode
```bash
#!/bin/bash
# Switch DDR to Low-bus mode 312.5 MHz (625 MT/s)
# Set CPU to minimum 1400 MHz
# DDR VFS for power saving
# Disable Ethernet, stop Weston, blank display

systemctl stop weston.service
if [ -f /sys/class/graphics/fb0/blank ]; then
    echo 1 > /sys/class/graphics/fb0/blank
fi
```

---

## 🎨 E-Ink Board Power Management Strategy

### **Recommended Power Flow:**

1. **Boot** → **Initialize E-Ink** → **Enter DSM** (7.6 mW)
2. **RTC Wake** → **Update E-Ink** → **Return to DSM**
3. **User Interaction** → **Active Processing** → **Return to DSM**
4. **Long-term Storage** → **Battery Mode** (0.1 mW)

### **Key Implementation Points:**

1. **Device Tree:** Use `imx93-11x11-evk-DSM.dtb` for DSM support
2. **Wake Sources:** Configure RTC and necessary GPIO wake sources
3. **Fast Resume:** DSM allows quick wake-up for E-Ink updates
4. **Power Budget:** 
   - Standby (99% time): 7.6 mW
   - Active (1% time): ~275-500 mW
   - Storage: 0.1 mW

### **Critical for Our E-Ink Board:**

- **PCF2131 RTC** will be the primary wake source (600nA consumption)
- **E-Ink Display** consumes 0W when static - perfect for DSM
- **Update frequency** every few minutes/hours works perfectly with DSM
- **Battery life** with 3000mAh battery: **months** in DSM mode

---

## 🚨 Important Notes

1. **Device Tree Requirements:** Different modes may require specific DTB files
2. **Wake Configuration:** Ensure RTC and other wake sources are properly configured
3. **PMIC Configuration:** PMIC must support STBY mode for DSM
4. **Resume Time:** DSM has longer resume time vs idle modes
5. **Testing:** Verify wake sources work correctly before production

## 📋 Power Mode Comparison

| Mode | Power | Use Case | Resume Time | Wake Sources |
|------|--------|----------|-------------|--------------|
| **DSM** | **7.6 mW** | E-Ink Standby | Medium | RTC, GPIO |
| **Battery** | **0.1 mW** | Storage | Long | Limited |
| **LD Idle** | **199.9 mW** | Active Idle | Fast | All |
| **ND Idle** | **288.1 mW** | Normal Idle | Fast | All |
| **OD Idle** | **345.6 mW** | Performance Idle | Fastest | All |

**For E-Ink applications, DSM (7.6 mW) is the optimal choice for standby power management.**
