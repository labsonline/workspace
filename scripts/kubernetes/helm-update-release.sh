#!/bin/bash
# SPDX-License-Identifier: GPL-3.0

set -euxo pipefail

CMD=$1

: ${WORKDIR:=$PWD}

: ${RELEASE_NAME:=$2}
: ${RELEASE_NAMESPACE:=$3}
: ${RELEASE_STATUS:=deployed}
: ${RELEASE_OBJ:="${WORKDIR}/${RELEASE_NAME}_${RELEASE_NAMESPACE}"}

# Decoding helm release (2x endoded & gziped)
function decode_release() {
  echo 'Decoding release...'

  RELEASE_SECRET=$(kubectl get secret -l owner=helm,status=${RELEASE_STATUS},name=${RELEASE_NAME} -n ${RELEASE_NAMESPACE} | awk '{print $1}' | grep -v NAME)

  # Get latest release details and make a backup copy
  kubectl get secret ${RELEASE_SECRET} -n ${RELEASE_NAMESPACE} -o yaml > ${RELEASE_OBJ}.yaml
  cp -f ${RELEASE_OBJ}.{yaml,bak}

  # Decode the release object
  cat ${RELEASE_OBJ}.yaml | yq '.data.release' | base64 -d | base64 -d | gzip -d > ${RELEASE_OBJ}.decoded

  echo "Helm release secret decoded and available for modification at ${RELEASE_OBJ}.yaml"
  echo "A backup copy is also available at ${RELEASE_OBJ}.bak"

  exit 0
}

# Re-encoding helm release
function encode_release() {
  echo 'Encoding release...'

  RELEASE_SECRET=$(cat ${RELEASE_OBJ}.decoded | gzip | base64 | base64)

  # Re-encode helm release object
  yq e '.data.release = $RELEASE_SECRET' < ${RELEASE_OBJ}.yaml > ${RELEASE_OBJ}.updated.yaml

  exit 0
}

# Running
case ${CMD} in
decode)
decode_release
break
;;
encode)
encode_release
break
;;
*)
echo 'Invalid command; supported commands: decode, encode'
exit 1
esac
