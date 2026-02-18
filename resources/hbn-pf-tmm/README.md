## Deploy HBN TMM service 

DPUServiceConfiguration alpine-sfc is attached to HBN pod via two interfaces, internal_sf and
external_sf. 

```
$ k get node -o wide
NAME   STATUS   ROLES           AGE    VERSION       INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
dpf1   Ready    control-plane   165m   v1.34.3+k0s   192.168.68.73   <none>        Ubuntu 24.04.4 LTS   6.8.0-100-generic   containerd://1.7.30
```

```
$ k get pod -A
NAMESPACE                NAME                                                  READY   STATUS              RESTARTS       AGE
cert-manager             cert-manager-c8685d75c-ws5hq                          1/1     Running             0              155m
cert-manager             cert-manager-cainjector-6697bc4f6b-tgnnw              1/1     Running             0              155m
cert-manager             cert-manager-webhook-55c9496865-kgmfv                 1/1     Running             0              155m
dpf-operator-system      argo-cd-argocd-application-controller-0               1/1     Running             0              161m
dpf-operator-system      argo-cd-argocd-redis-668b4f49b6-n45q7                 1/1     Running             0              161m
dpf-operator-system      argo-cd-argocd-repo-server-76dd95c76f-fpmr4           1/1     Running             0              161m
dpf-operator-system      argo-cd-argocd-server-5475d79859-b8n5t                1/1     Running             0              161m
dpf-operator-system      bfb-registry-mzqlx                                    1/1     Running             0              159m
dpf-operator-system      crd-installer-brdc5                                   0/1     Completed           0              154m
dpf-operator-system      dpf-operator-controller-manager-6c6f5b854-ftcnc       1/1     Running             0              159m
dpf-operator-system      dpf-provisioning-controller-manager-5d4df4bd7-jd8k5   1/1     Running             0              159m
dpf-operator-system      dpuservice-controller-manager-7f8f888899-ldms5        1/1     Running             0              159m
dpf-operator-system      f5-cne-controller-77ccfb698-9d6mr                     3/3     Running             0              154m
dpf-operator-system      f5-crdconversion-c55dbb49c-nq6dj                      1/1     Running             0              154m
dpf-operator-system      f5-dssm-db-0                                          0/2     ContainerCreating   0              154m
dpf-operator-system      f5-dssm-sentinel-0                                    0/2     ContainerCreating   0              154m
dpf-operator-system      f5-rabbit-686f957f5-ndgwv                             1/1     Running             0              154m
dpf-operator-system      f5-spk-cwc-5d49dc97d9-qrpxk                           2/2     Running             0              154m
dpf-operator-system      flo-f5-lifecycle-operator-744d86c99b-597f2            2/2     Running             0              155m
dpf-operator-system      kamaji-79777fc4cb-t9n2s                               1/1     Running             0              160m
dpf-operator-system      kamaji-cm-controller-manager-747bfdf86b-jrjxz         1/1     Running             0              159m
dpf-operator-system      kamaji-etcd-0                                         1/1     Running             0              160m
dpf-operator-system      kamaji-etcd-1                                         1/1     Running             0              160m
dpf-operator-system      kamaji-etcd-2                                         1/1     Running             0              160m
dpf-operator-system      maintenance-operator-7b877f7bb7-75std                 1/1     Running             0              161m
dpf-operator-system      node-feature-discovery-gc-84d76bff96-gjlkh            1/1     Running             0              162m
dpf-operator-system      node-feature-discovery-master-f6d575c87-zljvs         1/1     Running             0              162m
dpf-operator-system      node-feature-discovery-worker-nr46g                   1/1     Running             0              162m
dpf-operator-system      servicechainset-controller-manager-76cc6744c-r26rl    1/1     Running             2 (158m ago)   158m
dpu-cplane-tenant1       dpu-cplane-tenant1-64bf766f9b-8kzgj                   3/3     Running             0              159m
dpu-cplane-tenant1       dpu-cplane-tenant1-64bf766f9b-dqx2x                   3/3     Running             0              159m
dpu-cplane-tenant1       dpu-cplane-tenant1-64bf766f9b-nphnj                   3/3     Running             0              159m
dpu-cplane-tenant1       dpu-cplane-tenant1-keepalived-cn9ds                   1/1     Running             0              159m
kube-system              coredns-6c65b966d4-hblrt                              1/1     Running             0              163m
kube-system              csi-nfs-controller-7d6df96d96-mhj6n                   5/5     Running             0              162m
kube-system              csi-nfs-node-qmts4                                    3/3     Running             0              162m
kube-system              kube-multus-ds-mgd56                                  1/1     Running             0              156m
kube-system              kube-proxy-prd9b                                      1/1     Running             0              163m
kube-system              kube-router-9qr7d                                     1/1     Running             0              163m
kube-system              metrics-server-67bc669cf4-5wlh2                       1/1     Running             0              163m
local-path-provisioner   local-path-provisioner-756c977f54-p54zt               1/1     Running             0              162metrics-server-67bc669cf4-5wlh2
```

```
$ d get node -A
NAME                                 STATUS   ROLES    AGE   VERSION
dpu-node-mt2428xz0n1d-mt2428xz0n1d   Ready    <none>   65m   v1.30.14
dpu-node-mt2428xz0r48-mt2428xz0r48   Ready    <none>   65m   v1.30.14
```

```
$ d get pod -A
NAMESPACE             NAME                                                             READY   STATUS    RESTARTS   AGE
dpf-operator-system   dpu-cplane-tenant1-cni-installer-9rjpd                           1/1     Running   0          65m
dpf-operator-system   dpu-cplane-tenant1-cni-installer-gxdzv                           1/1     Running   0          65m
dpf-operator-system   dpu-cplane-tenant1-doca-hbn-jmll8-ds-px9c6                       2/2     Running   0          47m
dpf-operator-system   dpu-cplane-tenant1-doca-hbn-jmll8-ds-s9d5l                       2/2     Running   0          47m
dpf-operator-system   dpu-cplane-tenant1-nvidia-k8s-ipam-controller-5c77854fcc-stfld   1/1     Running   0          114m
dpf-operator-system   dpu-cplane-tenant1-nvidia-k8s-ipam-node-ds-tftrx                 1/1     Running   0          65m
dpf-operator-system   dpu-cplane-tenant1-nvidia-k8s-ipam-node-ds-vfp4h                 1/1     Running   0          65m
dpf-operator-system   dpu-cplane-tenant1-ovs-cni-arm64-wln92                           1/1     Running   0          65m
dpf-operator-system   dpu-cplane-tenant1-ovs-cni-arm64-wn5pl                           1/1     Running   0          65m
dpf-operator-system   dpu-cplane-tenant1-sfc-controller-node-ds-9mcn6                  1/1     Running   0          65m
dpf-operator-system   dpu-cplane-tenant1-sfc-controller-node-ds-wnfjb                  1/1     Running   0          65m
dpf-operator-system   dpu-cplane-tenant1-tmm-sfc-dslqj-f5-tmm-62x7s                    4/4     Running   0          65m
dpf-operator-system   dpu-cplane-tenant1-tmm-sfc-dslqj-f5-tmm-z47cr                    4/4     Running   0          65m
dpf-operator-system   kube-flannel-ds-87ts4                                            1/1     Running   0          65m
dpf-operator-system   kube-flannel-ds-ds7hw                                            1/1     Running   0          65m
dpf-operator-system   kube-multus-ds-gvrmc                                             1/1     Running   0          65m
dpf-operator-system   kube-multus-ds-msjcn                                             1/1     Running   0          65m
dpf-operator-system   kube-sriov-device-plugin-fb9mc                                   1/1     Running   0          65m
dpf-operator-system   kube-sriov-device-plugin-qm8cf                                   1/1     Running   0          65m
kube-system           coredns-66bc5c9577-ltqcf                                         1/1     Running   0          114m
kube-system           coredns-66bc5c9577-s7vhg                                         1/1     Running   0          114m
kube-system           kube-proxy-dtzj9                                                 1/1     Running   0          65m
kube-system           kube-proxy-zpfsq                                                 1/1     Running   0          65m
```


```
```
