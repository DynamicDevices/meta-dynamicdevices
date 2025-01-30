# Recipe created by recipetool
# This is the basis of a recipe and may need further editing in order to be fully functional.
# (Feel free to remove these comments when editing.)

# WARNING: the following LICENSE and LIC_FILES_CHKSUM values are best guesses - it is
# your responsibility to verify that the values are complete and correct.
#
# The following license files were not able to be identified and are
# represented as "Unknown" below, you will need to check them yourself:
#   3rd_party/libs/bossa/LICENSE_BOSSA_BSD3.txt
#   external/strata/LICENSE
#   external/strata/contrib/rapidjson/license.txt
#   sdk/c/ifxAdvancedMotionSensing/license.txt
#   sdk/c/ifxRadarSegmentation/license.txt
#
# NOTE: multiple licenses have been detected; they have been separated with &
# in the LICENSE value for now since it is a reasonable assumption that all
# of the licenses apply. If instead there is a choice between the multiple
# licenses then you should change the value to separate the licenses with |
# instead of &. If there is any doubt, check the accompanying documentation
# to determine which situation is applicable.
LICENSE = "GPL-2.0-only & LGPL-2.1-only & MIT"
LIC_FILES_CHKSUM = "file://3rd_party/libs/argparse/LICENSE;md5=8c440aa75fef5b9fe1a00c897580066b \
                    file://3rd_party/libs/bossa/LICENSE_BOSSA_BSD3.txt;md5=a83ef45b4f39a7cb12d9dc11d2c0e623 \
                    file://3rd_party/libs/muFFT/COPYING;md5=5a66f218a4430df274bcddde2656c9c2 \
                    file://3rd_party/libs/muFFT/COPYING.GPLv2;md5=b234ee4d69f5fce4486a80fdaf4a4263 \
                    file://3rd_party/libs/nlohmann/LICENSE.txt;md5=dd0607f896f392c8b7d0290a676efc24 \
                    file://external/strata/LICENSE;md5=908a73b07b5c8a64487313726feeb388 \
                    file://external/strata/contrib/libusb/COPYING;md5=fbc093901857fcd118f065f900982c24 \
                    file://external/strata/contrib/pugixml/LICENSE.md;md5=297dbdec580de5365d8b69c3250629eb \
                    file://external/strata/contrib/rapidjson/license.txt;md5=ba04aa8f65de1396a7e59d1d746c2125 \
                    file://sdk/c/ifxAdvancedMotionSensing/license.txt;md5=a776397476d1327c006486da9a188726 \
                    file://sdk/c/ifxRadarSegmentation/license.txt;md5=a776397476d1327c006486da9a188726 \
                    file://sdk/py/wrapper_radarsdk/LICENSE.txt;md5=2b808264f161b58da3d816b7a2e6a918"

SRC_URI = "git://github.com/DynamicDevices/radar-sdk.git;protocol=https;branch=main"

# Modify these as desired
PV = "3.6.4"
SRCREV = "add1349d53d260737e75cda4d40cb9f0b391e63b"

S = "${WORKDIR}/git"

inherit cmake

# Specify any options you want to pass to cmake using EXTRA_OECMAKE:
EXTRA_OECMAKE = ""

do_install() {
  install -d ${D}${bindir}
  install -m 755 ${B}/bin/BGT* ${D}${bindir}
  install -m 755 ${B}/bin/bgt* ${D}${bindir}
  install -d ${D}${libdir}
  install -m 755 ${B}/bin/*.so ${D}${libdir}
}

FILES:${PN} += "${libdir}/*.so ${bindir}/*"

# TODO: We get an error relating to the -dev package which shouldn't have these libraries.
#       Maybe it's a build issue but for now let's just ensure there's nothing in the -dev package
FILES:${PN}-dev = ""


