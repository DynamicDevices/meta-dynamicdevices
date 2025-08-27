# Workaround for SPDX generation issue with cross-architecture dependencies
# The SPDX generation fails when looking up aktualizr dependency due to 
# architecture-specific sstate path mismatch
#
# This is a known issue in Yocto SPDX generation for allarch recipes that
# depend on architecture-specific recipes
#
# Since this recipe only installs a configuration file and doesn't contain
# source code, disabling SPDX generation is acceptable

# Disable SPDX generation for this recipe to work around the lookup issue
INHERIT:remove = "create-spdx"

# Alternative: Skip SPDX tasks entirely
do_create_spdx[noexec] = "1"
do_create_runtime_spdx[noexec] = "1"
