#!/bin/bash
# SPDX-License-Identifier: GPL-3.0

set -e

dst="${1:-/tmp}"
namespaces=(
    ceph
    kube-system
    openstack
    osh-infra
    tenant-ceph
    ucp
)

for ns in ${namespaces[@]}; do
    deploy="$(helm ls -n "${ns}" | awk '/ingress/ {print $1}')"
    for i in ${deploy[@]}; do
        helm get values -n "${ns}" "${i}" | tee "${dst}/${i}.${ns}.yaml"
    done
done
