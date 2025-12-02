#!/usr/bin/env bash
echo ""
export KUBECONFIG=./dpu-cplane-tenant1.kubeconfig
for nad in $(kubectl get network-attachment-definition -n dpf-operator-system -o jsonpath='{.items[*].metadata.name}'); do
  echo "$nad:"
  kubectl get network-attachment-definition $nad -n dpf-operator-system -o json | jq .spec
done
