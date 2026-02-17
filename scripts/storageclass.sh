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
  info "create nfs storageclass ..."
  if ! cat resources/storageclass.yaml | envsubst | kubectl apply -f-; then
    err "Applying manifests failed"; return 1
  fi
}

delete() {
  kubectl delete -f ./resources/storageclass.yaml
}

case "${1:-build}" in
  delete) delete ;;
  *)      build  ;;
esac
