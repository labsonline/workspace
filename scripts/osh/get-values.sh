#!/bin/bash
# SPDX-License-Identifier: GPL-3.0

set -euo pipefail

# fixme: charts
CHARTS=()

for c in "${CHARTS[@]}"; do
  ns="$(echo ${c} | cut -d: -f1)"
  chart="$(echo ${c} | cut -d: -f2)"
  echo "gettting values for ${chart} in ${ns}"
  dest="${HOME}/wip/${ns}"
  [[ ! -d "${dest}" ]] && mkdir -p "${dest}"
  helm get values -n "${ns}" "${chart}" > "${dest}/${chart}.yaml"
done
