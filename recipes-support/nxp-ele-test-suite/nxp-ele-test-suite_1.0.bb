SUMMARY = "NXP EdgeLock Enclave (ELE) Test Suite for i.MX93"
DESCRIPTION = "NXP Secure Enclave Userspace Library and test applications for i.MX93 EdgeLock Enclave functionality testing"
HOMEPAGE = "https://github.com/nxp-imx/imx-secure-enclave"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=8636bd68fc00cc6a3809b7b58b45f982"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://simple-ele-test.c"

DEPENDS = "openssl"
RDEPENDS:${PN} = "openssl-bin"

# Compatible only with i.MX93 machines that have EdgeLock Enclave
COMPATIBLE_MACHINE = "(imx93-jaguar-eink|imx93-11x11-lpddr4x-evk)"

# For now, we'll focus on our reliable simple test utility
# The NXP repository can be added later when branch issues are resolved
SRC_URI = "file://simple-ele-test.c"

S = "${WORKDIR}"

# Build configuration for i.MX93
EXTRA_OEMAKE = " \
    PLAT=imx93 \
    OPENSSL_DIR=${STAGING_DIR_HOST}${prefix} \
    CC='${CC}' \
    CXX='${CXX}' \
    CFLAGS='${CFLAGS}' \
    CXXFLAGS='${CXXFLAGS}' \
    LDFLAGS='${LDFLAGS}' \
"

do_compile() {
    # Create build directory
    mkdir -p ${S}/build/imx93
    
    # Compile our simple ELE test utility
    bbnote "Compiling simple ELE test utility"
    ${CC} ${CFLAGS} ${LDFLAGS} ${WORKDIR}/simple-ele-test.c \
        -o ${S}/build/imx93/simple-ele-test || bbfatal "Failed to compile simple ELE test"
}

do_install() {
    # Install test applications
    install -d ${D}${bindir}
    
    # Install our simple ELE test utility
    install -m 0755 ${S}/build/imx93/simple-ele-test ${D}${bindir}/
    
    # Create a simple test runner script
    cat > ${D}${bindir}/run-ele-tests << 'EOF'
#!/bin/bash
# ELE Test Runner Script
# Run this script to execute all available ELE tests

echo "=== EdgeLock Enclave Test Suite ==="
echo "Target: i.MX93 EdgeLock Enclave"
echo ""

# Run our simple ELE test
if command -v simple-ele-test >/dev/null 2>&1; then
    echo "=== Running ELE Hardware Test ==="
    simple-ele-test all
    echo ""
else
    echo "ERROR: simple-ele-test not found"
    exit 1
fi

echo "=== ELE Test Suite Complete ==="
EOF
    chmod +x ${D}${bindir}/run-ele-tests
}

# Package the test applications and libraries
PACKAGES = "${PN} ${PN}-dev ${PN}-dbg"

FILES:${PN} = " \
    ${bindir}/simple-ele-test \
    ${bindir}/run-ele-tests \
"

# Ensure the package is only built for compatible machines
python () {
    machine = d.getVar('MACHINE')
    compatible = d.getVar('COMPATIBLE_MACHINE')
    if not machine or not compatible:
        return
    
    import re
    if not re.match(compatible, machine):
        raise bb.parse.SkipRecipe("Machine %s not compatible with %s" % (machine, compatible))
}
