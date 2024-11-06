#!/bin/bash
# SPDX-License-Identifier: GPL-3.0

set -e

: "${CLUSTER_NAME:=kind-rook-ceph}"
: "${CONTAINER_NAME:=${CLUSTER_NAME}-control-plane}"

# verify dependencies are installed
[[ -z $(command -v docker) ]] && echo 'docker is not installed' && exit 1
[[ -z $(command -v kind) ]] && echo 'kind is not installed' && exit 1

# create kind cluster
[[ -z $(kind get clusters | grep "${CLUSTER_NAME}") ]] \
  && kind create cluster --name "${CLUSTER_NAME}" \
  && sleep 15

# create loopback device
tee /tmp/loops-setup-ceph.sh <<'EOF'
#!/bin/bash
set -e
for i in {1..3}; do
  # create raw devices if they don't exist
  [[ -s rook-ceph-${i}.img ]] && echo 'raw device already exists' \
  || dd if=/dev/zero of=rook-ceph-${i}.img bs=1M count=10240

  # create loop devices if they don't exist
  [[ -b /dev/loop${i} ]] && echo 'loop device already exists' \
  || losetup /dev/loop${i} rook-ceph-${i}.img
done
exit 0
EOF

docker container cp /tmp/loops-setup-ceph.sh "${CONTAINER_NAME}:loops-setup-ceph.sh"
docker container exec -it "${CONTAINER_NAME}" chmod +x /loops-setup-ceph.sh
docker container exec -it "${CONTAINER_NAME}" /loops-setup-ceph.sh

# deploy rook-ceph-operator
tee /tmp/rook-ceph-operator.yaml <<EOF
allowLoopDevices: true
csi:
  provisionerReplicas: 1
resources: {}
EOF

helm upgrade rook-ceph-operator rook-ceph \
  --install \
  --create-namespace \
  --repo=https://charts.rook.io/release/ \
  --version=1.11.9 \
  --namespace=rook-ceph \
  --values=/tmp/rook-ceph-operator.yaml \
  --wait

# deploy rook-ceph-cluster
tee /tmp/rook-ceph-cluster.yaml <<EOF
cephBlockPools:
  - name: ceph-blockpool
    spec:
      replicated:
        size: 1
    storageClass:
      enabled: true
      isDefault: true
      name: ceph-block
cephClusterSpec:
  dashboard:
    enabled: true
    ssl: true
  mgr:
    count: 1
  mon:
    count: 1
  resources:
    cleanup: {}
    crashcollector: {}
    exporter: {}
    logcollector: {}
    mgr: {}
    mgr-sidecar: {}
    mon: {}
    osd: {}
    prepareosd: {}
  storage:
    useAllNodes: true
    useAllDevices: false
    devices:
      - name: /dev/loop1
      - name: /dev/loop2
      - name: /dev/loop3
cephFileSystems:
  - name: ceph-filesystem
    spec:
      dataPools:
      - name: data0
        replicated:
          size: 1
      metadataPool:
        replicated:
          size: 1
      metadataServer:
        activeCount: 1
        resources: {}
    storageClass:
      enabled: true
      isDefault: false
      name: ceph-filesystem
      pool: data0
cephObjectStores:
  - name: ceph-objectstore
    ingress:
      enabled: false
    spec:
      dataPool:
        erasureCoded:
          codingChunks: 1
          dataChunks: 1
      gateway:
        instances: 1
        resources: {}
      metadataPool:
        replicated:
          size: 1
    storageClass:
      enabled: true
      name: ceph-bucket
      parameters:
        region: us-east-1
operatorNamespace: rook-ceph
toolbox:
  enabled: true
  resources:
    limits: {}
    requests: {}
EOF

helm upgrade rook-ceph-cluster rook-ceph-cluster \
  --install \
  --repo=https://charts.rook.io/release/ \
  --version=1.11.9 \
  --namespace=rook-ceph \
  --values=/tmp/rook-ceph-cluster.yaml \
  --wait

# test rook-ceph-cluster
sleep 15

TOOLBOX_POD_NAMESPACE="rook-ceph"
TOOLBOX_POD_NAME="$(kubectl get pods -n ${TOOLBOX_POD_NAMESPACE} -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}')"

kubectl exec -n "${TOOLBOX_POD_NAMESPACE}" -it "${TOOLBOX_POD_NAME}" -- bash -c "ceph status"
exit 0
