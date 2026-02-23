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
  info "create commonobjects ..."
  if ! cat resources/hbn-pf-common/*.yaml | envsubst | kubectl apply -f-; then
    err "Applying commonborder manifests failed"; return 1
  fi
  info "create dpu border objects ..."
  if ! cat resources/hbn-pf-border/*.yaml | envsubst | kubectl apply -f-; then
    err "Applying border manifests failed"; return 1
  fi
  info "create dpu mgx objects ..."
  if ! cat resources/hbn-pf-mgx/*.yaml | envsubst | kubectl apply -f-; then
    err "Applying mgx manifests failed"; return 1
  fi
}

delete() {
	info "delete dpu border and mgx objects ..."
	kubectl delete -f resources/hbn-pf-border
	kubectl delete -f resources/hbn-pf-mgx
	kubectl delete -f resources/hbn-pf-common
}

case "${1:-build}" in
  delete) delete ;;
  *)      build  ;;
esac
