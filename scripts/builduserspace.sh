#!/usr/bin/env bash
# Phase 3/3: userspace (rootfs) build.  OWNER: userspace repo.
#
# Contract (consumed by the main build's ramdeploy assembly):
#   outputs in  ../../build/userspace/
#     rootfs-ubuntu_desktop-fastcharge.sparse.img   <-- required by the
#         desktop-fastcharge ramdeploy variant (Android sparse ext4)
#     (other variants -- rootfs-debug, rootfs-ubuntu_desktop-debug, ... --
#      are built here as well but not assembled by the main build)
#
# Placeholder on purpose -- the userspace owner fills this in (typically
# delegating to ../userspace/build.sh).
exit 0
