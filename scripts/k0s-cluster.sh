#!/usr/bin/env bash
set -euo pipefail

# k0s-cluster quick helper: build (default) or delete the local single-node cluster.
# Usage: ./k0s-cluster.sh [delete]

ts() { date '+%Y-%m-%d %H:%M:%S'; }
log() { printf '%s [%s] %s\n' "$(ts)" "$1" "$2" >&2; }
info(){ log INFO "$1"; }
warn(){ log WARN "$1"; }
err(){ log ERROR "$1"; exit 1; }

source .env

build() {
  # Install k0s if not present
  if sudo k0s status >/dev/null 2>&1; then
    info "==> k0s already present at $(command -v k0s) (version: $(k0s version))"
  else
    info "==> Installing k0s..."
    curl -sSf https://get.k0s.sh | sudo sh

    # Create a default config
    sudo mkdir -p /etc/k0s
    k0s config create | sudo tee /etc/k0s/k0s.yaml >/dev/null

    # Edit it: set metricsPort: 0 to disable metrics server
    # conflicts with  kamaji-metrics-service on port 8080, listening on 0.0.0.0
    sudo sed -i 's/metricsPort: 8080/metricsPort: 0/' /etc/k0s/k0s.yaml

    # Install single-node controller (idempotent if already installed)
    info "==> Installing k0s controller (single-node)..."
    sudo k0s install controller --single --config /etc/k0s/k0s.yaml

    # Start (or ensure) the service is running
    info "==> Starting k0s..."
    sudo k0s start || err "k0s start failed"
  fi

# Wait for API & node to become Ready
SLEEP=10
info "==> Waiting for k0s API and node readiness ..."
for i in {1..60}; do
  if sudo k0s kubectl get nodes >/dev/null 2>&1; then
    # Check for a Ready node
    if sudo k0s kubectl get nodes 2>/dev/null | awk 'NR>1 && $2 ~ /Ready/ {found=1} END{exit(!found)}'; then
      info "k0s API and node ready"
      break
    fi
  fi
  info "k0s API and node not ready, waiting $SLEEP secs ..."
  sleep $SLEEP
  if [[ $i -eq 60 ]]; then
    warn "WARNING: Node not Ready yet. Proceeding to write kubeconfig anyway."
  fi
done

# Write kubeconfig for the target user
info "==> Writing kubeconfig ..."
mkdir -p ~/.kube
sudo k0s kubeconfig admin > ~/.kube/config
sudo chown -R $USER:$USER ~/.kube/config

echo ""
kubectl get nodes -o wide || true

echo ""
info 'Control plane nodes have the labels "node-role.kubernetes.io/control-plane" : ""'
info "See https://github.com/NVIDIA/doca-platform/blob/public-release-v25.7/docs/public/user-guides/zero-trust/prerequisites/system.md#kubernetes"
node=$(kubectl get nodes -o jsonpath='{range .items[0]}{.metadata.name}{end}')
kubectl label node $node node-role.kubernetes.io/control-plane="" --overwrite

NAMESPACE="kube-system"
TIMEOUT=300   # seconds
SLEEP=5

echo ""
info "==> Waiting for all pods in namespace '${NAMESPACE}' to be Ready..."

end=$((SECONDS + TIMEOUT))
while true; do
  # Get pod count and ready count
  not_ready=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null \
    | awk '{print $2}' \
    | awk -F/ '$1!=$2 {count++} END{print count+0}')

  total=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)

  if [[ "$total" -gt 0 && "$not_ready" -eq 0 ]]; then
    info "✅ All $total pods in '$NAMESPACE' are Ready"
    break
  fi

  if [[ $SECONDS -ge $end ]]; then
    err "❌ Timeout reached: some pods are still not Ready"
    kubectl get pods -n "$NAMESPACE"
    exit 1
  fi

  info "==> $not_ready / $total pods not ready yet... waiting $SLEEP secs"
  sleep "$SLEEP"
done

echo ""
kubectl get pod -n kube-system
}

delete() {
  info "stopping k0s"
  sudo k0s stop 2>/dev/null || true
  info "resetting k0s"
  sudo k0s reset -f 2>/dev/null || sudo k0s reset 2>/dev/null || true
  sudo systemctl stop k0scontroller 2>/dev/null || true
  sudo systemctl disable k0scontroller 2>/dev/null || true
  info "removing /usr/local/bin/k0s"
  sudo rm -f /usr/local/bin/k0s /tmp/k0s.yaml
  info "delete complete"
}

case "${1:-build}" in
  delete) delete ;;
  *)      build  ;;
esac
