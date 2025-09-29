#!/usr/bin/env bash
kubectl -n dpf-operator-system exec deploy/dpf-operator-controller-manager -- /dpfctl describe dpusets
