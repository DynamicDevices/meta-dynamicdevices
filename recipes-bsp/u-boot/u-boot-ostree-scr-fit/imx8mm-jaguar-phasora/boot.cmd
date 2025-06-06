echo "Using imx8mm-jaguar-phasora.dtb"

# Default boot type and device
setenv bootlimit 3
setenv devtype mmc
setenv devnum 2
setenv bootpart 1
setenv rootpart 2

# Boot image files
setenv fdt_file_final imx8mm-jaguar-phasora.dtb
setenv fit_addr ${initrd_addr}

# Boot firmware updates

# Offsets are in blocks (512KB each)
setenv bootloader 0x42
setenv bootloader2 0x300
setenv bootloader_s 0x1042
setenv bootloader2_s 0x1300

setenv bootloader_image "imx-boot"
setenv bootloader_s_image ${bootloader_image}
setenv bootloader2_image "u-boot.itb"
setenv bootloader2_s_image ${bootloader2_image}
setenv uboot_hwpart 1

# Set GPIO expander power on
i2c dev 0
i2c mw 20 2.1 ad
i2c mw 20 3.1 00
i2c mw 20 5.1 00
i2c mw 20 6.1 00

@@INCLUDE_COMMON_IMX@@
@@INCLUDE_COMMON@@
