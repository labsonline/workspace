#!/bin/bash
# SPDX-License-Identifier: GPL-3.0

# This script applies a similar approach as in ceph-increase-probe-timeout.sh
# to increase the etcd pod to 10 seconds to account for a runc bug that occasionally
# causes probes to time out and fail after succeeding.

set ex

# only work in kube-system
NS="kube-system"

# Loop over etcd pods and replace wotj 10-seconds timeout
for pod in $(kubectl -n ${NS} get pods -l component=etcd --no-headers | awk '{print $1}'); do
  kubectl -n ${NS} get pod ${pod} -o yaml | sed 's/timeoutSeconds:.*/timeoutSeconds: 10/g'  | kubectl -n ${NS} apply -f -
  # FIXME: remove
  kubectl -n ${NS} get pod ${pod} -o yaml > /tmp/etcd.yaml
done
