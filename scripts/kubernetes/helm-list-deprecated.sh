#!/bin/bash
# SPDX-License-Identifier: GPL-3.0

set -xe

: ${KUBECONFIG:=/etc/kubernetes/admin/kubeconfig.yaml}

# List API deprecation
for ns in $(kubectl get ns -o name | cut -d/ -f2); do
  for release in $(helm list --namespace "$ns" -q --date); do
    kubectl config set-context --current --namespace="$ns" > /dev/null
    while read -r line; do
      printf "%s: %s: %s\n" "$ns" "$release" "$line"
    done < <(helm get manifest --namespace "$ns" "$release" | kubectl get -f- -o name 2>&1 >/dev/null)
  done
done | tee deprecated-apis.txt
