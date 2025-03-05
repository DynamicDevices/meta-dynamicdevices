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
  echo
  exit 1
fi

# Customise the uuu script for the MACHINE
sed "s/MACHINE/${KAS_MACHINE}/g" program_full_image.uuu.in > program_full_image.uuu

# Program the board
export DIRNAME=`dirname ${0}`
sudo ${DIRNAME}/uuu ${DIRNAME}/program_full_image.uuu

# Tidy up
rm ${DIRNAME}/program_full_image.uuu
