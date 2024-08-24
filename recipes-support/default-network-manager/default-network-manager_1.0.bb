FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

LICENSE = "GPL-3.0-or-later"
LIC_FILES_CHKSUM ?= "file://${COMMON_LICENSE_DIR}/GPL-3.0-or-later;md5=1c76c4cc354acaac30ed4d5eefea7245"

SRC_URI = "file://setup_network_manager.sh"

do_install() {
  install -d ${D}${bindir}
  install -m 755 ${WORKDIR}/setup_network_manager.sh ${D}${bindir}
}

FILES_${PN} = "${bindir}/setup_network_manager.sh"

pkg_postinst_ontarget:${PN} () {
  #!/bin/sh
  echo Setting up Network Manager connectivity
  setup_network_manager.sh &
}