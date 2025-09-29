#!/usr/bin/env bash
set -euo pipefail

ts() { date '+%Y-%m-%d %H:%M:%S'; }
log() { printf '%s [%s] %s\n' "$(ts)" "$1" "$2" >&2; }
info(){ log INFO "$1"; }
warn(){ log WARN "$1"; }
err(){ log ERROR "$1"; }

source .env
export BFB_URL

build() {
  info "create BFB, DPUSet and DPUServiceChain objects ..."
  cat \
    resources/passthru/ifaces.yaml \
    resources/passthru/dpuset.yaml \
    resources/passthru/bfb.yaml \
    resources/passthru/dpuservicechain.yaml \
    resources/passthru/dpuflavor.yaml \
    | envsubst | kubectl apply -f-

  info "ensure the DPUServiceChain is ready ..."
  kubectl wait --for=condition=ready --namespace dpf-operator-system dpuservicechain passthrough
  info "ensure the DPUServiceInterfaces are ready ..."
  kubectl wait --for=condition=ready --timeout=300s --namespace dpf-operator-system dpuserviceinterface p0 p1 pf0hpf pf1hpf
  info "ensure the BFB is ready ..."
  kubectl wait --for=jsonpath='{.status.phase}'=Ready --timeout=300s --namespace dpf-operator-system bfb bf-bundle
  info "ensure the DPUs have the condition initialized (this may take time) ..."
  kubectl wait --for=condition=Initialized --namespace dpf-operator-system dpu --all
}

delete() {
  kubectl delete \
    -f ./resources/passthru/dpuflavor.yaml \
    -f ./resources/passthru/dpuservicechain.yaml \
    -f ./resources/passthru/bfb.yaml \
    -f ./resources/passthru/dpuset.yaml \
    -f ./resources/passthru/ifaces.yaml
}

case "${1:-build}" in
  delete) delete ;;
  *)      build  ;;
esac
