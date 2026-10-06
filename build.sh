#!/usr/bin/env bash
# Main meta-repo orchestrator for the iceland (OnePlus Pad 4 / SM8850)
# mainline port.
#
#   ./build.sh
#
# Three phases, strictly in order -- each is owned by its subsystem repo
# (scripts are stubs until the owners fill them in):
#
#   scripts/buildbl.sh        bootloader: BootApp/TestBootApp/BootUtil EFI
#                             + esp.img (Android-sparse FAT32) into
#                             ../../build/bootloader/
#   scripts/buildkernel.sh    kernel MUST run after bl: the netdeploy initrd
#                             embeds ../../build/bootloader/esp.img for the
#                             factory-first-boot ESP install.  Produces
#                             images/debs/ramdeploy set into
#                             ../../build/kernel/
#   scripts/builduserspace.sh rootfs variants (debug / desktop /
#                             desktop-fastcharge sparse images) into
#                             ../../build/userspace/
#
# After the phases, this script assembles the deliverable:
#   ../artifacts/ramdeploy/   self-contained desktop-fastcharge RAM-deploy
#                             bundle (boot chain + kernel/dtb/bootcfg/initrd
#                             + deploy.blob + one-shot ramdeploy.sh)
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAINLINE="$(cd "${SRC}/.." && pwd)"
BL_OUT="${MAINLINE}/build/bootloader"
K_OUT="${MAINLINE}/build/kernel"
U_OUT="${MAINLINE}/build/userspace"
LOGS="${MAINLINE}/build/logs"
ART="${SRC}/../artifacts/ramdeploy"

log() { printf '[main-build] %s\n' "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }

for s in buildbl buildkernel builduserspace; do
    [ -f "${SRC}/scripts/${s}.sh" ] || die "missing scripts/${s}.sh"
done
mkdir -p "${LOGS}"

# --- phases (bl -> kernel -> userspace; kernel after bl for esp.img) --------
for phase in buildbl buildkernel builduserspace; do
    t0=$(date +%s)
    log "[${phase}] RUN (log: ${LOGS}/${phase}.log)"
    bash "${SRC}/scripts/${phase}.sh" 2>&1 | tee "${LOGS}/${phase}.log"
    printf '%s %ss\n' "${phase}" "$(( $(date +%s) - t0 ))" >> "${LOGS}/last-run.txt"
done

# --- required phase outputs --------------------------------------------------
need() { [ -e "$1" ] || die "phase output missing: $1 (fill in the owning scripts/ build script)"; }

need "${BL_OUT}/TestBootApp.efi"
need "${BL_OUT}/esp.img"
for f in bootcfg_ramdeploy.bin kernel_ramdeploy.bin dtb_ramdeploy.bin \
         initrd_ramdeploy.bin initrd_debug_ramdeploy.bin; do
    need "${K_OUT}/ramdeploy/${f}"
done
need "${K_OUT}/tools/deployclient"
need "${K_OUT}/tools/makeblob"
for f in "${K_OUT}"/debs/linux-firmware-iceland*_arm64.deb \
         "${K_OUT}"/debs/linux-headers-*_arm64.deb \
         "${K_OUT}"/debs/linux-image-*_arm64.deb \
         "${K_OUT}"/debs/linux-modules-*_arm64.deb; do
    need "$f"
done
SPARSE="${U_OUT}/rootfs-ubuntu_desktop-fastcharge.sparse.img"
need "${SPARSE}"

# --- assemble ../artifacts/ramdeploy (desktop-fastcharge variant) -----------
log "assembling ${ART} (desktop-fastcharge variant)"
mkdir -p "${ART}"

cp -f "${BL_OUT}/TestBootApp.efi" "${ART}/"
cp -f "${K_OUT}/ramdeploy/bootcfg_ramdeploy.bin" \
      "${K_OUT}/ramdeploy/kernel_ramdeploy.bin" \
      "${K_OUT}/ramdeploy/dtb_ramdeploy.bin" \
      "${K_OUT}/ramdeploy/initrd_ramdeploy.bin" \
      "${K_OUT}/ramdeploy/initrd_debug_ramdeploy.bin" \
      "${ART}/"
cp -f "${K_OUT}/tools/deployclient" "${ART}/"

log "packing deploy.blob (desktop-fastcharge rootfs + 4 debs)"
"${K_OUT}/tools/makeblob" -o "${ART}/deploy.blob" "${SPARSE}" \
    "${K_OUT}"/debs/linux-firmware-iceland*_arm64.deb \
    "${K_OUT}"/debs/linux-headers-*_arm64.deb \
    "${K_OUT}"/debs/linux-image-*_arm64.deb \
    "${K_OUT}"/debs/linux-modules-*_arm64.deb

cat > "${ART}/ramdeploy.sh" <<'EOS'
#!/usr/bin/env bash
# One-shot RAM deploy of the desktop-fastcharge variant.  Device must be in
# TestBootApp fastboot (8B0C705); run from this directory:
#   ./ramdeploy.sh [deploy.blob] [debug]   (defaults: deploy.blob, release)
set -eu
D=$(cd "$(dirname "$0")" && pwd)
BLOB="${1:-$D/deploy.blob}"
INITRD=initrd_ramdeploy.bin
[ "${2:-}" = debug ] && INITRD=initrd_debug_ramdeploy.bin
fastboot flash bootcfg "$D/bootcfg_ramdeploy.bin"
fastboot flash kernel   "$D/kernel_ramdeploy.bin"
fastboot flash dtb      "$D/dtb_ramdeploy.bin"
fastboot flash initrd   "$D/$INITRD"
fastboot continue || true                      # device re-enumerates down
echo "== waiting for deploy NCM (60 s)..."
for i in $(seq 15); do ip -o addr show 2>/dev/null | grep -q 'enx.*192.168.42' && break; sleep 4; done
ip -4 -o addr show | grep 192.168.42 | head -1
"$D/deployclient" 192.168.42.42 5190 "$BLOB"
EOS
chmod +x "${ART}/ramdeploy.sh"

(
    cd "${ART}"
    sha256sum TestBootApp.efi *_ramdeploy.bin deployclient deploy.blob ramdeploy.sh \
        > SHA256SUMS
)

log "done. deliverable in ${ART}:"
ls -l "${ART}" >&2
