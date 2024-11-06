#!/bin/bash
# SPDX-License-Identifier: GPL-3.0

set -ex

# : "${CMD:=./tools/developer/osh-exec/osh-exec.sh}"
: "${CMD:=$HOME/workspace/scripts/osh-exec.sh}"

CEPH_RBD_POOL="cinder.volumes"
VOLUME_LIST=($(${CMD} os volume list --all-projects | egrep -i 'SLAA|PVT|tempest|SSDV|aqua' | awk '{print $2}'))

echo """
---------------------------------------------------
VOLUMES
---------------------------------------------------
${VOLUME_LIST}
"""

# purge ceph trash
${CMD} rbd -p "${CEPH_RBD_POOL}" trash list
${CMD} rbd -p "${CEPH_RBD_POOL}" trash purge

# clear volumes
for vol in ${VOLUME_LIST[@]}; do
    CEPH_VOL_SNAPS="$(${CMD} rbd -p ${CEPH_RBD_POOL} snap ls ${vol} | awk '{ print $2 }' | tail -n +3)"

    # unprotect volume snapshots
    for snap in ${CEPH_VOL_SNAPS[@]}; do
        ${CMD} rbd -p "${CEPH_RBD_POOL}" snap unprotect ${vol}@${snap}
        ${CMD} rbd -p "${CEPH_RBD_POOL}" snap rm ${vol}@${snap}
    done

    VOLUME_SNAPSHOT_LIST=($(${CMD} os volume snapshot list --all-projects | egrep -i 'SLAA|PVT|tempest|SSDV|aqua' | awk '{print $2}'))

    # clear volume snapshots
    for snap in ${VOLUME_SNAPSHOT_LIST[@]}; do
        ${CMD} os volume snapshot delete ${snap}
    done

    ${CMD} os volume delete ${vol}
done

# verify artifacts were deleted
VOLUME_LIST=($(${CMD} os volume list --all-projects | egrep -i 'SLAA|PVT|tempest|SSDV|aqua' | awk '{print $2}'))
VOLUME_SNAPSHOT_LIST=($(${CMD} os volume snapshot list --all-projects | egrep -i 'SLAA|PVT|tempest|SSDV|aqua' | awk '{print $2}'))

echo """
---------------------------------------------------
VOLUMES
---------------------------------------------------
${VOLUME_LIST}
---------------------------------------------------
SNAPSHOTS
---------------------------------------------------
${VOLUME_SNAPSHOT_LIST}
"""
