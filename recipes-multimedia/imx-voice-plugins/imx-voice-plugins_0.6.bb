DESCRIPTION = "NXP i.MX Voice Plugins"
SECTION = "multimedia"
DEPENDS = "gstreamer1.0"
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = "file://LA_OPT_NXP_Software_License.txt;md5=d16137f4fa2adc98c4ab84b806182303"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = " \
            file://gst-plugin/libgstimx_ai_aecnr.so \
            file://gst-plugin/libgstimx_ai_dual_aecnr.so \
            file://gst-plugin/libgstimx_ai_nr.so \
            file://gst-plugin/libgstimxvit.so \
"

do_install () {
  install -d ${D}usr/local/lib/gstreamer-1.0
  install -m 755 ${B}/gst-plugin/libgstimx_ai_aecnr.so ${D}${libdir}/gstreamer-1.0
  install -m 755 ${B}/gst-plugin/libgstimx_ai_dual_aecnr.so ${D}${libdir}/gstreamer-1.0
  install -m 755 ${B}/gst-plugin/libgstimx_ai_nr.so ${D}${libdir}gstreamer-1.0
  install -m 755 ${B}/gst-plugin/libgstimxvit.so ${D}${libdir}/gstreamer-1.0
}
