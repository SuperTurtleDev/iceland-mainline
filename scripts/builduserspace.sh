#!/usr/bin/env bash
# Phase 3/3: userspace (rootfs) build.  OWNER: userspace repo.
#
# Contract (consumed by the main build's ramdeploy assembly):
#   outputs in  ../../build/userspace/
#     rootfs-ubuntu_desktop-fastcharge.sparse.img   <-- required by the
#         desktop-fastcharge ramdeploy variant (Android sparse ext4)
#     (other variants -- rootfs, rootfs-debug, rootfs-fastcharge,
#      rootfs-ubuntu_desktop-debug, ... -- are produced by the same
#      pipeline on demand and land next to it, but are not assembled)
#
# Knobs:
#   PRESENTS   comma-separated preset list            (default:
#              ubuntu_desktop,fastcharge -- the desktop ramdeploy variant;
#              pass e.g. PRESENTS=fastcharge for the light variant,
#              PRESENTS="" for the bare base)
#   MIRROR     apt mirror override (default: official ports.ubuntu.com;
#              point at a local mirror for faster builds)
#   extra argv is forwarded to userspace/build.sh verbatim
#
# The userspace pipeline builds on the host under a single sudo elevation
# (debootstrap + chroot via qemu-aarch64 binfmt); build.sh re-execs itself
# under sudo when run unprivileged.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${SRC}/../build/userspace"

log() { printf '[builduserspace] %s\n' "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }

[ -x "${SRC}/userspace/build.sh" ] || die "userspace/build.sh missing"

PRESENTS="${PRESENTS-ubuntu_desktop,fastcharge}"

# the userspace repo's own orchestrator: host debootstrap + presets +
# verify gate; artifacts default to exactly the contract location above
log "running userspace/build.sh --addition-presents ${PRESENTS:-<none>}"
if [ -n "${PRESENTS}" ]; then
    bash "${SRC}/userspace/build.sh" --addition-presents "${PRESENTS}" "$@"
else
    bash "${SRC}/userspace/build.sh" "$@"
fi

# contract self-check (the main build re-checks before assembly)
NAME="rootfs"
if [ -n "${PRESENTS}" ]; then
    NAME="rootfs-$(echo "${PRESENTS}" | tr ',' '-')"
fi
for f in "${NAME}.img" "${NAME}.sparse.img" SHA256SUMS buildinfo.txt; do
    [ -e "${OUT}/${f}" ] || die "contract output missing after build: ${f}"
done
log "contract outputs verified in ${OUT} (${NAME})"
