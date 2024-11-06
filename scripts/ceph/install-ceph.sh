#!/bin/bash
# SPDX-License-Identifier: GPL-3.0

set -e

: "${CEPH_REPO:=https://charts.rook.io/release}"
: "${CEPH_VERSION:=v1.12.5}"

# Configure snapshotter
kustomize build https://github.com/kubernetes-csi/external-snapshotter/client/config/crd | kubectl apply -f -
kustomize build https://github.com/kubernetes-csi/external-snapshotter/deploy/kubernetes/csi-snapshotter | kubectl apply -f -
kustomize build https://github.com/kubernetes-csi/external-snapshotter/deploy/kubernetes/snapshot-controller | kubectl apply -f -

# Generate rook-ceph config
cat <<EOF > /tmp/rook-ceph.yaml
allowLoopDevices: true
csi:
  csiAddons:
    enabled: true
  csiCephFSPluginResource: |
    - name : driver-registrar
      resources:
        requests: {}
        limits: {}
    - name : csi-cephfsplugin
      resources:
        requests: {}
        limits: {}
    - name : liveness-prometheus
      resources:
        requests: {}
        limits: {}
  csiCephFSProvisionerResource: |
    - name : csi-provisioner
      resources:
        requests: {}
        limits: {}
    - name : csi-resizer
      resources:
        requests: {}
        limits: {}
    - name : csi-attacher
      resources:
        requests: {}
        limits: {}
    - name : csi-snapshotter
      resources:
        requests: {}
        limits: {}
    - name : csi-cephfsplugin
      resources:
        requests: {}
        limits: {}
    - name : liveness-prometheus
      resources:
        requests: {}
        limits: {}
  csiNFSPluginResource: |
    - name : driver-registrar
      resources:
        requests: {}
        limits: {}
    - name : csi-nfsplugin
      resources:
        requests: {}
        limits: {}
  csiNFSProvisionerResource: |
    - name : csi-provisioner
      resources:
        requests: {}
        limits: {}
    - name : csi-nfsplugin
      resources:
        requests: {}
        limits: {}
    - name : csi-attacher
      resources:
        requests: {}
        limits: {}
  csiRBDPluginResource: |
    - name : driver-registrar
      resources:
        requests: {}
        limits: {}
    - name : csi-rbdplugin
      resources:
        requests: {}
        limits: {}
    - name : liveness-prometheus
      resources:
        requests: {}
        limits: {}
  csiRBDProvisionerResource: |
    - name : csi-provisioner
      resources:
        requests: {}
        limits: {}
    - name : csi-resizer
      resources:
        requests: {}
        limits: {}
    - name : csi-attacher
      resources:
        requests: {}
        limits: {}
    - name : csi-snapshotter
      resources:
        requests: {}
        limits: {}
    - name : csi-rbdplugin
      resources:
        requests: {}
        limits: {}
    - name : csi-omap-generator
      resources:
        requests: {}
        limits: {}
    - name : liveness-prometheus
      resources:
        requests: {}
        limits: {}
  enableMetadata: true
  nfs:
    enabled: false
  provisionerReplicas: 1
  readAffinity:
    enabled: true
  serviceMonitor:
    enabled: false
  topology:
    domainLabels:
    - kubernetes.io/hostname
    enabled: true
discover:
  resources: {}
monitoring:
  enabled: false
resources:
  limits: {}
  requests: {}
EOF

# Install rook-ceph
helm upgrade rook-ceph \
    --create-namespace \
    --install rook-ceph \
    --namespace rook-ceph \
    --repo "${CEPH_REPO}" \
    --values /tmp/rook-ceph.yaml \
    --version "${CEPH_VERSION}"

# Generate rook-ceph-cluster config
cat <<EOF > /tmp/rook-ceph-cluster.yaml
cephBlockPools:
- name: ceph-blockpool
  spec:
    failureDomain: host
    replicated:
      size: 1
  storageClass:
    allowVolumeExpansion: true
    enabled: true
    name: ceph-block
    parameters:
      csi.storage.k8s.io/controller-expand-secret-name: rook-csi-rbd-provisioner
      csi.storage.k8s.io/controller-expand-secret-namespace: '{{ .Release.Namespace }}'
      csi.storage.k8s.io/fstype: ext4
      csi.storage.k8s.io/node-stage-secret-name: rook-csi-rbd-node
      csi.storage.k8s.io/node-stage-secret-namespace: '{{ .Release.Namespace }}'
      csi.storage.k8s.io/provisioner-secret-name: rook-csi-rbd-provisioner
      csi.storage.k8s.io/provisioner-secret-namespace: '{{ .Release.Namespace }}'
      imageFeatures: layering
      imageFormat: "2"
    reclaimPolicy: Delete
    volumeBindingMode: Immediate
cephBlockPoolsVolumeSnapshotClass:
  annotations:
    k10.kasten.io/is-snapshot-class: "true"
  enabled: true
cephClusterSpec:
  crashCollector:
    disable: false
  dashboard:
    enabled: true
    ssl: true
  mgr:
    count: 1
    modules:
    - enabled: true
      name: k8sevents
    - enabled: true
      name: mirroring
    - enabled: true
      name: nfs
    - enabled: true
      name: osd_perf_query
    - enabled: true
      name: osd_support
    - enabled: true
      name: pg_autoscaler
    - enabled: true
      name: rgw
    - enabled: true
      name: rook
  mon:
    count: 1
  network:
    connections:
      encryption:
        enabled: false
  resources:
    cleanup:
      limits: {}
      requests: {}
    crashcollector:
      limits: {}
      requests: {}
    exporter:
      limits: {}
      requests: {}
    logcollector:
      limits: {}
      requests: {}
    mgr:
      limits: {}
      requests: {}
    mgr-sidecar:
      limits: {}
      requests: {}
    mon:
      limits: {}
      requests: {}
    osd:
      limits: {}
      requests: {}
    prepareosd:
      requests: {}
  storage:
    useAllDevices: false
    useAllNodes: true
    devices:
      - name: /dev/loop1
      - name: /dev/loop2
      - name: /dev/loop3
cephFileSystemVolumeSnapshotClass:
  annotations:
    k10.kasten.io/is-snapshot-class: "true"
  enabled: true
cephFileSystems:
- name: ceph-filesystem
  spec:
    dataPools:
    - failureDomain: host
      name: data0
      replicated:
        size: 1
    metadataPool:
      replicated:
        size: 1
    metadataServer:
      activeCount: 1
      resources: {}
  storageClass:
    allowVolumeExpansion: true
    enabled: true
    isDefault: false
    name: ceph-filesystem
    parameters:
      csi.storage.k8s.io/controller-expand-secret-name: rook-csi-cephfs-provisioner
      csi.storage.k8s.io/controller-expand-secret-namespace: '{{ .Release.Namespace }}'
      csi.storage.k8s.io/fstype: ext4
      csi.storage.k8s.io/node-stage-secret-name: rook-csi-cephfs-node
      csi.storage.k8s.io/node-stage-secret-namespace: '{{ .Release.Namespace }}'
      csi.storage.k8s.io/provisioner-secret-name: rook-csi-cephfs-provisioner
      csi.storage.k8s.io/provisioner-secret-namespace: '{{ .Release.Namespace }}'
    pool: data0
    reclaimPolicy: Delete
    volumeBindingMode: Immediate
cephObjectStores:
- name: ceph-objectstore
  spec:
    dataPool:
      erasureCoded:
        codingChunks: 0
        dataChunks: 0
      failureDomain: host
      replicated:
        size: 1
    gateway:
      instances: 1
      port: 80
      resources: {}
    metadataPool:
      failureDomain: host
      replicated:
        size: 1
  storageClass:
    enabled: true
    name: ceph-bucket
    parameters:
      region: us-east-1
    reclaimPolicy: Delete
    volumeBindingMode: Immediate
configOverride: |
  [global]
  mon mon_allow_pool_delete = true
  mon mon_allow_pool_size_one = true
  osd osd_crush_chooseleaf_type = 0
  osd osd_memory_target_autotune = true
  osd osd_pool_default_size = 1
monitoring:
  createPrometheusRules: false
  enabled: false
operatorNamespace: rook-ceph
toolbox:
  affinity: {}
  enabled: true
  resources:
    limits: {}
    requests: {}
  tolerations: []
EOF

# Install rook-ceph-cluster
sleep 15
helm upgrade rook-ceph-cluster \
    --install rook-ceph-cluster \
    --namespace rook-ceph \
    --repo "${CEPH_REPO}" \
    --values /tmp/rook-ceph-cluster.yaml \
    --version "${CEPH_VERSION}"
