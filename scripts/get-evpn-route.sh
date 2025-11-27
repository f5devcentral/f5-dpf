#!/usr/bin/env bash
#
# scripts/get-evpn-route.sh
#
# Collect all EVPN routes from FRR (vtysh) inside all DOCA-HBN pods.

set -euo pipefail

# Configurable via env vars
NAMESPACE="${NAMESPACE:-dpf-operator-system}"
POD_PREFIX="${POD_PREFIX:-dpu-cplane-tenant1-doca-hbn}"
CONTAINER="${CONTAINER:-}"   # if empty, we auto-detect a container containing "doca-hbn"

export KUBECONFIG=/home/mwiget/f5-dpf/dpu-cplane-tenant1.kubeconfig

# Default vtysh command (can be overridden by first script argument)
VTYSH_CMD="${1:-show bgp l2vpn evpn}"

echo "Namespace : ${NAMESPACE}"
echo "Pod prefix: ${POD_PREFIX}"
echo "Container : ${CONTAINER}"
echo "vtysh cmd : ${VTYSH_CMD}"
echo

# Get all matching pods
pods=$(kubectl get pods -n "${NAMESPACE}" -o jsonpath='{.items[*].metadata.name}' \
       | tr ' ' '\n' \
       | grep "^${POD_PREFIX}" || true)

if [ -z "${pods}" ]; then
  echo "No pods found matching prefix '${POD_PREFIX}' in namespace '${NAMESPACE}'" >&2
  exit 1
fi

for pod in ${pods}; do
  echo "============================================================"
  echo "Pod: ${pod}"
  echo "------------------------------------------------------------"
  kubectl exec -n "${NAMESPACE}" "${pod}" -c "${CONTAINER}" -- \
    vtysh -c "${VTYSH_CMD}" || echo "vtysh command failed on pod ${pod}" >&2
  echo
done
