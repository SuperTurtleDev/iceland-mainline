#!/usr/bin/env bash
# Phase 1/3: bootloader build.  OWNER: bootloader repo.
#
# Contract (consumed by the main build and the kernel phase):
#   outputs in  ../../build/bootloader/
#     BootApp.efi  BootUtil.efi  TestBootApp.efi   EFI applications
#     esp.img      Android-sparse FAT32 (1 GiB) carrying the ESP content;
#                  the kernel phase embeds it into the netdeploy initrd for
#                  the factory-first-boot ESP install
#     symbols/     link-time ELF .dll + linker maps (debug artifacts)
#     buildinfo.txt  provenance (meta/submodule/container hashes)
#
# Thin wrapper: delegates to ../bootloader/build.sh (shared container via
# ../podman_container/runin.sh, incremental OUT/build, BOOTLOADER_* knobs).
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${SRC}/../build/bootloader"

log() { printf '[buildbl] %s\n' "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }

command -v podman >/dev/null 2>&1 || die "podman not found"
[ -x "${SRC}/bootloader/build.sh" ] || die "bootloader/build.sh missing or not executable"

# the bootloader repo's own orchestrator; OUT defaults to exactly the
# contract location above, pass it explicitly anyway
log "running bootloader/build.sh -> ${OUT}"
OUT="${OUT}" bash "${SRC}/bootloader/build.sh"

# contract self-check (the kernel phase re-checks esp.img before embedding)
for f in BootApp.efi BootUtil.efi TestBootApp.efi esp.img \
         symbols/BootApp.dll symbols/BootApp.map buildinfo.txt; do
    [ -e "${OUT}/${f}" ] || die "contract output missing after build: ${f}"
done
log "contract outputs verified in ${OUT}"
