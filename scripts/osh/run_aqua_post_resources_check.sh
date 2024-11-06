#!/bin/bash
# SPDX-License-Identifier: GPL-3.0

set -euxo pipefail

export KUBECONFIG=/etc/kubernetes/admin/kubeconfig.yaml

for i in OS_AUTH_URL OS_PROJECT_NAME OS_REGION_NAME OS_PASSWORD OS_USERNAME;do
    export ${i}=$(sudo -E kubectl get secret keystone-keystone-admin -n openstack --template={{.data.${i}}} | base64 -d)
done

ARGS=${1}
SRC_DIR=/tmp/resources_check

cleanup() {
    NS=${1}
    POD=${2}
    CN=${3}
    PY_SCRIPT_NAME=${4}
    PY_SCRIPT_ARGS=${5}

    sudo -E kubectl -n ${NS} cp -c ${CN} ${SRC_DIR}/${PY_SCRIPT_NAME} ${POD}:/tmp/
    sudo -E kubectl -n ${NS} exec ${POD} -c ${CN} -- bash -c "export OS_AUTH_URL=${OS_AUTH_URL} OS_PROJECT_NAME=${OS_PROJECT_NAME} OS_REGION_NAME=${OS_REGION_NAME} OS_PASSWORD=${OS_PASSWORD} OS_USERNAME=${OS_USERNAME}; python3 /tmp/${PY_SCRIPT_NAME} ${PY_SCRIPT_ARGS}"
    sudo -E kubectl -n ${NS} exec ${POD} -c ${CN} -- rm -f /tmp/${PY_SCRIPT_NAME}
}

# cleanup volumes using ceph tools
CEPH_NS=tenant-ceph
CEPH_CN=ceph-mon
CEPH_POD=$(sudo -E kubectl -n ${CEPH_NS} get pod | awk '/ceph-mon-check/ { print $1 }' | head -n 1)

# Cleaning up items marked for deletion that haven not beem removed
# note: these items have .deleted at the end of their name
# e.g.: 9f90738c-23f4-4b35-827c-6fb848784f07.deleted
cat <<'eof' > ${SRC_DIR}/pre_cleanup.sh
#!/bin/bash

set -euxo pipefail

CINDER_VOL="cinder.volumes"

remove() {
    vol=${1}
    snapshots=$(rbd -p ${CINDER_VOL} snap ls ${vol} | tail -n +2 | awk '{ print $2 }')

    for snap in ${snapshots}; do
        rbd -p ${CINDER_VOL} snap unprotect ${vol}@${snap}
    done

    rbd -p ${CINDER_VOL} snap purge ${vol}
    rbd -p ${CINDER_VOL} rm ${vol}
}

vols=$(rbd -p ${CINDER_VOL} ls | awk /.deleted/)
for vol in ${vols}; do
    children=$(rbd -p ${CINDER_VOL} children ${vol})
    for child in ${children}; do
        rbd -p ${CINDER_VOL} flatten ${child}
        remove ${child}
    done

    remove ${vol}
done
eof

sudo -E kubectl -n ${CEPH_NS} cp -c ${CEPH_CN} ${SRC_DIR}/pre_cleanup.sh ${CEPH_POD}:/tmp/pre_cleanup.sh
sudo -E kubectl -n ${CEPH_NS} exec ${CEPH_POD} -c ${CEPH_CN} -- bash -c 'chmod +x /tmp/pre_cleanup.sh; /tmp/pre_cleanup.sh'
sudo -E kubectl -n ${CEPH_NS} exec ${CEPH_POD} -c ${CEPH_CN} -- rm -f /tmp/pre_cleanup.sh

cleanup ${CEPH_NS} ${CEPH_POD} ${CEPH_CN} aqua_post_resources_check_ceph.py ${ARGS}

# cleanup using openstack client
OS_NS=openstack
OS_CN=heat-api
OS_POD=$(sudo -E kubectl -n ${OS_NS} get pod | awk '/heat-api/ { print $1 }' | head -n 1)
cleanup ${OS_NS} ${OS_POD} ${OS_CN} aqua_post_resources_check_openstack.py ${ARGS}
