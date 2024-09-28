FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

LICENSE = "GPL-3.0-or-later"
LIC_FILES_CHKSUM ?= "file://${COMMON_LICENSE_DIR}/GPL-3.0-or-later;md5=1c76c4cc354acaac30ed4d5eefea7245"

SRC_URI = "file://setup-wifi-hotspot.sh"

do_install() {
  install -d ${D}${bindir}
  install -m 755 ${WORKDIR}/setup-wifi-hotspot.sh ${D}${bindir}
}

FILES:${PN} = "${bindir}/setup-wifi-hotspot.sh"

pkg_postinst_ontarget:${PN} () {
  #!/bin/sh
  echo Setting up WiFi Hotspot connectivity
  setup-wifi-hotspot.sh &
}