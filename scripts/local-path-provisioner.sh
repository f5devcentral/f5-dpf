#!/usr/bin/env bash
set -euo pipefail

ts() { date '+%Y-%m-%d %H:%M:%S'; }
log() { printf '%s [%s] %s\n' "$(ts)" "$1" "$2" >&2; }
info(){ log INFO "$1"; }
warn(){ log WARN "$1"; }
err(){ log ERROR "$1"; }

build() {
  info "installing local-path-provider storage class ..."
  curl https://codeload.github.com/rancher/local-path-provisioner/tar.gz/v0.0.31 \
    | tar -xz --strip=3 local-path-provisioner-0.0.31/deploy/chart/local-path-provisioner/
  kubectl get ns local-path-provisioner || kubectl create ns local-path-provisioner

  helm upgrade --install -n local-path-provisioner local-path-provisioner ./local-path-provisioner --version 0.0.31 \
        --set 'tolerations[0].key=node-role.kubernetes.io/control-plane' \
        --set 'tolerations[0].operator=Exists' \
        --set 'tolerations[0].effect=NoSchedule' \
        --set 'tolerations[1].key=node-role.kubernetes.io/master' \
        --set 'tolerations[1].operator=Exists' \
        --set 'tolerations[1].effect=NoSchedule'

  info "waiting for local-path-provisioner condition ready ..."
  kubectl wait --for=condition=ready --namespace local-path-provisioner pods --all
  info "set is-default-class ..."
  kubectl annotate storageclass local-path storageclass.kubernetes.io/is-default-class=true --overwrite
  kubectl get sc
}

delete() {
  helm delete -n local-path-provisioner local-path-provisioner || true
}

case "${1:-build}" in
  delete) delete ;;
  *)      build  ;;
esac
