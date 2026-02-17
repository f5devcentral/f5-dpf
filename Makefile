.PHONY: all

include .env

all: cluster local-storage bfb-pv create-bmc-pwd dpf-operator dpf-system kamaji-kubeconfig
	@echo ""
	@echo "================================================================================"
	@echo "✅ DPF Cluster Installation Complete!"
	@echo "================================================================================"
	@echo ""
	@echo "Next steps to add worker nodes with DPUs:"
	@echo "1. (optional) expose argocd server UI with 'make argocd'"
	@echo "2. deploy DPF object/use cases with 'make passthru', 'make hbn-pf' or 'make hbn-pf-alpine'"
	@echo "3. verify status with scripts/check-dpusets.sh"
	@echo ""
	@echo "================================================================================"

requirements:
	scripts/install-requirements.sh

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

delete-hbn-pf:
	scripts/hbn-pf-dpf-objects.sh delete || true

hbn-pf-alpine:
	scripts/hbn-pf-dpf-alpine.sh

delete-hbn-pf-alpine:
	scripts/hbn-pf-dpf-alpine.sh delete || true

kamaji-kubeconfig:
	scripts/kamaji-cluster-access.sh

bnk:
	scripts/decode-jwt.sh
	scripts/multus.sh
	scripts/f5-flo.sh
	scripts/hbn-pf-tmm.sh

delete-bnk:
	scripts/hbn-pf-tmm.sh delete
	scripts/f5-flo.sh delete
	scripts/multus.sh delete

clean-all:
	scripts/k0s-cluster.sh delete
