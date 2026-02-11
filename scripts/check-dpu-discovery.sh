kubectl -n dpf-operator-system logs deploy/dpf-provisioning-controller-manager -c manager |grep 'Found DPU BMC'
echo ""
kubectl -n dpf-operator-system logs deploy/dpf-provisioning-controller-manager -c manager |grep 'Found existing DPU device'
