#!/usr/bin/env bash
set -euo pipefail

ts() { date '+%Y-%m-%d %H:%M:%S'; }
log() { printf '%s [%s] %s\n' "$(ts)" "$1" "$2" >&2; }
info(){ log INFO "$1"; }
warn(){ log WARN "$1"; }
err(){ log ERROR "$1"; }

source .env
export DPUCLUSTER_INTERFACE DPUCLUSTER_VIP
export IP_RANGE_START IP_RANGE_END
export TARGETCLUSTER_API_SERVER_HOST

build() {
  info "kubectl create ns dpu-cplane-tenant1 ..."
  kubectl create ns dpu-cplane-tenant1 || true

  info "deploy DPF system components ..."
  TARGETCLUSTER_API_SERVER_HOST=$(kubectl get nodes -l node-role.kubernetes.io/control-plane \
    -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
  cat resources/dpucluster.yaml resources/dpudiscovery.yaml resources/operatorconfig.yaml \
        | envsubst | kubectl apply -f-

  NAMESPACE="dpf-operator-system"
  DEPLOYMENTS=(
    "dpf-provisioning-controller-manager"
    "dpuservice-controller-manager"
  )

  for DEPLOY in "${DEPLOYMENTS[@]}"; do
    info "⏳ Waiting for Deployment $DEPLOY in namespace $NAMESPACE to appear..."

    # Wait up to 300s for the deployment object to exist
    for i in {1..300}; do
      if kubectl get deployment "$DEPLOY" -n "$NAMESPACE" >/dev/null 2>&1; then
        info "✅ Deployment $DEPLOY created."
        break
      fi
      sleep 1
    done

    # Now wait for rollout to complete (with a 300s timeout)
    info "⏳ Waiting for rollout of $DEPLOY..."
    kubectl rollout status deployment/"$DEPLOY" -n "$NAMESPACE" --timeout=300s
  done

  info "ensure the DPUCluster is ready for nodes to join ..."
  kubectl wait --for=condition=ready --namespace dpu-cplane-tenant1 dpucluster --all
}

delete() {
  kubectl delete -f ./resources/operatorconfig.yaml || true
  kubectl delete -f ./resources/dpudiscovery.yaml || true
  kubectl delete -f ./resources/dpucluster.yaml || true
}

case "${1:-build}" in
  delete) delete ;;
  *)      build  ;;
esac
