#!/bin/sh

# Build mfgtool images for i.MX93 machines
#
# Usage: 
#   KAS_MACHINE=imx93-jaguar-eink ./kas-build-mfgtools.sh
#   KAS_MACHINE=imx93-11x11-lpddr4x-evk ./kas-build-mfgtools.sh
#
# Supports both imx93-jaguar-eink and imx93-11x11-lpddr4x-evk machines

# Set default machine if not specified
if [ -z "$KAS_MACHINE" ]; then
    export KAS_MACHINE="imx93-11x11-lpddr4x-evk"
    echo "No KAS_MACHINE specified, defaulting to $KAS_MACHINE"
else
    echo "Building mfgtool for machine: $KAS_MACHINE"
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

# Pass KAS_MACHINE to kas-container to override the machine in the config file
# Include SSH support for private repositories
kas-container --ssh-agent --ssh-dir ${HOME}/.ssh --runtime-args "-v ${HOME}/yocto:/var/cache -e KAS_MACHINE=$KAS_MACHINE" build kas/lmp-dynamicdevices-mfgtool.yml
