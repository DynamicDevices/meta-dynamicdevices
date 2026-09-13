# Product tuple lifecycle

## Deprecated on 13 September 2026

The product owner has retired CI builds for these machine families:

- `imx8mm-jaguar-inst`
- `imx8mm-jaguar-phasora`

The retirement covers normal factory images and mfgtool/recovery images. For
Foundries CI it also covers the `main-jaguar-phasora`,
`main-jaguar-phasora-ext`, and `main-jaguar-inst` refs.

These tuples are intentionally absent from `ci/layer-adoption-tuples.json` and
must not be treated as accidentally deleted regression coverage. Board source
may remain in the repository for history or possible future reactivation, but
reactivation requires an explicit product decision and restoration of both
image and recovery coverage. Every other existing product tuple remains
protected by the layer-adoption gate.
