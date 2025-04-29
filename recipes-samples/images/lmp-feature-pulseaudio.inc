CORE_IMAGE_BASE_INSTALL += " \
  pulseaudio \
  pulseaudio-server \
  pulseaudio-misc \
"

CORE_IMAGE_BASE_INSTALL:append:imx8mm-jaguar-sentai = " \
  sox \
"
