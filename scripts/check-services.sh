#!/bin/bash
echo "DPUServiceInterface:"
kubectl -n dpf-operator-system get dpuserviceinterface
echo ""
echo "DPUService:"
kubectl -n dpf-operator-system get dpuservice
echo ""
echo "DPUServiceChain:"
kubectl -n dpf-operator-system get dpuservicechain
echo ""
echo "DPUServiceTemplate:"
kubectl -n dpf-operator-system get dpuserviceTemplate
echo ""
echo "DPUServiceConfiguration:"
kubectl -n dpf-operator-system get dpuserviceConfiguration
