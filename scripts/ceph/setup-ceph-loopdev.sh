#!/bin/bash
# SPDX-License-Identifier: GPL-3.0

: "${CEPH_LOOPDEV_SIZE_MB:="10240"}"

# verify dependencies are installed
[[ -z $(command -v dd) ]] && echo "dd is not installed" && exit 1
[[ -z $(command -v losetup) ]] && echo "losetup is not installed" && exit 1

for i in {1..3}; do
  # create raw devices if they don't exist
  [[ -s "/srv/rook-ceph-${i}.img" ]] && echo "raw device already exists" ||
    dd if=/dev/zero of="/srv/rook-ceph-${i}.img" bs=1M count="${CEPH_LOOPDEV_SIZE_MB}"

  # create loop devices if they don't exist
  [[ -b "/dev/loop10${i}" ]] && echo "loop device already exists" ||
    losetup "/dev/loop10${i}" "/srv/rook-ceph-${i}.img"
done
