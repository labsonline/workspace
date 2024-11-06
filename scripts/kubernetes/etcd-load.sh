#!/bin/bash
# SPDX-License-Identifier: GPL-3.0

set -xe

: ${ETCD_NAMESPACE:=kube-system}
: ${ETCD_LEADER:=""}

: ${FIO_DEB_PKG:=https://artifacts-nc.mtn57z.cti.att.com/artifactory/aqua/binaries/resource/fio-3.30.tar.gz}

export K8S_CTRL="32.67.136.121 32.67.136.122 32.67.136.123" # FIXME: hard-coded value
export ETCD_PODS="$(kubectl get pod -n kube-system | grep kubernetes-etcd-bsr | cut -d ' ' -f 1 | tr -s '\n' ' ')"

# TODO: add fio
# download
# extract
# move

# TODO: find etcd leader and node it's running on and label it

# TODO: on leader change, remove label on all controllers and relabel new leader

# FIXME: run fio on leader node, when completed, check if node is still leader and rerun if set to rerun
for POD in ${ETCD_PODS}; do
  endpoints=$(kubectl exec -n ${ETCD_NAMESPACE} ${POD} -- etcdctl endpoint status -w table | awk /https/ | tr -d '|')
  is_leader=$(echo $endpoints | cut -d ' ' -f 6)

  echo ${POD} is leader: ${is_leader}

  if ${is_leader}; then
    ETCD_LEADER=${POD}
    echo "etcd leader is ${ETCD_LEADER}"

    kubectl get pod -o wide -n ${ETCD_NAMESPACE} ${ETCD_LEADER}

    # ssh ${USER}@${ETCD_LEADER_NODE} fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=etcd-disk-io-test --filename=/var/lib/etcd/etcd_read_write.io --bs=4k --iodepth=64 --size=4G --readwrite=randrw --rwmixread=75
  fi
done

# TODO: cleanup
