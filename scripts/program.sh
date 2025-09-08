#!/bin/sh

#
# DEPRECATED: This script is deprecated and should not be used.
# Use fio-program-board.sh instead for proper Foundries.io integration.
#

echo "============================================================"
echo "WARNING: This script is DEPRECATED and should not be used!"
echo "============================================================"
echo ""
echo "This script creates its own UUU programming script from a template,"
echo "which is incorrect and may cause programming failures."
echo ""
echo "CORRECT USAGE:"
echo ""
echo "For LOCAL BUILDS (development):"
echo "  ./scripts/program-local-build.sh --machine imx93-jaguar-eink"
echo "  ./scripts/program-local-build.sh --machine imx8mm-jaguar-sentai"
echo "  ./scripts/program-local-build.sh --machine imx8mm-jaguar-phasora"
echo ""
echo "For FOUNDRIES.IO CLOUD BUILDS (production):"
echo "  ./scripts/fio-program-board.sh --machine imx8mm-jaguar-sentai --target <target-number> --program"
echo "  ./scripts/fio-program-board.sh --machine imx93-jaguar-eink --target <target-number> --program"
echo "  ./scripts/fio-program-board.sh --machine imx8mm-jaguar-phasora --target <target-number> --program"
echo ""
echo "For more information:"
echo "  ./scripts/program-local-build.sh --help"
echo "  ./scripts/fio-program-board.sh --help"
echo ""
echo "============================================================"
exit 1

# OLD DEPRECATED CODE BELOW - DO NOT USE
if [ -z "${KAS_MACHINE}" ]
then
  echo
  echo "Set environment variable \${KAS_MACHINE} to one of the supported machine builds:"
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
sed "s/\$KAS_MACHINE/${KAS_MACHINE}/g" program/program_full_image.uuu.in > program/program_full_image.uuu

# Program the board
DIRNAME=$(dirname "${0}")/program
export DIRNAME
sudo "${DIRNAME}"/uuu "${DIRNAME}"/program_full_image.uuu

# Tidy up
rm "${DIRNAME}"/program_full_image.uuu
