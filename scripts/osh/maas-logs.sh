#!/bin/bash
# SPDX-License-Identifier: GPL-3.0

set -eux

: "${NAMESPACE:=ucp}"

# maas-region & maas-rack logs
kubectl logs -n ${NAMESPACE} maas-region-0 -c maas-region > ${1:-$PWD}/maas-region-0.log
kubectl logs -n ${NAMESPACE} maas-rack-0 -c maas-rack > ${1:-$PWD}/maas-rack-0.log

# armada logs
ARMADA_POD=$(kubectl get pod -n $NAMESPACE -l application=armada|awk '{print $1}'|tail -n +2|head -n 1)
kubectl logs -n ${NAMESPACE} ${ARMADA_POD} -c armada-api > ${1:-$PWD}/${ARMADA_POD}.log

# shipyard logs
SHIPYARD_POD=$(kubectl get pod -n $NAMESPACE -l application=shipyard|awk '{print $1}'|tail -n +2|head -n 1)
kubectl logs -n ${NAMESPACE} ${SHIPYARD_POD} -c shipyard-api > ${1:-$PWD}/${SHIPYARD_POD}.log

# drydock logs
DRYDOCK_PODS=$(kubectl get pod -n $NAMESPACE -l application=drydock|awk '{print $1}'|tail -n +2|head -n 2)
for POD in ${DRYDOCK_PODS}; do
  kubectl logs -n ${NAMESPACE} ${POD} -c drydock-api > ${1:-$PWD}/${POD}.log
done
