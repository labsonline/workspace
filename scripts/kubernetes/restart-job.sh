#!/bin/bash
# SPDX-License-Identifier: GPL-3.0

JOB=$1
NAMESPACE=$2

: "${WAIT:=0}"
: "${TIMEOUT_SEC:=120s}"

# Restart job
kubectl get job "${JOB}" -n "${NAMESPACE}" -o json |
  jq 'del(.spec.selector)' |
  jq 'del(.spec.template.metadata.labels)' |
  kubectl replace --force -f - >/dev/null

# Wait for job to complete
[ ${WAIT} -eq 1 ] && kubectl wait --for=condition=complete "job/${JOB}" -n "${NAMESPACE}" --timeout "${TIMEOUT_SEC}" >/dev/null
