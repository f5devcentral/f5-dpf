#!/usr/bin/env bash
echo "Once all the hosts are back online, we have to remove an annotation from the DPUNodes."
kubectl annotate dpunodes -n dpf-operator-system --all provisioning.dpu.nvidia.com/dpunode-external-reboot-required-
