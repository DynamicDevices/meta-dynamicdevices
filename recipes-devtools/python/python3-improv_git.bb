# Recipe created by recipetool
# This is the basis of a recipe and may need further editing in order to be fully functional.
# (Feel free to remove these comments when editing.)

# WARNING: the following LICENSE and LIC_FILES_CHKSUM values are best guesses - it is
# your responsibility to verify that the values are complete and correct.
LICENSE = "LGPL-2.1-only"
LIC_FILES_CHKSUM = "file://LICENSE;md5=1803fa9c2c3ce8cb06b4861d75310742"

# Extend file search path to include machine-specific directories
# Yocto will automatically look in ${MACHINE}/ before recipe directory
FILESEXTRAPATHS_prepend := "${THISDIR}:"

SRC_URI = "git://github.com/Mimoja/pyImprov.git;protocol=https;branch=main \
           file://improv.service \
           file://onboarding-server.py \
           ${@bb.utils.contains('MACHINE', 'imx93-jaguar-eink', 'file://improv-eink.service file://onboarding-server-eink.py', '', d)} \
"

SRCREV = "635a49d244f6989803cd426921d645f9b4c29622"

S = "${WORKDIR}/git"

inherit systemd

do_configure() {
}

do_compile() {
}

do_install() {
  install -d ${D}/${datadir}/improv
  install -D -m 0755 ${S}/*.py ${D}${datadir}/improv
  install -D -m 0755 ${WORKDIR}/*.py ${D}${datadir}/improv
  chmod a+x ${D}${datadir}/improv
  install -d ${D}/${systemd_unitdir}/system
  install -m 0644 ${WORKDIR}/improv.service ${D}/${systemd_unitdir}/system
  
  # Install machine-specific files if they exist (Yocto automatically picks up ${MACHINE}/*)
  # For imx93-jaguar-eink: installs improv-eink.service and onboarding-server-eink.py
  # For other machines: these files don't exist, so nothing is installed
  if [ -f ${WORKDIR}/improv-eink.service ]; then
    install -m 0644 ${WORKDIR}/improv-eink.service ${D}/${systemd_unitdir}/system
  fi
  if [ -f ${WORKDIR}/onboarding-server-eink.py ]; then
    install -m 0755 ${WORKDIR}/onboarding-server-eink.py ${D}${datadir}/improv
  fi
}

FILES:${PN} = "${datadir}/improv/*.py \
               ${systemd_unitdir}/system/improv.service \
"

# Conditionally include machine-specific service file if it exists
FILES:${PN} += "${@bb.utils.contains('MACHINE', 'imx93-jaguar-eink', '${systemd_unitdir}/system/improv-eink.service', '', d)}"

RDEPENDS:${PN} = "python3-bless python3-nmcli"

# Use machine-specific service if it exists, otherwise use default
# Yocto automatically picks up files from ${MACHINE}/ subdirectory
SYSTEMD_SERVICE:${PN} = "${@bb.utils.contains('MACHINE', 'imx93-jaguar-eink', 'improv-eink.service', 'improv.service', d)}"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"
