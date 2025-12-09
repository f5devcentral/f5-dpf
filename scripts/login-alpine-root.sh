#!/bin/bash
kubectl --kubeconfig=${HOME}/f5-dpf/dpu-cplane-tenant1.kubeconfig -n dpf-operator-system exec -ti $1 -- chroot /host /bin/bash -li

