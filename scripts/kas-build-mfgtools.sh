#!/bin/sh

script_dir=$(CDPATH='' cd -P "$(dirname "$0")" && pwd)
# shellcheck source=kas-container-image.sh
. "$script_dir/kas-container-image.sh"

# Build mfgtool images for supported i.MX machines
#
# Usage:
#   KAS_MACHINE=imx95-frdm-evk ./scripts/kas-build-mfgtools.sh
#   KAS_MACHINE=imx93-jaguar-eink ./scripts/kas-build-mfgtools.sh
#   KAS_MACHINE=imx93-11x11-lpddr4x-evk ./scripts/kas-build-mfgtools.sh
#
# The machine-specific BSP selects the correct imx-boot manufacturing target.

# Set default machine if not specified
if [ -z "$KAS_MACHINE" ]; then
    export KAS_MACHINE="imx93-11x11-lpddr4x-evk"
    echo "No KAS_MACHINE specified, defaulting to $KAS_MACHINE"
else
    echo "Building mfgtool for machine: $KAS_MACHINE"
fi

KAS_CONFIG="kas/lmp-dynamicdevices-mfgtool.yml"
if [ "$KAS_MACHINE" = "imx95-frdm-evk" ]; then
    # Keep local validation aligned with the Foundries manifest revisions used
    # for FRDM-i.MX95 production builds.
    KAS_CONFIG="kas/lmp-imx95-frdm-evk-mfgtool.yml"
fi

# TODO: Look at this to fix missing key issue if needed
#
#conf/machine/include/lmp-factory-custom.inc:OPTEE_TA_SIGN_KEY = "${TOPDIR}/conf/factory-keys/opteedev.key"
#lmp-tools/scripts/rotate_ci_keys.sh:openssl genpkey -algorithm RSA -out factory-keys/opteedev.key \
#lmp-tools/scripts/rotate_ci_keys.sh:openssl req -batch -new -x509 -key factory-keys/opteedev.key -out factory-keys/opteedev.crt

if [ ! -d ~/yocto ]
then
  mkdir -p ~/yocto
  mkdir -p ~/yocto/downloads
  mkdir -p ~/yocto/persistent
  mkdir -p ~/yocto/sstate
  chmod 755 ~/yocto
  chmod 755 ~/yocto/downloads
  chmod 755 ~/yocto/persistent
  chmod 755 ~/yocto/sstate
fi

# Pass KAS_MACHINE to kas-container to override the machine in the config file.
# Forward SSH credentials only when they exist; the standard layer URLs are HTTPS,
# so unattended builders such as ai-tools do not require an SSH agent.
set -- --runtime-args "-v ${HOME}/yocto:/var/cache -e KAS_MACHINE=$KAS_MACHINE"
if [ -n "${SSH_AUTH_SOCK:-}" ] && [ -S "${SSH_AUTH_SOCK}" ]; then
    set -- --ssh-agent "$@"
fi
if [ -d "${HOME}/.ssh" ]; then
    set -- --ssh-dir "${HOME}/.ssh" "$@"
fi

kas-container "$@" build "$KAS_CONFIG"
