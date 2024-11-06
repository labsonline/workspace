#!/bin/bash
# SPDX-License-Identifier: GPL-3.0

set -xe

: ${KUBECONFIG:=/etc/kubernetes/admin/kubeconfig.yaml}

# Get crds available on the cluster
CRDS=$(kubectl get crd|cut -d' ' -f1)

# List crds api version
rm -f crd-api-version.txt

for CRD in ${CRDS}; do
  [ $CRD == "NAME" ] && continue
  kubectl explain --recursive ${CRD} | head | awk '/VERSION/' | sed -e 's/VERSION: //g' | tee -a crd-api-version.txt
done
