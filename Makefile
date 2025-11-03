.PHONY: all

include .env

all: cluster local-storage bfb-pv create-bmc-pwd dpf-operator dpf-system
	@echo ""
	@echo "================================================================================"
	@echo "✅ DPF Cluster Installation Complete!"
	@echo "================================================================================"
	@echo ""
	@echo "Next steps to add worker nodes with DPUs:"
	@echo "1. (optional) expose argocd server UI with 'make argocd'"
	@echo "2. deploy DPF object/use cases with 'make passthru' or 'make hbn-pf'"
	@echo "3. verify status with scripts/check-dpusets.sh"
	@echo ""
	@echo "================================================================================"

cluster:
	scripts/k0s-cluster.sh

local-storage:
	scripts/local-path-provisioner.sh

bfb-pv:
	scripts/bfb-pv.sh

create-bmc-pwd:
	scripts/bmc-password-secret.sh

dpf-operator:
	scripts/dpf-operator.sh

dpf-system:
	scripts/dpf-system.sh

argocd:
	scripts/argocd-expose.sh

passthru:
	scripts/passthru-dpf-objects.sh

hbn-pf:
	scripts/hbn-pf-dpf-objects.sh

clean-all:
	scripts/k0s-cluster.sh delete
