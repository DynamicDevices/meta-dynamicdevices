FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#   Important security configuration notes for SC05X / TPM / HSM
#
#   @see: https://docs.foundries.io/latest/reference-manual/security/secure-elements/secure-element.050.html
#
#   CFG_CORE_SE05X_SCP03_EARLY             - enable encrypted scp03 i2c comms before normal world boot (NOTE: Remember to rotate keys!)
#   CFG_SCP03_PTA                          - don't allow enabling in normal world as we should already be enabled
#   CFG_CORE_SE05X_DISPLAY_INFO            - whether to display debug info on boot (e.g. if OEFID may be incorrect)
#   CFG_CORE_SE05X_I2C_BUS                 - if DeviceTree is say i2c4 then this is bus-1 so 3. (NOTE: OpTee initialises i.MX8 pinmux internally)
#   CFG_CORE_SE05X_SCP03_PROVISION_ON_INIT - whether to rotate scp03 (i2c encryption) keys on startup
#   CFG_CORE_SE05X_SCP03_PROVISION         - allow scp03 (i2c encryption) key rotation from user space application
#   CFG_CORE_SE05X_INIT_NVM                - clear SE05X NVM (factory reset?)
#   CFG_CORE_SE05X_OEFID                   - se05x part ID. Board WILL NOT BOOT if this is wrong. Now set in machine.conf
#
#   Useful tools:
#
#   - ssscli                               - NXP tool. Useful for development. fio-se05c-cli is recommended by Foundries
#   - pkcs11-tool
#   - fio-se05x-cli
#
#  Useful notes:
#
#  How to clear TPM and setup for TPM2 PKCS11 (this sets the token and pin we use in future)
#
#  @see: https://docs.foundries.io/latest/reference-manual/security/secure-elements/secure-element.tpm.html#validating-tpm-2-pkcs-11
#

EXTRA_OEMAKE:append:imx8mm-jaguar-sentai = " \
    ${@bb.utils.contains('MACHINE_FEATURES', \
    'se05x', \
    'CFG_IMX_I2C=y CFG_CORE_SE05X=y CFG_NXP_SE05X_RNG_DRV=n CFG_NXP_CAAM_RSA_DRV=n CFG_NUM_THREADS=1 CFG_CORE_SE05X_DISPLAY_INFO=n CFG_CORE_SE05X_I2C_BUS=3 CFG_CORE_SE05X_SCP03_EARLY=y CFG_CORE_SE05X_SCP03_PROVISION_ON_INIT=n CFG_CORE_SE05X_SCP03_PROVISION=y CFG_CORE_SE05X_INIT_NVM=n CFG_CORE_SE05X_OEFID=0xA200', \
    '', d)} \
"
