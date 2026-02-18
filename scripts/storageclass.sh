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
  info "install the NFS CSI driver into kube-system ..."
  helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
  helm repo update

  helm upgrade --install csi-driver-nfs csi-driver-nfs/csi-driver-nfs \
    --namespace kube-system --create-namespace --set kubeletDir=/var/lib/k0s/kubelet

  info "verify it registered"
  kubectl get csidrivers | grep -i nfs
  kubectl -n kube-system get pods -o wide | egrep -i 'nfs|csi'

  info "create nfs storageclass ..."
  if ! cat resources/storageclass.yaml | envsubst | kubectl apply -f-; then
    err "Applying manifests failed"; return 1
  fi
}

delete() {
  kubectl delete -f ./resources/storageclass.yaml
  helm delete csi-driver-nfs --namespace kube-system
}

case "${1:-build}" in
  delete) delete ;;
  *)      build  ;;
esac
