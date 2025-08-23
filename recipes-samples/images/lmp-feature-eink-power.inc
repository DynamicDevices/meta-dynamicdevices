# Power management features for E-ink board
# Optimized for low power consumption and suspend/resume functionality

SUMMARY = "LMP E-ink board power management features"

# Power management packages
IMAGE_INSTALL:append = " \
    wifi-power-management \
    eink-power-management \
    fast-boot-optimization \
    pm-utils \
    powertop \
    cpufrequtils \
    ethtool \
    wireless-tools \
    iw \
"

# Enable systemd power management features
SYSTEMD_DEFAULT_TARGET = "multi-user.target"

# Kernel modules for power management
KERNEL_MODULE_AUTOLOAD:append = " \
    cpufreq_conservative \
    cpufreq_powersave \
    cpufreq_ondemand \
    governor_performance \
"

# Remove power-hungry features not needed for eink use case
IMAGE_INSTALL:remove = " \
    pulseaudio \
    alsa-utils \
    gstreamer1.0 \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    mesa \
    libdrm \
"

# Add power monitoring tools
IMAGE_INSTALL:append = " \
    htop \
    iotop \
    powertop \
"
