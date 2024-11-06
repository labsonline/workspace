#!/bin/bash
# SPDX-License-Identifier: GPL-3.0

set -euxo pipefail

snap_id="${1}"
vol_pool="${2:cinder.volumes}"

# get vol snap parent vol
vol_id="$(openstack volume snapshot show --format shell "${snap_id}" | grep volume_id | cut -d'"' -f2)"

# flatten parent vol children
vol_children="$(rbd -p "${vol_pool}" children "${vol_id}" | cut -d'/' -f2)" # list of children vol
for child in "${vol_children}"; do
    rbd -p "${vol_pool}" flatten "${child}"
done

# unprotect snap
rbd -p "${vol_pool}" snap unprotect "${vol_id}"@snapshot-"${snap_id}"
rbd -p "${vol_pool}" snap ls "${vol_id}"

# purge trash
rbd -p "${vol_pool}" trash purge
