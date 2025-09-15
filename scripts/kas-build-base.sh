#!/bin/sh

# TODO: Look at this to fix missing key issue
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
# If no arguments provided, build the default image
if [ $# -eq 0 ]; then
    kas-container --ssh-agent --ssh-dir ${HOME}/.ssh --runtime-args "-v ${HOME}/yocto:/var/cache" build kas/lmp-dynamicdevices-base.yml
else
    # Pass through all arguments for BitBake commands like -c cleansstate, -c show-versions, etc.
    # KAS shell expects: kas-container shell <config.yml> -c "bitbake <args>"
    kas-container --ssh-agent --ssh-dir ${HOME}/.ssh --runtime-args "-v ${HOME}/yocto:/var/cache" shell kas/lmp-dynamicdevices-base.yml -c "bitbake $*"
fi
