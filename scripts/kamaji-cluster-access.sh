NS=dpu-cplane-tenant1
TCP=dpu-cplane-tenant1
SECRET="${TCP}-admin-kubeconfig"
unset KUBECONFIG
# Extract the file (key is "admin.conf")
kubectl -n "$NS" get secret "$SECRET" -o jsonpath='{.data.admin\.conf}' \
  | base64 -d > "${TCP}.kubeconfig"

echo -n "kubeconfig written to "
ls ${TCP}.kubeconfig
echo ""
# Sanity check
kubectl --kubeconfig "${TCP}.kubeconfig" cluster-info
