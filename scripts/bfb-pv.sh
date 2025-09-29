#!/usr/bin/env bash
set -euo pipefail

ts() { date '+%Y-%m-%d %H:%M:%S'; }
log() { printf '%s [%s] %s\n' "$(ts)" "$1" "$2" >&2; }
info(){ log INFO "$1"; }
warn(){ log WARN "$1"; }
err(){ log ERROR "$1"; }

source .env
export NFS_SERVER_IP NFS_SERVER_PATH

build() {
  info "🔎 Checking if $NFS_SERVER_IP is reachable..."
  if ping -c 1 -W 2 "$NFS_SERVER_IP" >/dev/null 2>&1; then
    info "✅ Host $NFS_SERVER_IP is reachable"
  else
    err "❌ Host $NFS_SERVER_IP not reachable"
    exit 1
  fi

  echo "🔎 Checking NFS exports on $NFS_SERVER_IP ..."
  if showmount -e "$NFS_SERVER_IP" >/dev/null 2>&1; then
    showmount -e "$NFS_SERVER_IP"
  else
    err "❌ Unable to query NFS exports (rpcbind/nfs-server not responding?)"
    exit 1
  fi

  info "NFS_SERVER_IP=$NFS_SERVER_IP NFS_SERVER_PATH=$NFS_SERVER_PATH"

  kubectl create ns dpf-operator-system 2>/dev/null || true
  cat ./resources/nfs-storage-for-bfb-dpf-ga.yaml | envsubst | kubectl apply -f -
}

delete() {
  kubectl delete -f ./resources/nfs-storage-for-bfb-dpf-ga.yaml || true
}

case "${1:-build}" in
  delete) delete ;;
  *)      build  ;;
esac
