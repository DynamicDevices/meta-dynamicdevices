SUMMARY = "Minimal factory image which includes OTA Lite, Docker and optional development support such as OpenSSH"
DESCRIPTION = "Factory image for Dynamic Devices edge computing platforms with OTA capabilities, Docker containers and optional development tools"

LICENSE = "MIT"

require recipes-samples/images/lmp-image-common.inc

# Factory tooling requires SOTA (OSTree + Aktualizr-lite)
require ${@bb.utils.contains('DISTRO_FEATURES', 'sota', 'recipes-samples/images/lmp-feature-factory.inc', '', d)}

# Enable wayland related recipes if required by DISTRO
require ${@bb.utils.contains('DISTRO_FEATURES', 'wayland', 'recipes-samples/images/lmp-feature-wayland.inc', '', d)}

# Enable waydroid related recipes if required by DISTRO
require ${@bb.utils.contains('DISTRO_FEATURES', 'waydroid', 'recipes-samples/images/lmp-feature-waydroid.inc', '', d)}

# Enable auto register related recipes if required by DISTRO
require ${@bb.utils.contains('DISTRO_FEATURES', 'auto-register', 'recipes-samples/images/lmp-feature-auto-register.inc', '', d)}

# Enable alsa related recipes if required by DISTRO
require ${@bb.utils.contains('DISTRO_FEATURES', 'alsa', 'recipes-samples/images/lmp-feature-alsa.inc', '', d)}

# Enable alsa related recipes if required by DISTRO
require ${@bb.utils.contains('DISTRO_FEATURES', 'pulseaudio', 'recipes-samples/images/lmp-feature-pulseaudio.inc', '', d)}

# Enable improv protocol (BLE/serial onboarding) recipes if required by DISTRO
require ${@bb.utils.contains('DISTRO_FEATURES', 'improv', 'recipes-samples/images/lmp-feature-improv.inc', '', d)}

# Enable flutter related recipes if required by DISTRO
require ${@bb.utils.contains('DISTRO_FEATURES', 'flutter', 'recipes-samples/images/lmp-feature-flutter.inc', '', d)}

# Enable OP-TEE related recipes if provided by the image
require ${@bb.utils.contains('MACHINE_FEATURES', 'optee', 'recipes-samples/images/lmp-feature-optee.inc', '', d)}

# Enable SE05X related recipes if provided by machine
require ${@bb.utils.contains('MACHINE_FEATURES', 'se05x', 'recipes-samples/images/lmp-feature-se05x.inc', '', d)}

# Enable TPM2 related recipes if provided by machine
require ${@bb.utils.contains('MACHINE_FEATURES', 'tpm2', 'recipes-samples/images/lmp-feature-tpm2.inc', '', d)}

# Enable EFI support if provided by machine
require ${@bb.utils.contains('MACHINE_FEATURES', 'efi', 'recipes-samples/images/lmp-feature-efi.inc', '', d)}

# Enable IMA support if required by DISTRO
require ${@bb.utils.contains('MACHINE_FEATURES', 'ima', 'recipes-samples/images/lmp-feature-ima.inc', '', d)}

# Enable Xenomai4 related recipes if provided by the image
require ${@bb.utils.contains('MACHINE_FEATURES', 'xeno4', 'recipes-samples/images/lmp-feature-xeno4.inc', '', d)}

# Enable Intel AX210 WiFi related recipes if required by MACHINE
require ${@bb.utils.contains('MACHINE_FEATURES', 'ax210', 'recipes-samples/images/lmp-feature-ax210.inc', '', d)}

# Enable TI tas2563 related recipes if required by MACHINE
require ${@bb.utils.contains('MACHINE_FEATURES', 'tas2563', 'recipes-samples/images/lmp-feature-tas2563.inc', '', d)}

# Enable ST usb4500 related recipes if required by MACHINE
require ${@bb.utils.contains('MACHINE_FEATURES', 'stusb4500', 'recipes-samples/images/lmp-feature-stusb4500.inc', '', d)}

# Enable Infineon bgt60 related recipes if required by MACHINE
require ${@bb.utils.contains('MACHINE_FEATURES', 'bgt60', 'recipes-samples/images/lmp-feature-bgt60.inc', '', d)}

# Enable NXP IW612 related recipes if required by MACHINE
require ${@bb.utils.contains('MACHINE_FEATURES', 'nxpiw612-sdio', 'recipes-samples/images/lmp-feature-iw612.inc', '', d)}

# Enable Renesas upd72020x related recipes if required by MACHINE
require ${@bb.utils.contains('MACHINE_FEATURES', 'upd72020x', 'recipes-samples/images/lmp-feature-upd72020x.inc', '', d)}

# Enable alsa related recipes if required by MACHINE
require ${@bb.utils.contains('MACHINE_FEATURES', 'zigbee', 'recipes-samples/images/lmp-feature-zigbee.inc', '', d)}

# Enable power management for eink boards
require ${@bb.utils.contains('MACHINE', 'imx93-jaguar-eink', 'recipes-samples/images/lmp-feature-eink-power.inc', '', d)}

# Set image features based on DEV_MODE environment variable defined in Factory configuration
IMAGE_FEATURES += "${@bb.utils.contains('DEV_MODE', '1', 'debug-tweaks tools-sdk', '', d)}"

# Set image features based on CE_TEST environment variable defined in Factory configuration
IMAGE_FEATURES += "${@bb.utils.contains('CE_TESTING', '1', 'ce-testing', '', d)}"

# Enable development related recipes if required by IMAGE_FEATURES
require ${@bb.utils.contains('IMAGE_FEATURES', 'debug-tweaks', 'recipes-samples/images/lmp-feature-dev.inc', '', d)}

# Enable CE test related recipes if required by IMAGE_FEATURES
require ${@bb.utils.contains('IMAGE_FEATURES', 'ce-testing', 'recipes-samples/images/lmp-feature-ce-testing.inc', '', d)}

require recipes-samples/images/lmp-feature-softhsm.inc
require recipes-samples/images/lmp-feature-wireguard.inc
require recipes-samples/images/lmp-feature-docker.inc
require recipes-samples/images/lmp-feature-wifi.inc
require recipes-samples/images/lmp-feature-ota-utils.inc
require recipes-samples/images/lmp-feature-sbin-path-helper.inc

CORE_IMAGE_BASE_INSTALL_GPLV3 = "\
    packagegroup-core-full-cmdline-utils \
    packagegroup-core-full-cmdline-multiuser \
"

CORE_IMAGE_BASE_INSTALL += " \
    board-init \
    board-scripts \
    nano \
    lmp-auto-hostname \
    kernel-modules \
    networkmanager-nmcli \
    modemmanager \
    libiio \
    lmsensors \
    tzdata-core \
    tzdata-europe \
    nodejs \
    nodejs-npm \
    python3-pyserial \
    python3-paho-mqtt \
    packagegroup-core-full-cmdline-extended \
    ${@bb.utils.contains('LMP_DISABLE_GPLV3', '1', '', '${CORE_IMAGE_BASE_INSTALL_GPLV3}', d)} \
"

CORE_IMAGE_BASE_INSTALL:append:imx8mm-jaguar-sentai = " \
    socat \
    default-network-manager \
    gstreamer1.0-rtsp-server gstreamer1.0 gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav \
"

CORE_IMAGE_BASE_INSTALL:append:imx8mm-jaguar-inst = " \
       uwb-mqtt-publisher \
       linux-firmware-iwlwifi \
       pciutils \
"

CORE_IMAGE_BASE_INSTALL:append:imx93-jaguar-eink = " \
       default-network-manager \
"

IMAGE_FEATURES += "ssh-server-openssh"

#CORE_IMAGE_BASE_INSTALL:append:imx8mm-jaguar-phasora = " \
#    phasora-config \
#    gstreamer1.0-meta-base \
#"

#DRM-REMOVE:imxgpu:imx8mm-jaguar-phasora = "drm-gl drm-gles2"

#postprocess_function_phasora() {
#
#   # Setup the Weston UI (rotate)
#   sed -z -i 's/#\[output\]\n#name=HDMI-A-1/[output]\nname=DSI-1/g' ${IMAGE_ROOTFS}/etc/xdg/weston/weston.ini
#   sed -i 's/#transform=rotate-90/transform=rotate-270/g' ${IMAGE_ROOTFS}/etc/xdg/weston/weston.ini
#
#   # Add use of the calibration helper file
#   sed -i 's|touchscreen_calibrator=true|touchscreen_calibrator=true\ncalibration_helper=/usr/bin/save-calibration.sh|g' ${IMAGE_ROOTFS}/etc/xdg/weston/weston.ini
#
#   # Set a default calibration matrix
#   echo "ENV{LIBINPUT_CALIBRATION_MATRIX}=\"0.868808 -0.002796 0.188540 -0.006824 0.982137 -0.013213\"" >> ${IMAGE_ROOTFS}/etc/udev/rules.d/touchscreen.rules
#}

#ROOTFS_POSTPROCESS_COMMAND:imx8mm-jaguar-phasora += "postprocess_function; "

# Disable root login - NOTE: This means we can't use "sudo su" any more *but* running commands as root works
inherit extrausers

EXTRA_USERS_PARAMS:append = "\
  usermod -s /sbin/nologin root; \
"
