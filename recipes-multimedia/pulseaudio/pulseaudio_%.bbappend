FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

inherit systemd

SYSTEMD_SERVICE:${PN} = "pulseaudio.service"
SYSTEMD_AUTO_ENABLE:${PN}  = "enable"

PACKAGECONFIG += " webrtc"
REPENDS:${PN} += " webrtc"
 
SRC_URI:append = "\
    file://pulseaudio.service \
    file://load-unix-module.pa \
"

do_install:append() {
        install -d ${D}/${systemd_unitdir}/system
        install -m 0644 ${WORKDIR}/pulseaudio.service ${D}/${systemd_unitdir}/system
        install -d ${D}/${sysconfdir}/pulse/system.pa.d
        install -m 0644 ${WORKDIR}/load-unix-module.pa ${D}/${sysconfdir}/pulse/system.pa.d

        # We need to ignore the ALSA dB information provided to PulseAudio or the volume control is broken
	sed -i 's/load-module module-udev-detect/load-module module-udev-detect ignore_dB=true/g' ${D}/${sysconfdir}/pulse/system.pa
}

FILES:${PN}:append = "${systemd_unitdir}/system/pulseaudio.service ${sysconfdir}/pulse/load-unix-module.pa"
