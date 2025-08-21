#!/bin/sh

#
# We need the environment variable KAS_MACHINE set so we know which files to program
#
if [ -z "${KAS_MACHINE}" ]
then
  echo
  echo Set environment variable ${KAS_MACHINE} to one of the supported machine builds:
  echo
  echo e.g.
  echo
  echo KAS_MACHINE=sentai ./program.sh
  echo KAS_MACHINE=inst ./program.sh
  echo KAS_MACHINE=phasora ./program.sh
  echo KAS_MACHINE=imx93-11x11-lpddr4x-evk ./program.sh
  exit 1
fi

# Customise the uuu script for the MACHINE
sed 's/$KAS_MACHINE/'${KAS_MACHINE}'/g' program/program_full_image.uuu.in > program/program_full_image.uuu

# Program the board
export DIRNAME=`dirname ${0}`/program
sudo ${DIRNAME}/uuu ${DIRNAME}/program_full_image.uuu

# Tidy up
rm ${DIRNAME}/program_full_image.uuu
