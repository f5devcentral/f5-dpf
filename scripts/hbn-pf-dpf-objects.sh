#!/usr/bin/env bash
set -euo pipefail

ts() { date '+%Y-%m-%d %H:%M:%S'; }
log() { printf '%s [%s] %s\n' "$(ts)" "$1" "$2" >&2; }
info(){ log INFO "$1"; }
warn(){ log WARN "$1"; }
err(){ log ERROR "$1"; }

source .env
export BFB_URL

# configurable timing
: "${KWAIT_TIMEOUT:=600}"   # seconds to wait for resources/conditions
: "${KWAIT_INTERVAL:=5}"    # seconds between polls

# Wait until at least one object exists for a kind/selector in a namespace
wait_for_resources() {
  local ns="$1" kind="$2" selector="$3" waited=0
  while true; do
    # -o name prints nothing if none exist; we only need to see ONE
    if kubectl get -n "$ns" "$kind" -l "$selector" -o name 2>/dev/null | grep -q .; then
      return 0
    fi
    if [ "$waited" -ge "$KWAIT_TIMEOUT" ]; then
      echo "Timed out waiting for $kind in ns=$ns selector='$selector'" >&2
      return 1
    fi
    sleep "$KWAIT_INTERVAL"
    waited=$((waited + KWAIT_INTERVAL))
  done
}

# Wrapper that retries kubectl wait if server responds transiently
wait_condition() {
  local ns="$1" condition="$2" kind="$3" selector="$4"
  kubectl wait --timeout="${KWAIT_TIMEOUT}s" --for="condition=${condition}" -n "$ns" "$kind" -l "$selector"
}

build() {
  info "create DPUDeployment, DPUServiceConfig, DPUServiceTemplate and other necessary objects ..."
  if ! cat resources/hbn-pf/*.yaml | envsubst | kubectl apply -f-; then
    err "Applying manifests failed"; return 1
  fi

  local ns="dpf-operator-system"
  local owned_sel='svc.dpu.nvidia.com/owned-by-dpudeployment=dpf-operator-system_hbn'
  info "Ensure the DPUServices are created and have been reconciled..."
  while true; do
    if kubectl wait --timeout="${KWAIT_TIMEOUT}s" --for=condition=ApplicationsReconciled -n "$ns" dpuservices -l "$owned_sel"; then
        echo "Success: ApplicationsReconciled condition reached."
        return
    else
        echo "Not ready yet. Retrying in 5 seconds..."
        sleep 5
    fi
done

  info "Ensure the DPUServiceIPAMs have been reconciled..."
  kubectl wait --for=condition=DPUIPAMObjectReconciled --namespace dpf-operator-system dpuserviceipam --all
  info "Ensure the DPUServiceInterfaces have been reconciled..."
  kubectl wait --for=condition=ServiceInterfaceSetReconciled --namespace dpf-operator-system dpuserviceinterface --all
  info "Ensure the DPUServiceChains have been reconciled..."
  kubectl wait --for=condition=ServiceChainSetReconciled --namespace dpf-operator-system dpuservicechain --all
  info "Ensure the DPUs have the condition Initialized (this may take time)..."
  kubectl wait --for=condition=Initialized --namespace dpf-operator-system dpu --all
}

delete() {
  kubectl delete \
    -f ./resources/hbn-pf/hbn-dpuflavor.yaml \
    -f ./resources/hbn-pf/hbn-dpuserviceconfig.yaml \
    -f ./resources/hbn-pf/hbn-dpuservicetemplate.yaml \
    -f ./resources/hbn-pf/hbn-loopback-ipam.yaml \
    -f ./resources/hbn-pf/hbn-ipam.yaml \
    -f ./resources/hbn-pf/bfb.yaml \
    -f ./resources/hbn-pf/dpudeployment.yaml \
    -f ./resources/hbn-pf/physical-ifaces.yaml
}

case "${1:-build}" in
  delete) delete ;;
  *)      build  ;;
esac
