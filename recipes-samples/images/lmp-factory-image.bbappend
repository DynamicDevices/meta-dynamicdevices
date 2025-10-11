# BSP-specific additions to lmp-factory-image
# Hardware-specific packages for Dynamic Devices boards

# XM125 Radar Module Support (Sentai board)
# Include XM125 firmware and tools when xm125-radar machine feature is enabled
CORE_IMAGE_BASE_INSTALL:append:imx8mm-jaguar-sentai = " \
    ${@bb.utils.contains('MACHINE_FEATURES', 'xm125-radar', 'xm125-firmware', '', d)} \
"
