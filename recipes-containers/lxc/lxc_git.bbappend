# lxc meson+ninja fails at configure when clang ThinLTO is enabled but the
# default Yocto linker is ld.bfd:
#   ERROR: LLVM's ThinLTO only works with gold, lld, lld-link, ld64 or mold, not ld.bfd
EXTRA_OEMESON:append = " -Db_lto=false"
