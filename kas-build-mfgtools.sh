#!/bin/sh

# TODO: Look at this to fix missing key issue
#
#conf/machine/include/lmp-factory-custom.inc:OPTEE_TA_SIGN_KEY = "${TOPDIR}/conf/factory-keys/opteedev.key"
#lmp-tools/scripts/rotate_ci_keys.sh:openssl genpkey -algorithm RSA -out factory-keys/opteedev.key \
#lmp-tools/scripts/rotate_ci_keys.sh:openssl req -batch -new -x509 -key factory-keys/opteedev.key -out factory-keys/opteedev.crt

if [ ! -d ~/yocto ]
then
  mkdir -p -m 777 ~/yocto
  mkdir -p -m 777 ~/yocto/downloads
  mkdir -p -m 777 ~/yocto/persistent
  mkdir -p -m 777 ~/yocto/sstate
fi
kas-container --runtime-args "-v ${HOME}/yocto:/var/cache" build kas/lmp-dynamicdevices-mfgtool.yml
