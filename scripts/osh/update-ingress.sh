#!/bin/bash
# SPDX-License-Identifier: GPL-3.0

set -e

NS="${1}"
[[ -z "${NS}" ]] && echo "missing namespace!!!" && exit 1

# getting the ingresses to be updated
INGS="$(kubectl get ing -n "${NS}" -o custom-columns=:metadata.name --no-headers)"
[[ -z "${INGS}" ]] && echo "no ingresses to be updated!!!" && exit 0

echo """
Updating the following ingresses...

${INGS}
"""

# update ingresses
for ing in ${INGS[@]}; do
    # check for spec.ingressClassName and bailout
    ICN="$(kubectl describe ing -n "${NS}" ${ing} | awk '/Ingress Class/')"
    [[ "${ICN}" != *"<none>"* ]] && echo "${ing} is already configured with ${ICN}" && continue

    # get ingressclass from annotation
    class=$(kubectl describe ing -n "${NS}" "${ing}" | awk '/ingress.class/ {print $3}') # Annotations: kubernetes.io/ingress.class: nginx
    [[ -z "${class}" ]] && class=$(kubectl describe ing -n "${NS}" "${ing}" | awk '/ingress.class/ {print $2}') # kubernetes.io/ingress.class: nginx

    echo "${ing} ingress has class name ${class}"

    if [[ "${class}" == "nginx" || "${class}" == "" ]]; then
        class="${NS}-ingress"
        echo "${ing} ingress will be set with class name ${class}"
    fi

    # add spec.ingressClassName
    kubectl patch ing -n "${NS}" "${ing}" -p  "{\"spec\":{\"ingressClassName\":\"${class}\"}}"

    # remove deprecated annotation
    kubectl annotate ing -n "${NS}" "${ing}" kubernetes.io/ingress.class-

    echo "updated ${ing} with spec.ingressClassName: ${class}"
    echo ""
done
