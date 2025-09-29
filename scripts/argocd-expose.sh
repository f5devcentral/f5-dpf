#!/usr/bin/env bash
source .env

kubectl -n dpf-operator-system patch svc argo-cd-argocd-server --type merge --patch-file resources/argocd-server-nodeport.yaml
sleep 2
kubectl -n dpf-operator-system get svc argo-cd-argocd-server
echo ""
TARGETCLUSTER_API_SERVER_HOST=$(kubectl get nodes -l node-role.kubernetes.io/control-plane \
  -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo -n "access argo cd UI at https://$TARGETCLUSTER_API_SERVER_HOST:30443, user admin password "
kubectl -n dpf-operator-system get secret argocd-initial-admin-secret   -o jsonpath='{.data.password}' | base64 -d; echo
