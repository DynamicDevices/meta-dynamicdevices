#!/bin/sh

# Keep local KAS wrappers on the exact container image exercised by the
# layer-adoption gate. Update the workflow and its parity test with this pin.
KAS_CONTAINER_IMAGE="ghcr.io/siemens/kas/kas@sha256:d989add57fc441fe9e27bb2dd6ed98c5597b44c807928e35a72dc1cfbdda9abe"
export KAS_CONTAINER_IMAGE
