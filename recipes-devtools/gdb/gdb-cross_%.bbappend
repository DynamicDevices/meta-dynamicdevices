# Only enable TUI for Dynamic Devices machines to avoid unconditional task signature changes
PACKAGECONFIG:append:imx8mm-jaguar-sentai = " tui"
PACKAGECONFIG:append:imx8mm-jaguar-inst = " tui"
PACKAGECONFIG:append:imx8mm-jaguar-handheld = " tui"
PACKAGECONFIG:append:imx8mm-jaguar-phasora = " tui"
PACKAGECONFIG:append:imx93-jaguar-eink = " tui"
