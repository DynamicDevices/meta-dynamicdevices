#!/bin/sh

if [ ! -d ~/yocto ]
then
  mkdir -p -m 777 ~/yocto
  mkdir -p -m 777 ~/yocto/downloads
  mkdir -p -m 777 ~/yocto/persistent
  mkdir -p -m 777 ~/yocto/sstate
fi
kas-container --runtime-args "-v ${HOME}/yocto:/var/cache" build kas/lmp-dynamicdevices-base.yml
