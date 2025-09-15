#!/bin/sh

# KAS Shell Base Script
# Usage: ./kas-shell-base.sh [options]
#   -c "command"  : Execute command in kas environment
#   (no args)     : Start interactive shell

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

# Pass all arguments to kas-container shell command
kas-container --ssh-agent --ssh-dir ${HOME}/.ssh --runtime-args "-v ${HOME}/yocto:/var/cache" shell kas/lmp-dynamicdevices-base.yml "$@"
