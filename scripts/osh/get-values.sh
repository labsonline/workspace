#!/bin/bash
# SPDX-License-Identifier: GPL-3.0

set -euo pipefail

CHARTS=(
    ucp:clcp-maas
    ucp:clcp-ucp-postgresql
    ceph:clcp-ucp-ceph-mgr
    ceph:clcp-ucp-ceph-mon
    ceph:clcp-ucp-ceph-osd-sdd
    ceph:clcp-ucp-ceph-provisioners
    openstack:clcp-cinder
    openstack:clcp-glance
    openstack:clcp-heat
    openstack:clcp-horizon
    openstack:clcp-keystone
    openstack:clcp-libvirt
    openstack:clcp-neutron
    openstack:clcp-nova
    openstack:clcp-openstack-mariadb
    openstack:clcp-openstack-memcached
    openstack:clcp-openstack-rabbitmq
    openstack:clcp-openvswitch
    openstack:clcp-placement
    openstack:clcp-tenant-ceph-rgw
)

for c in "${CHARTS[@]}"; do
  ns="$(echo ${c} | cut -d: -f1)"
  chart="$(echo ${c} | cut -d: -f2)"
  echo "gettting values for ${chart} in ${ns}"
  dest="${HOME}/wip/${ns}"
  [[ ! -d "${dest}" ]] && mkdir -p "${dest}"
  helm get values -n "${ns}" "${chart}" > "${dest}/${chart}.yaml"
done
