#!/bin/sh
# imx95-frdm-evk KAS smoke tests (parse, then optional full build)
set -e

KAS_CFG="kas/lmp-imx95-frdm-evk-smoke.yml"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1

sync_machine() {
  name="$1"
  dst="${ROOT}/meta-dynamicdevices-bsp/conf/machine/${name}"
  esl="${ROOT}/../../esl/meta-dynamicdevices-bsp/conf/machine/${name}"
  if [ -f "$esl" ] && { [ ! -f "$dst" ] || [ "$esl" -nt "$dst" ]; }; then
    echo "Syncing ${name} from esl/meta-dynamicdevices-bsp..."
    cp "$esl" "$dst"
  fi
  if [ ! -f "$dst" ]; then
    echo "error: ${name} not found in BSP layer" >&2
    exit 1
  fi
}

sync_machine imx95-15x15-lpddr4x-frdm.conf
sync_machine imx95-frdm-evk.conf

mkdir -p "${HOME}/yocto/downloads" "${HOME}/yocto/sstate" "${HOME}/yocto/persistent"

kas_run() {
  kas-container --ssh-agent --ssh-dir "${HOME}/.ssh" \
    --runtime-args "-v ${HOME}/yocto:/var/cache" \
    "$@"
}

cmd="${1:-parse}"

case "$cmd" in
  parse)
    echo "=== Smoke 1: kas checkout (fetch layers) ==="
    kas_run checkout "$KAS_CFG"
    echo "=== Smoke 2: bitbake -e (machine parse) ==="
    kas_run shell "$KAS_CFG" -c "grep -q 'imx95-frdm-evk' conf/local.conf && bitbake -e >/dev/null && echo 'machine parse OK: imx95-frdm-evk'"
    echo "=== Smoke 3: bitbake-layers show-layers (imx / dynamicdevices) ==="
    kas_run shell "$KAS_CFG" -c "bitbake-layers show-layers 2>/dev/null | grep -E 'imx|dynamicdevices' | head -15"
    echo "=== Smoke 4: parse lmp-factory-image ==="
    kas_run shell "$KAS_CFG" -c "bitbake -p lmp-factory-image 2>&1 | tail -5"
    echo "=== parse OK ==="
    ;;
  build)
    echo "=== Full image build: lmp-factory-image ==="
    kas_run build "$KAS_CFG"
    ;;
  shell)
    shift
    kas_run shell "$KAS_CFG" "$@"
    ;;
  *)
    echo "Usage: $0 {parse|build|shell ...}" >&2
    exit 1
    ;;
esac
