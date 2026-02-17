#!/usr/bin/env bash
set -euo pipefail

ts() { date '+%Y-%m-%d %H:%M:%S'; }
log() { printf '%s [%s] %s\n' "$(ts)" "$1" "$2" >&2; }
info(){ log INFO "$1"; }
warn(){ log WARN "$1"; }
err(){ log ERROR "$1"; }

source .env

# configurable timing
: "${KWAIT_TIMEOUT:=600}"   # seconds to wait for resources/conditions
: "${KWAIT_INTERVAL:=5}"    # seconds between polls

build() {
  info "installing multus ..."
  kubectl apply -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset.yml  
  kubectl -n kube-system get pods -l name=multus
  if ! cat resources/f5-flo/dummy-nad.yaml | envsubst | kubectl apply -f-; then
    err "Applying manifest failed"; return 1
  fi
}

delete() {
  echo "delete ..."
  kubectl delete -f resources/f5-flo/dummy-nad.yaml
  kubectl delete -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset.yml  
}

case "${1:-build}" in
  delete) delete ;;
  *)      build  ;;
esac
