#!/usr/bin/env bash
# Phase 1/3: bootloader build.  OWNER: bootloader repo.
#
# Contract (consumed by the main build and the kernel phase):
#   outputs in  ../../build/bootloader/
#     BootApp.efi  BootUtil.efi  TestBootApp.efi   EFI applications
#     esp.img      Android-sparse FAT32 (1 GiB) carrying the ESP content;
#                  the kernel phase embeds it into the netdeploy initrd for
#                  the factory-first-boot ESP install
#
# Placeholder on purpose -- the bootloader owner fills this in (typically
# delegating to ../bootloader/build.sh).
exit 0
