# We are doing this file removal as INSANE_SKIP and package removal doesn't seem to work
# And these files break the build when multilib is enabled
inherit logging

# TODO: This needs to be removed based on multilib enablement
do_install:append() {
  bbwarn Removing files that break multilib build
  rm -rf ${D}/usr/lib64/cryptsetup
}
