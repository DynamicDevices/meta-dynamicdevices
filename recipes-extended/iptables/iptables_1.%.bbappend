FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = "file://iptables.rules"

