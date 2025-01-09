FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = "file://iptables.rules"

SYSTEMD_AUTO_ENABLE_${PN} = "disable"
