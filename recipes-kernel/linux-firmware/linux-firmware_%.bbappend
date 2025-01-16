
# We are doing this file removal as INSANE_SKIP and package removal doesn't seem to work
# And these files break the build when multilib is enabled
inherit logging

# TODO: This needs to be removed based on multilib enablement
do_install:append() {
  bbwarn Removing files that break multilib build
  rm ${D}/usr/lib/firmware/qcom/sdm845/wlanmdsp.mbn
  rm ${D}/usr/lib/firmware/qcom/apq8016/modem.mbn
}

INSANE_SKIP:${PN} += " ldflags "
