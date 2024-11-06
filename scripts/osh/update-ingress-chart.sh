#!/bin/bash
# SPDX-License-Identifier: GPL-3.0

set -e


src="${1:-/tmp}"
[[ ! -d "${src}" ]] && echo "invalid directory!!!" && exit 1

# check chart exist at path
NGINX_INGRESS_CHART="${src}/ingress-nginx-4.4.0.tgz"
[[ ! -f "${NGINX_INGRESS_CHART}" ]] && echo "chart not found!!!" && exit 1

# fixme: list of chart to be updated (namespace:deployname)
charts=()

# update chart with provided values (<src>/<deployname>.<namespace>)
for chart in ${charts[@]}; do
    ns=$(echo "${chart}" | cut -d: -f1)
    item=$(echo "${chart}" | cut -d: -f2)
    echo """
    updating chart...
        chart: ${item}
        namespace: ${ns}
    """

    values="${src}/${item}.${ns}.yaml"
    [[ ! -f "${values}" ]] && echo "${values} not found!!!" && exit 1
    helm upgrade "${item}" -n "${ns}" -f "${values}" "${NGINX_INGRESS_CHART}"
done
