#!/usr/bin/env bash
# Phase 2/3: kernel build.  OWNER: kernel repo.  MUST run AFTER buildbl.
#
# Ordering: the netdeploy initrd embeds ../../build/bootloader/esp.img
# (factory-first-boot ESP install); a missing esp.img silently produces an
# initrd that can partition but not populate a virgin device.
#
# Contract (consumed by the main build's ramdeploy assembly):
#   outputs in  ../../build/kernel/
#     ramdeploy/{bootcfg,kernel,dtb,initrd,initrd_debug}_ramdeploy.bin
#                 RAW (no BootApp prefix) TestBootApp RAM-staging set
#     tools/makeblob  tools/deployclient      host deploy tools
#     debs/linux-{firmware-iceland,headers,image,modules}_*_arm64.deb
#     kernel.img dtb.img initrd_debug.img initrd_charge.img  (+ .img set)
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${SRC}/../build/kernel"

log() { printf '[buildkernel] %s\n' "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }

command -v podman >/dev/null 2>&1 || die "podman not found"
[ -x "${SRC}/kernel/build.sh" ] || die "kernel submodule missing (git submodule update --init)"

# bl dependency: the initrd embeds the bootloader's ESP image
if [ -f "${SRC}/../build/bootloader/esp.img" ]; then
    log "bl esp.img present ($(du -h "${SRC}/../build/bootloader/esp.img" | cut -f1))"
else
    log "WARNING: no ../build/bootloader/esp.img -- firstboot ESP install disabled"
fi

# the kernel repo's own orchestrator: container stages, incremental kbuild,
# verify gate; OUT defaults to exactly the contract location above
log "running kernel/build.sh -> ${OUT}"
bash "${SRC}/kernel/build.sh" "${OUT}"

# contract self-check (the main build re-checks before assembly)
for f in \
    ramdeploy/bootcfg_ramdeploy.bin ramdeploy/kernel_ramdeploy.bin \
    ramdeploy/dtb_ramdeploy.bin ramdeploy/initrd_ramdeploy.bin \
    ramdeploy/initrd_debug_ramdeploy.bin \
    tools/makeblob tools/deployclient \
    kernel.img dtb.img initrd_debug.img initrd_charge.img; do
    [ -e "${OUT}/${f}" ] || die "contract output missing after build: ${f}"
done
for g in linux-firmware-iceland*_arm64.deb linux-headers-*_arm64.deb \
         linux-image-*_arm64.deb linux-modules-*_arm64.deb; do
    ls "${OUT}"/debs/${g} >/dev/null 2>&1 || die "contract output missing: debs/${g}"
done
log "contract outputs verified in ${OUT}"
