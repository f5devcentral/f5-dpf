#!/usr/bin/env bash
set -euo pipefail

ts() { date '+%Y-%m-%d %H:%M:%S'; }
log() { printf '%s [%s] %s\n' "$(ts)" "$1" "$2" >&2; }
info(){ log INFO "$1"; }
warn(){ log WARN "$1"; }
err(){ log ERROR "$1"; }

source .env
export HELM_REGISTRY_REPO_URL
export DPF_VERSION

build() {
  pushd helmfiles
  helmfile init --force
  helmfile apply -f ./prereqs.yaml --color --suppress-diff --skip-diff-on-install --concurrency 0 --hide-notes
  popd

  info "installing dpf-operator ..."
  helm repo add --force-update dpf-repository ${HELM_REGISTRY_REPO_URL}
  helm repo update
  helm upgrade --install -n dpf-operator-system dpf-operator dpf-repository/dpf-operator --version=${DPF_VERSION}

  info "check rollout status deployment of dpf-operator-controller-manager ..."
  kubectl rollout status deployment --namespace dpf-operator-system dpf-operator-controller-manager

  info "ensure all pods in the DPF Operator system are ready ..."
  kubectl wait --for=condition=ready --namespace dpf-operator-system pods --all
}

delete() {
  info "deleting dpf-operator ..."
  helm delete -n dpf-operator-system dpf-operator || true
}

case "${1:-build}" in
  delete) delete ;;
  *)      build  ;;
esac
