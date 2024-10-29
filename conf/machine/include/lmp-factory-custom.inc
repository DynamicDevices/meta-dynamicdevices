# LMP factory specific customizations (either replace or extend options as defined by meta-lmp)

# kernel modules signing key
MODSIGN_KEY_DIR = "${TOPDIR}/conf/factory-keys"
MODSIGN_PRIVKEY = "${MODSIGN_KEY_DIR}/privkey_modsign.pem"
MODSIGN_X509 = "${MODSIGN_KEY_DIR}/x509_modsign.crt"

# U-Boot signing key
UBOOT_SIGN_KEYDIR = "${TOPDIR}/conf/factory-keys"
UBOOT_SIGN_KEYNAME = "ubootdev"

# OP-TEE: Custom TA signing key
OPTEE_TA_SIGN_KEY = "${TOPDIR}/conf/factory-keys/opteedev.key"

# SPL / U-Boot proper signing key
UBOOT_SPL_SIGN_KEYDIR = "${TOPDIR}/conf/factory-keys"
UBOOT_SPL_SIGN_KEYNAME = "spldev"

# UEFI keys and certificates
UEFI_SIGN_KEYDIR = "${TOPDIR}/conf/factory-keys/uefi"

# TF-A Trusted Boot
TF_A_SIGN_KEY_PATH = "${TOPDIR}/conf/factory-keys/tf-a/privkey_ec_prime256v1.pem"

# Use custom DTS handling
PREFERRED_PROVIDER_virtual/dtb ?= "lmp-device-tree"

PACKAGECONFIG:append:pn-networkmanager:imx8mm-jaguar-sentai = " modemmanager ppp"

# Support SE050
SE05X_OEFID:imx8mm-jaguar-sentai = "0xA1F4"
MACHINE_FEATURES:append:imx8mm-jaguar-sentai = " se05x"

SE05X_OEFID:imx8mm-jaguar-inst = "0xA1F4"
MACHINE_FEATURES:append:imx8mm-jaguar-inst = " se05x"
