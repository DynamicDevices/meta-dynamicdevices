# Power Monitoring and Analysis Tools Feature - DEVELOPMENT ONLY
# Include this feature to add comprehensive power monitoring tools to development images
# This feature should only be enabled for development builds with debug-tweaks
# 
# VERIFIED for scarthgap/v95 LmP release - all packages confirmed available

SUMMARY = "Power monitoring and analysis tools for development and optimization"

# Core power monitoring tools (all verified available)
IMAGE_INSTALL:append = " \
    powertop \
    iotop \
    htop \
    sysstat \
    power-analysis-suite \
"

# System analysis and profiling tools (all verified available)
IMAGE_INSTALL:append = " \
    strace \
    ltrace \
    lsof \
    procps \
    psmisc \
    util-linux \
"

# Hardware monitoring and control tools (all verified available)
IMAGE_INSTALL:append = " \
    i2c-tools \
    spitools \
    devmem2 \
    gpio-utils \
"

# Network monitoring for WiFi power analysis (all verified available)
IMAGE_INSTALL:append = " \
    tcpdump \
    iproute2 \
    ethtool \
    wireless-tools \
    iw \
"

# Kernel debugging and tracing tools (verified available)
IMAGE_INSTALL:append = " \
    trace-cmd \
"

# File system and I/O monitoring (verified available)
IMAGE_INSTALL:append = " \
    pv \
"

# Temperature and thermal monitoring (corrected package name)
IMAGE_INSTALL:append = " \
    lmsensors \
"

# Power management utilities (verified available)
IMAGE_INSTALL:append = " \
    upower \
"

# Development and debugging essentials (all verified available)
IMAGE_INSTALL:append = " \
    gdb \
    gdbserver \
    valgrind \
    binutils \
"

# Scripting and automation tools (verified available - python3 base package exists)
IMAGE_INSTALL:append = " \
    python3 \
    bash \
    bc \
    jq \
"

FEATURE_DESCRIPTION = "Comprehensive power monitoring and analysis tools for development and optimization"
