# Recipe created by recipetool
# This is the basis of a recipe and may need further editing in order to be fully functional.
# (Feel free to remove these comments when editing.)

# WARNING: the following LICENSE and LIC_FILES_CHKSUM values are best guesses - it is
# your responsibility to verify that the values are complete and correct.
LICENSE = "LGPL-2.1-only"
LIC_FILES_CHKSUM = "file://LICENSE;md5=1803fa9c2c3ce8cb06b4861d75310742"

SRC_URI = "git://github.com/Mimoja/pyImprov.git;protocol=https;branch=main \
           file://onboarding-server.py \
           file://improv.service \
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
}

FILES:${PN} = "${datadir}/improv/*.py"

RDEPENDS:${PN} = "python3-bless python3-nmcli"

SYSTEMD_SERVICE:${PN} = "improv.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"
