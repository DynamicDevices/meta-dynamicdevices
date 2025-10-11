# E-ink Scheduler Feature Include
# This file can be included to add automated scheduling capabilities to E-ink displays

SUMMARY = "E-ink Display Scheduler Support"
DESCRIPTION = "Adds controller-agnostic scheduling service for automated E-ink display content updates. \
Works with T2000 USB, Spectra6 SPI, and other compatible display controllers."

# Core scheduler application
IMAGE_INSTALL:append = " eink-scheduler"

# HTTP client tools for API communication
IMAGE_INSTALL:append = " curl wget"

# JSON processing tools that may be useful
IMAGE_INSTALL:append = " jq"

# Development and debugging tools (optional - can be removed for production)
IMAGE_INSTALL:append = " \
    htop \
    tree \
    nano \
"
