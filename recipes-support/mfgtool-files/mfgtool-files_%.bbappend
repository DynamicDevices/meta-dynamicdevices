FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Override for imx93 machines when using mfgtool distro
# The mfgtool distro produces cpio.gz files, not fitImage files
do_deploy:prepend:mx93-nxp-bsp() {
    install -d ${DEPLOYDIR}/${PN}
    install -m 0644 ${DEPLOY_DIR_IMAGE}/imx-boot ${DEPLOYDIR}/${PN}/imx-boot-mfgtool
    install -m 0644 ${DEPLOY_DIR_IMAGE}/u-boot.itb ${DEPLOYDIR}/${PN}/u-boot-mfgtool.itb
    # Use the cpio.gz file instead of fitImage for mfgtool distro
    #install -m 0644 ${DEPLOY_DIR_IMAGE}/${INITRAMFS_IMAGE}-${MACHINE}.cpio.gz ${DEPLOYDIR}/${PN}/${INITRAMFS_IMAGE}-${MACHINE}.cpio.gz
}
