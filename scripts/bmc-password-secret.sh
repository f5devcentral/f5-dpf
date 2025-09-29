#!/usr/bin/env bash

ts() { date '+%Y-%m-%d %H:%M:%S'; }
log() { printf '%s [%s] %s\n' "$(ts)" "$1" "$2" >&2; }
info(){ log INFO "$1"; }
warn(){ log WARN "$1"; }
err(){ log ERROR "$1"; }

source .env

build() {
  info "kubectl create secret generic ..."

  if [[ -z "${BMC_ROOT_PASSWORD:-}" ]]; then
    err "❌ Error: BMC_ROOT_PASSWORD is not set in .env"
    exit 1
  fi

  kubectl create secret generic -n dpf-operator-system bmc-shared-password \
    --from-literal=password=${BMC_ROOT_PASSWORD}

  kubectl get secret bmc-shared-password -n dpf-operator-system
}

delete() {
  kubectl delete secret bmc-shared-password -n dpf-operator-system
}

case "${1:-build}" in
  delete) delete ;;
  *)      build  ;;
esac
