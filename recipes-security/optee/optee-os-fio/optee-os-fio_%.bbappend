FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://se05x_mw_v04.05.01.zip;name=se050-mw \
"

SRC_URI[se050-mw.md5sum] = "d1f0553ec6e3a9a70d7be9d3183921f9"
SRC_URI[se050-mw.sha256sum] = "6d0c2799475dfb304d159909cdcf8c7e2a38d6596c3e3205224da685b4b204f6"

do_compile:prepend() {
    # Link SE050 MW in order for it to available to OP-TEE
    ln -sf ${WORKDIR}/simw-top ${S}/lib/libnxpse050/se050/simw-top
}

EXTRA_OEMAKE:append:imx8mm-jaguar-sentai = " \
    CFG_IMX_I2C=y CFG_CORE_SE05X=y CFG_NXP_SE05X_RNG_DRV=n \
    CFG_NXP_CAAM_RSA_DRV=n CFG_NUM_THREADS=1 CFG_CORE_SE05X_DISPLAY_INFO=1 \
    CFG_CORE_SE05X_SCP03_EARLY=1 \
    CFG_CORE_SE05X_OEFID=0xA1F4 CFG_CORE_SE05X_I2C_BUS=4 \
"
