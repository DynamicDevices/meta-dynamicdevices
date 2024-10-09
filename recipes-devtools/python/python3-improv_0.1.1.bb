# Recipe created by recipetool
# This is the basis of a recipe and may need further editing in order to be fully functional.
# (Feel free to remove these comments when editing.)

# WARNING: the following LICENSE and LIC_FILES_CHKSUM values are best guesses - it is
# your responsibility to verify that the values are complete and correct.
LICENSE = "LGPL-2.1-only"
LIC_FILES_CHKSUM = "file://LICENSE;md5=1803fa9c2c3ce8cb06b4861d75310742"

SRC_URI = "git://github.com/Mimoja/pyImprov.git;protocol=https;branch=main"
SRCREV = "d83c0f7c152737de13132533b7d65d4a1e07f6c1"

S = "${WORKDIR}/git"

do_configure() {
}

do_compile() {
}

do_install() {
  install -d ${D}/${datadir}/improv
  install -D -m 0755 ${S}/*.py ${D}${datadir}/improv
  chmod a+x ${D}${datadir}/improv
}

FILES:${PN} = "${datadir}/improv/*.py"

RDEPENDS:${PN} = "python3-bless"
