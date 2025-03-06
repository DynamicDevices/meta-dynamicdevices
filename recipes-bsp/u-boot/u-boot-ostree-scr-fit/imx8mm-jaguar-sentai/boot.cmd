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
i2c dev 1
i2c mw 28 0.1 40
i2c mw 28 d.1 8f
i2c mw 28 e.1 8f
i2c mw 28 2.1 3f
i2c mw 28 21.1 ff
i2c mw 28 22.1 ff
i2c mw 28 23.1 ff
i2c mw 28 24.1 ff
i2c mw 28 25.1 ff
i2c mw 28 26.1 ff

@@INCLUDE_COMMON_IMX@@
@@INCLUDE_COMMON@@
