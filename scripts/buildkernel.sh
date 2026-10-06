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
#
# Placeholder on purpose -- the kernel owner fills this in (typically
# delegating to ../kernel/build.sh).
exit 0
