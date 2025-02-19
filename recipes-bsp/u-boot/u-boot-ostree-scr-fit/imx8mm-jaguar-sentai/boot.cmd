echo "Using imx8mm-jaguar-sentai.dtb"

# Default boot type and device
setenv bootlimit 3
setenv devtype mmc
setenv devnum 2
setenv bootpart 1
setenv rootpart 2

# Boot image files
setenv fdt_file_final imx8mm-jaguar-sentai.dtb
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

# Set LEDs on
i2c dev 2
i2c mw 0x28 0x00 0x40
i2c mw 0x28 0x0d 0x8f
i2c mw 0x28 0x0e 0x8f
i2c mw 0x28 0x02 0x3F
i2c mw 0x28 0x21 0xff
i2c mw 0x28 0x22 0xff
i2c mw 0x28 0x23 0xff
i2c mw 0x28 0x24 0xff
i2c mw 0x28 0x25 0xff
i2c mw 0x28 0x26 0xff

@@INCLUDE_COMMON_IMX@@
@@INCLUDE_COMMON@@
