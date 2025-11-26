SUMMARY = "Test ELE utility"
DESCRIPTION = "Simple test for ELE functionality"
LICENSE = "MIT"
LIC_FILES_CHKSUM = ""

do_compile() {
    echo '#!/bin/bash' > ${B}/test-ele
    echo 'echo "ELE test utility - checking hardware..."' >> ${B}/test-ele
    echo 'ls -la /sys/bus/platform/devices/44230000.mailbox 2>/dev/null || echo "ELE mailbox not found"' >> ${B}/test-ele
    echo 'ls -la /sys/bus/nvmem/devices/ELE-OCOTP0 2>/dev/null || echo "ELE OCOTP not found"' >> ${B}/test-ele
    chmod +x ${B}/test-ele
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${B}/test-ele ${D}${bindir}/
}

FILES:${PN} = "${bindir}/test-ele"
