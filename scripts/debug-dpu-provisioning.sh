#!/bin/bash
set -euo pipefail

ns="dpf-operator-system"
deploy="dpf-provisioning-controller-manager"
container="manager"
selector="dpu.nvidia.com/component=dpf-provisioning-controller-manager"

echo "== BEFORE PATCH =="
kubectl -n "$ns" get deploy "$deploy" \
  -o jsonpath='{.spec.template.spec.containers[?(@.name=="manager")].args}'; echo

# Patch Deployment (strategic merge)
kubectl -n "$ns" patch deploy "$deploy" \
  --type='strategic' \
  -p '{
    "spec": {
      "template": {
        "spec": {
          "containers": [{
            "name": "manager",
            "args": [
              "--leader-elect",
              "--zap-devel=true",
              "--zap-encoder=console",
              "--zap-log-level=debug"
            ]
          }]
        }
      }
    }
  }'

echo
echo "== AFTER PATCH =="
kubectl -n "$ns" get deploy "$deploy" \
  -o jsonpath='{.spec.template.spec.containers[?(@.name=="manager")].args}'; echo
echo

echo "== ROLLOUT STATUS =="
kubectl -n "$ns" rollout status deploy/"$deploy"
echo

echo "== PODS (selector: $selector) =="
kubectl -n "$ns" get pods -l "$selector" -o wide
echo

echo "== POD ARGS =="
kubectl -n "$ns" get pods -l "$selector" \
  -o jsonpath='{range .items[*]}{.metadata.name}{" -> "}{.spec.containers[?(@.name=="'"$container"'")].args}{"\n"}{end}'
echo
