# f5-dpf

Proof-of-concept DPF ZT (Zero-Trust) deployment using a single node k0s kubernetes
cluster running on baremetal or in a VM with bridged network access based on
[RDG for DPF Zero Trust (DPF-ZT)](https://docs.nvidia.com/networking/display/public/sol/rdg+for+dpf+zero+trust+(dpf-zt)).

## Requirements

- Linux (amd64) to run k0s (https://k0sproject.io)
- helm https://helm.sh
- helmfile https://github.com/helmfile/helmfile
- kubectl
- 1 or more Nvidia Bluefield-3 DPUs

## Lab Setup

```
+--------------------------+         +--------------------------+
|         worker1          |         |         worker2          |
|             +------------+         +------------+             |
|             |            |         |            |             |
|   enp7s0np0 +  bf-3   p0 +---------+ p0  bf-3   + enp7s0np0   |
|             |  dpu1      |         |     dpu2   |             |
|   enp8s0np0 +         p1 +---------+ p1         + enp8s0np0   |
|             |            |         |            |             |
|             |   oob-net0 +--.   .--+ oob-net0   |             |
|             +------------+  |   |  +------------+             |
|                          |  |   |  |                          |
|                   enp1s0 |  |   |  | enp1s0                   |
+----------------------+---+  |   |  +----+---------------------+
                       |      |   |       |
                       |      |   |       |
           ---+--------+------+---+-------+--------+-----
              |  oob-network 192.168.68.0/22       |.1
              |                                    |
       +------+------+                          +--+--+
       | k0s-cluster |                          | IGW |---{ Internet }
       +-------------+                          +-----+
```

Instead of a typical spine / leaf setup, two DPU's are interconnected
back to back with DAC cables, interconnecting both high speed DPU ports.
HBN with BGP unnumbered will establish peering between DPU nodes. 

The actual physical setup is composed of a single baremetal server with
2 Bluefield-3 DPU's and 2 KVM VMs, worker1 and worker2, using PCI passthru
for the DPU's. 


## Preparation

```
cp .env.example .env
```

Edit environment variables in .env according to your environment.
Make sure your NFS server is reachable at `$NFS_SERVER_IP` and 
exports the specified path `$NFS_SERVER_PATH`

Set `$DPUCLUSTER_VIP` to an IP in the same subnet and interface 
`$DPUCLUSTER_INTERFACE` as the single node k0s cluster that will get created.

## helper shell aliases

The following aliases simplify accessing the kamaji cluster after it has been 
deployed.

```
alias d='kubectl --kubeconfig=/home/mwiget/f5-dpf/dpu-cplane-tenant1.kubeconfig'
alias dk9s='k9s --kubeconfig=/home/mwiget/f5-dpf/dpu-cplane-tenant1.kubeconfig'
```

### Remove DPU lag configuration

Currently DPU provisioning doesn't do a full hardware and configuration reset. In case
the DPU was using LAG mode, remove it first. 
See https://docs.nvidia.com/doca/sdk/link-aggregation/index.html#src-3233877782_id-.LinkAggregationv2.9.0LTS-RemovingLAGConfiguration



## Deploy

```
make

. . .

================================================================================
✅ DPF Cluster Installation Complete!
================================================================================

Next steps to add worker nodes with DPUs:
1. (optional) expose argocd server UI with `make argocd`
2. deploy DPF object/use case with `make passthru`
3. verify status with scripts/check-dpusets.sh

================================================================================
```

## current status

```
$ hostname
dpf

$ kubectl get node -o wide
NAME   STATUS   ROLES           AGE   VERSION       INTERNAL-IP      EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
dpf    Ready    control-plane   28m   v1.33.4+k0s   192.168.68.105   <none>        Ubuntu 24.04.3 LTS   6.8.0-84-generic   containerd://1.7.27
```

```
$ kubectl get pod -A
NAMESPACE                NAME                                                   READY   STATUS    RESTARTS      AGE
cert-manager             cert-manager-69b5985847-dlcbv                          1/1     Running   0             28m
cert-manager             cert-manager-cainjector-54b4c4fc5b-ckm27               1/1     Running   0             28m
cert-manager             cert-manager-webhook-6c9b47775f-4jhbh                  1/1     Running   0             28m
dpf-operator-system      argo-cd-argocd-application-controller-0                1/1     Running   0             28m
dpf-operator-system      argo-cd-argocd-redis-84cf5bf59d-79mvx                  1/1     Running   0             28m
dpf-operator-system      argo-cd-argocd-repo-server-7b6c5b8cdb-998t2            1/1     Running   0             28m
dpf-operator-system      argo-cd-argocd-server-744d5f9c7c-zxc2j                 1/1     Running   0             28m
dpf-operator-system      bfb-registry-gpjhp                                     1/1     Running   0             26m
dpf-operator-system      dpf-operator-controller-manager-7f96b4c7d4-gwxsd       1/1     Running   0             26m
dpf-operator-system      dpf-provisioning-controller-manager-86f54f9566-clx7b   1/1     Running   0             26m
dpf-operator-system      dpuservice-controller-manager-5fb99f78b8-l9d9r         1/1     Running   0             26m
dpf-operator-system      kamaji-9d75c58c7-4gn5p                                 1/1     Running   0             27m
dpf-operator-system      kamaji-cm-controller-manager-5f576cb568-mfrz6          1/1     Running   0             26m
dpf-operator-system      kamaji-etcd-0                                          1/1     Running   0             27m
dpf-operator-system      kamaji-etcd-1                                          1/1     Running   0             27m
dpf-operator-system      kamaji-etcd-2                                          1/1     Running   0             27m
dpf-operator-system      maintenance-operator-585767f779-sl58q                  1/1     Running   0             28m
dpf-operator-system      node-feature-discovery-gc-7f64f764f8-vzrf9             1/1     Running   0             28m
dpf-operator-system      node-feature-discovery-master-6fbc95665c-7sb7t         1/1     Running   0             28m
dpf-operator-system      node-feature-discovery-worker-68nkc                    1/1     Running   0             28m
dpf-operator-system      servicechainset-controller-manager-5dd8cc87cd-85r8b    1/1     Running   2 (25m ago)   25m
dpu-cplane-tenant1       dpu-cplane-tenant1-7d5957c47f-65scl                    3/3     Running   0             26m
dpu-cplane-tenant1       dpu-cplane-tenant1-7d5957c47f-grv87                    3/3     Running   0             26m
dpu-cplane-tenant1       dpu-cplane-tenant1-7d5957c47f-j9vbb                    3/3     Running   0             26m
dpu-cplane-tenant1       dpu-cplane-tenant1-keepalived-7rc62                    1/1     Running   0             26m
kube-system              coredns-6946cc8786-7dggd                               1/1     Running   0             29m
kube-system              kube-proxy-whg2x                                       1/1     Running   0             29m
kube-system              kube-router-r67rx                                      1/1     Running   0             29m
kube-system              metrics-server-7db8586f5-n9wph                         1/1     Running   0             29m
local-path-provisioner   local-path-provisioner-6b669b8d7f-xlvdf                1/1     Running   0             28m
```

```
$ kubectl get deployment -A
NAMESPACE                NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE
cert-manager             cert-manager                               1/1     1            1           29m
cert-manager             cert-manager-cainjector                    1/1     1            1           29m
cert-manager             cert-manager-webhook                       1/1     1            1           29m
dpf-operator-system      argo-cd-argocd-applicationset-controller   0/0     0            0           29m
dpf-operator-system      argo-cd-argocd-redis                       1/1     1            1           29m
dpf-operator-system      argo-cd-argocd-repo-server                 1/1     1            1           29m
dpf-operator-system      argo-cd-argocd-server                      1/1     1            1           29m
dpf-operator-system      dpf-operator-controller-manager            1/1     1            1           28m
dpf-operator-system      dpf-provisioning-controller-manager        1/1     1            1           27m
dpf-operator-system      dpuservice-controller-manager              1/1     1            1           27m
dpf-operator-system      kamaji                                     1/1     1            1           28m
dpf-operator-system      kamaji-cm-controller-manager               1/1     1            1           27m
dpf-operator-system      maintenance-operator                       1/1     1            1           29m
dpf-operator-system      node-feature-discovery-gc                  1/1     1            1           29m
dpf-operator-system      node-feature-discovery-master              1/1     1            1           29m
dpf-operator-system      servicechainset-controller-manager         1/1     1            1           26m
dpu-cplane-tenant1       dpu-cplane-tenant1                         3/3     3            3           27m
kube-system              coredns                                    1/1     1            1           31m
kube-system              metrics-server                             1/1     1            1           30m
local-path-provisioner   local-path-provisioner                     1/1     1            1           30m
```

```
$ kubectl get daemonset -A
NAMESPACE             NAME                            DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                            AGE
dpf-operator-system   bfb-registry                    1         1         1       1            1           <none>                                   27m
dpf-operator-system   node-feature-discovery-worker   1         1         1       1            1           <none>                                   30m
dpu-cplane-tenant1    dpu-cplane-tenant1-keepalived   1         1         1       1            1           node-role.kubernetes.io/control-plane=   27m
kube-system           kube-proxy                      1         1         1       1            1           kubernetes.io/os=linux                   31m
kube-system           kube-router                     1         1         1       1            1           <none>                                   31m
```

```
$ kubectl get services -A
NAMESPACE             NAME                                       TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
cert-manager          cert-manager                               ClusterIP   10.106.127.244   <none>        9402/TCP                     30m
cert-manager          cert-manager-cainjector                    ClusterIP   10.111.165.46    <none>        9402/TCP                     30m
cert-manager          cert-manager-webhook                       ClusterIP   10.101.246.11    <none>        443/TCP,9402/TCP             30m
default               kubernetes                                 ClusterIP   10.96.0.1        <none>        443/TCP                      32m
dpf-operator-system   argo-cd-argocd-applicationset-controller   ClusterIP   10.110.205.140   <none>        7000/TCP                     30m
dpf-operator-system   argo-cd-argocd-redis                       ClusterIP   10.97.80.242     <none>        6379/TCP                     30m
dpf-operator-system   argo-cd-argocd-repo-server                 ClusterIP   10.99.32.145     <none>        8081/TCP                     30m
dpf-operator-system   argo-cd-argocd-server                      NodePort    10.101.239.56    <none>        80:30080/TCP,443:30443/TCP   30m
dpf-operator-system   dpf-provisioning-webhook-service           ClusterIP   10.104.34.192    <none>        443/TCP                      28m
dpf-operator-system   dpuservice-webhook-service                 ClusterIP   10.97.203.0      <none>        443/TCP                      28m
dpf-operator-system   kamaji-etcd                                ClusterIP   None             <none>        2379/TCP,2380/TCP,2381/TCP   29m
dpf-operator-system   kamaji-metrics-service                     ClusterIP   10.105.218.88    <none>        8080/TCP                     29m
dpf-operator-system   kamaji-webhook-service                     ClusterIP   10.105.49.196    <none>        443/TCP                      29m
dpf-operator-system   maintenance-operator-metrics-service       ClusterIP   10.108.55.124    <none>        8443/TCP                     30m
dpf-operator-system   maintenance-operator-webhook-service       ClusterIP   10.106.59.141    <none>        443/TCP                      30m
dpu-cplane-tenant1    dpu-cplane-tenant1                         NodePort    10.100.229.27    <none>        31053:31053/TCP              28m
kube-system           kube-dns                                   ClusterIP   10.96.0.10       <none>        53/UDP,53/TCP,9153/TCP       31m
kube-system           metrics-server                             ClusterIP   10.100.189.164   <none>        443/TCP                      31m
```

## argo cd web ui (optional)

[scripts/argocd-expose.sh](scripts/argocd-expose.sh) exposes argocd over the network and
prints the URL with username and password.

```
$ scripts/argocd-expose.sh 
service/argo-cd-argocd-server patched (no change)
NAME                    TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
argo-cd-argocd-server   NodePort   10.101.239.56   <none>        80:30080/TCP,443:30443/TCP   41m

access argo cd UI at https://192.168.68.105:30443, user admin password .............
```

So far no DPU discovery is happening. The DPF operator is ready to accept DPU objects. See passthru use
case below.
 
## passthru use case

Folder [resources/passthru](resources/passhtru) contains kubectl manifests for BFB, DPUFlavor,
DPUServiceChain, DPUSet and DPUServiceInterface. Deploy them via

```
make passthru

2025-09-29 08:27:52 [INFO] create BFB, DPUSet and DPUServiceChain objects ...
dpuserviceinterface.svc.dpu.nvidia.com/p0 created
dpuserviceinterface.svc.dpu.nvidia.com/p1 created
dpuserviceinterface.svc.dpu.nvidia.com/pf0hpf created
dpuserviceinterface.svc.dpu.nvidia.com/pf1hpf created
dpuset.provisioning.dpu.nvidia.com/passthrough created
bfb.provisioning.dpu.nvidia.com/bf-bundle created
dpuservicechain.svc.dpu.nvidia.com/passthrough created
dpuflavor.provisioning.dpu.nvidia.com/passthrough created
2025-09-29 08:27:52 [INFO] ensure the DPUServiceChain is ready ...
dpuservicechain.svc.dpu.nvidia.com/passthrough condition met
2025-09-29 08:27:53 [INFO] ensure the DPUServiceInterfaces are ready ...
dpuserviceinterface.svc.dpu.nvidia.com/p0 condition met
dpuserviceinterface.svc.dpu.nvidia.com/p1 condition met
dpuserviceinterface.svc.dpu.nvidia.com/pf0hpf condition met
dpuserviceinterface.svc.dpu.nvidia.com/pf1hpf condition met
2025-09-29 08:27:53 [INFO] ensure the BFB is ready ...
bfb.provisioning.dpu.nvidia.com/bf-bundle condition met
2025-09-29 08:27:54 [INFO] ensure the DPUs have the condition initialized (this may take time) ...
dpu.provisioning.dpu.nvidia.com/dpu-node-mt2428xz0n1d-mt2428xz0n1d condition met
dpu.provisioning.dpu.nvidia.com/dpu-node-mt2428xz0r48-mt2428xz0r48 condition met
```

Monitor progress with `scripts/check-dpusets.sh` , which calls

```
$ kubectl -n dpf-operator-system exec deploy/dpf-operator-controller-manager -- /dpfctl describe dpusets

NAME                                            NAMESPACE            STATUS       REASON         SINCE  MESSAGE                                                                          
DPFOperatorConfig/dpfoperatorconfig             dpf-operator-system                                                                                                                       
│           ├─Ready                                                  False        Pending        36m    The following conditions are not ready:                                           
│           │                                                                                           * SystemComponentsReady                                                           
│           └─SystemComponentsReady                                  False        Error          35m    System components must be ready for DPF Operator to continue:                     
│                                                                                                         * nvidia-k8s-ipam: DPUService dpf-operator-system/nvidia-k8s-ipam is not ready  
├─DPUServiceChains                                                                                                                                                                        
│ └─DPUServiceChain/passthrough                 dpf-operator-system  Ready: True  Success        24s                                                                                      
├─DPUServiceInterfaces                                                                                                                                                                    
│ └─4 DPUServiceInterfaces...                   dpf-operator-system  Ready: True  Success        24s    See p0, p1, pf0hpf, pf1hpf                                                        
└─DPUSets                                                                                                                                                                                 
  └─DPUSet/passthrough                          dpf-operator-system                                                                                                                       
    ├─BFB/bf-bundle                             dpf-operator-system  Ready: True  Ready          25s    File: bf-bundle-3.1.0-76_25.07_ubuntu-22.04_prod.bfb, DOCA: 3.1.0                 
    └─DPUs                                                                                                                                                                                
      ├─DPU/dpu-node-mt2428xz0n1d-mt2428xz0n1d  dpf-operator-system                                                                                                                       
      │             └─Ready                                          False        OS Installing  15s                                                                                      
      └─DPU/dpu-node-mt2428xz0r48-mt2428xz0r48  dpf-operator-system                                                                                                                       
                    └─Ready                                          False        OS Installing  15s 
```

The test system discovered 2 Bluefield-3 DPUs, named dpu-node-mt2428* and is installing the BFB image and configuration.
DPU status will eventually change to

```
$ scripts/check-dpusets.sh
NAME                                            NAMESPACE            STATUS       REASON                              SINCE  MESSAGE
DPFOperatorConfig/dpfoperatorconfig             dpf-operator-system
│           ├─Ready                                                  False        Pending                             59m    The following conditions are not ready:
│           │                                                                                                                * SystemComponentsReady
│           └─SystemComponentsReady                                  False        Error                               58m    System components must be ready for DPF Operator to continue:
│                                                                                                                              * nvidia-k8s-ipam: DPUService dpf-operator-system/nvidia-k8s-ipam is not ready
├─DPUServiceChains
│ └─DPUServiceChain/passthrough                 dpf-operator-system  Ready: True  Success                             23m
├─DPUServiceInterfaces
│ └─4 DPUServiceInterfaces...                   dpf-operator-system  Ready: True  Success                             23m    See p0, p1, pf0hpf, pf1hpf
└─DPUSets
  └─DPUSet/passthrough                          dpf-operator-system
    ├─BFB/bf-bundle                             dpf-operator-system  Ready: True  Ready                               23m    File: bf-bundle-3.1.0-76_25.07_ubuntu-22.04_prod.bfb, DOCA: 3.1.0
    └─DPUs
      ├─DPU/dpu-node-mt2428xz0n1d-mt2428xz0n1d  dpf-operator-system
      │             ├─Rebooted                                       False        WaitingForManualPowerCycleOrReboot  9m56s
      │             └─Ready                                          False        Rebooting                           9m56s
      └─DPU/dpu-node-mt2428xz0r48-mt2428xz0r48  dpf-operator-system
                    ├─Rebooted                                       False        WaitingForManualPowerCycleOrReboot  9m51s
                    └─Ready                                          False        Rebooting                           9m51s
```

At this point, we have to power cycle the hosts with the DPU according to https://github.com/NVIDIA/doca-platform/tree/public-release-v25.7/docs/public/user-guides/zero-trust/use-cases/passthrough#making-the-dpus-ready

Once all the hosts are back online, we have to remove an annotation from the DPUNodes. 

```
$ kubectl annotate dpunodes -n dpf-operator-system --all provisioning.dpu.nvidia.com/dpunode-external-reboot-required-
dpunode.provisioning.dpu.nvidia.com/dpu-node-mt2428xz0n1d annotated
dpunode.provisioning.dpu.nvidia.com/dpu-node-mt2428xz0r48 annotated
```

Check status again

```
$ ./scripts/check-dpusets.sh
NAME                                 NAMESPACE            STATUS       REASON    SINCE  MESSAGE
DPFOperatorConfig/dpfoperatorconfig  dpf-operator-system
│           ├─Ready                                       False        Pending   110s   The following conditions are not ready:
│           │                                                                           * SystemComponentsReady
│           └─SystemComponentsReady                       False        Error     11s    System components must be ready for DPF Operator to continue:
│                                                                                         * flannel: DPUService dpf-operator-system/flannel is not ready
│                                                                                         * nvidia-k8s-ipam: DPUService dpf-operator-system/nvidia-k8s-ipam is not ready
│                                                                                         * sfc-controller: DPUService dpf-operator-system/sfc-controller is not ready
├─DPUServiceChains
│ └─DPUServiceChain/passthrough      dpf-operator-system  Ready: True  Success   75s
├─DPUServiceInterfaces
│ └─4 DPUServiceInterfaces...        dpf-operator-system  Ready: True  Success   75s    See p0, p1, pf0hpf, pf1hpf
└─DPUSets
  └─DPUSet/passthrough               dpf-operator-system
    ├─BFB/bf-bundle                  dpf-operator-system  Ready: True  Ready     23m    File: bf-bundle-3.1.0-76_25.07_ubuntu-22.04_prod.bfb, DOCA: 3.1.0
    └─DPUs
      └─2 DPUs...                    dpf-operator-system  Ready: True  DPUReady  7s     See dpu-node-mt2428xz0n1d-mt2428xz0n1d, dpu-node-mt2428xz0r48-mt2428xz0r48
```

Both DPU's are ready. Minutes later, all reported status is now ok.

```
$ kubectl -n dpf-operator-system exec deploy/dpf-operator-controller-manager -- /dpfctl describe dpusets

NAME                                 NAMESPACE            STATUS       REASON    SINCE  MESSAGE
DPFOperatorConfig/dpfoperatorconfig  dpf-operator-system  Ready: True  Success   10m
├─DPUServiceChains
│ └─DPUServiceChain/passthrough      dpf-operator-system  Ready: True  Success   12m
├─DPUServiceInterfaces
│ └─4 DPUServiceInterfaces...        dpf-operator-system  Ready: True  Success   12m    See p0, p1, pf0hpf, pf1hpf
└─DPUSets
  └─DPUSet/passthrough               dpf-operator-system
    ├─BFB/bf-bundle                  dpf-operator-system  Ready: True  Ready     34m    File: bf-bundle-3.1.0-76_25.07_ubuntu-22.04_prod.bfb, DOCA: 3.1.0
    └─DPUs
      └─2 DPUs...                    dpf-operator-system  Ready: True  DPUReady  11m    See dpu-node-mt2428xz0n1d-mt2428xz0n1d, dpu-node-mt2428xz0r48-mt2428xz0r48
```


```
$ kubectl get dpu -n dpf-operator-system dpu-node-mt2428xz0n1d-mt2428xz0n1d -o yaml

apiVersion: provisioning.dpu.nvidia.com/v1alpha1
kind: DPU
metadata:
  creationTimestamp: "2025-09-29T09:39:51Z"
  finalizers:
  - provisioning.dpu.nvidia.com/dpu-protection
  generation: 3
  labels:
    provisioning.dpu.nvidia.com/dpudevice-bmc-ip: 192.168.68.100
    provisioning.dpu.nvidia.com/dpudevice-name: mt2428xz0n1d
    provisioning.dpu.nvidia.com/dpudevice-num-of-pfs: "1"
    provisioning.dpu.nvidia.com/dpudevice-opn: 900-9D3B6-00CV-AA0
    provisioning.dpu.nvidia.com/dpunode-name: dpu-node-mt2428xz0n1d
    provisioning.dpu.nvidia.com/dpuset-name: passthrough
    provisioning.dpu.nvidia.com/dpuset-namespace: dpf-operator-system
  name: dpu-node-mt2428xz0n1d-mt2428xz0n1d
  namespace: dpf-operator-system
  ownerReferences:
  - apiVersion: provisioning.dpu.nvidia.com/v1alpha1
    blockOwnerDeletion: true
    controller: true
    kind: DPUSet
    name: passthrough
    uid: 9be335ec-1048-4d3d-9dcd-32af857b1b7e
  resourceVersion: "7991"
  uid: 0a1a990c-3a89-4d62-9279-94a6e6b49dd6
spec:
  bfb: bf-bundle
  bmcIP: 192.168.68.100
  cluster:
    name: dpu-cplane-tenant1
    namespace: dpu-cplane-tenant1
    nodeLabels:
      operator.dpu.nvidia.com/dpf-version: v25.7.0
      provisioning.dpu.nvidia.com/host: dpu-node-mt2428xz0n1d
  dpuDeviceName: mt2428xz0n1d
  dpuFlavor: passthrough
  dpuNodeName: dpu-node-mt2428xz0n1d
  nodeEffect:
    noEffect: true
  serialNumber: MT2428XZ0N1D
status:
  addresses:
  - address: 192.168.68.79
    type: InternalIP
  - address: dpu-node-mt2428xz0n1d-mt2428xz0n1d
    type: Hostname
  bfCFGFile: bfcfg/dpf-operator-system_dpu-node-mt2428xz0n1d-mt2428xz0n1d_0a1a990c-3a89-4d62-9279-94a6e6b49dd6
  bfbFile: /bfb/dpf-operator-system-bf-bundle.bfb
  conditions:
  - lastTransitionTime: "2025-09-29T09:39:53Z"
    message: ""
    reason: Initialized
    status: "True"
    type: Initialized
  - lastTransitionTime: "2025-09-29T09:39:53Z"
    message: ""
    reason: BFBReady
    status: "True"
    type: BFBReady
  - lastTransitionTime: "2025-09-29T09:39:53Z"
    message: ""
    reason: NodeEffectReady
    status: "True"
    type: NodeEffectReady
  - lastTransitionTime: "2025-09-29T09:39:55Z"
    message: ""
    reason: InterfaceInitialized
    status: "True"
    type: InterfaceInitialized
  - lastTransitionTime: "2025-09-29T09:39:55Z"
    message: ""
    reason: FWConfigured
    status: "True"
    type: FWConfigured
  - lastTransitionTime: "2025-09-29T09:39:55Z"
    message: ""
    reason: BFBPrepared
    status: "True"
    type: BFBPrepared
  - lastTransitionTime: "2025-09-29T09:47:53Z"
    message: 'failed to get system: %!w(<nil>)'
    reason: FailToGetSystem
    status: "False"
    type: OSInstalled
  - lastTransitionTime: "2025-09-29T10:01:34Z"
    message: ""
    reason: Rebooted
    status: "True"
    type: Rebooted
  - lastTransitionTime: "2025-09-29T10:01:34Z"
    message: cluster configured
    reason: DPUClusterReady
    status: "True"
    type: DPUClusterReady
  - lastTransitionTime: "2025-09-29T10:01:34Z"
    message: ""
    reason: DPUReady
    status: "True"
    type: Ready
  dpfVersion: v25.7.0
  dpuInstallInterface: redfish
  firmware: {}
  phase: Ready
```


## Delete cluster

```
make clean-all
```


## Troubleshooting

### failed to set up mTLS: failed to replace CA cert, unexpected response status: 500 Internal server

Fixed this by flashing BMC on DPU and issue factory reset (scripts/factory-reset-dpu.sh).


### bf-bundle not ready.

Check `kubectl describe bfb bf-bundle -n dpf-operator-system`
  If status are write permission related, check NFS server and path

### DPU Discovery

Check logs of dpf-provisioning-controller-manager. Search for `refused` (hint at wrong BMC password) or search for a DPUs
BMC IP address. The IP_RANGE_START/IP_RANGE_END needs to include DPU's BMC IP addresses, not the DPU OS IP.

```
kubectl -n dpf-operator-system logs deploy/dpf-provisioning-controller-manager -c manager 
```

### DPU BMC Password missing

```
$ kubectl -n dpf-operator-system logs deploy/dpf-provisioning-controller-manager -c manager --timestamps |grep Redfish|grep password |tail -1
2025-09-23T06:45:20.696218044Z E0923 06:45:20.696126       1 crawler.go:197] "Failed to create authenticated Redfish client" err="password not specified in secret dpf-operator-system/bmc-shared-password" controller="dpudiscovery" controllerGroup="provisioning.dpu.nvidia.com" controllerKind="DPUDiscovery" DPUDiscovery="dpf-operator-system/dpu-discovery" namespace="dpf-operator-system" name="dpu-discovery" reconcileID="ac8b85ab-18a1-4194-aff9-69212c4f05a3" ip="192.168.68.102"
```

Indicates missing or empty BMC password in secret.
check .env for BMC_ROOT_PASSWORD, which is used by scripts/create-bmc-password-secret.sh:

```
$ k get secret -n dpf-operator-system bmc-shared-password -o yaml
apiVersion: v1
data:
  password: ""
kind: Secret
metadata:
  creationTimestamp: "2025-09-23T06:41:32Z"
  name: bmc-shared-password
  namespace: dpf-operator-system
  resourceVersion: "501"
  uid: 4164ca86-c6fb-4480-8118-50ce27c69141
type: Opaque
```

### FailedToSetUpMTLS

Error shown with `scripts/check-dpusets.sh. Might be related to minimal required BMC version. Use 

```
$ scripts/get-bmc-firmware-info.sh 192.168.68.100
{
  "@odata.id": "/redfish/v1/UpdateService/FirmwareInventory/BMC_Firmware",
  "@odata.type": "#SoftwareInventory.v1_4_0.SoftwareInventory",
  "Description": "BMC image",
  "Id": "BMC_Firmware",
  "Manufacturer": "",
  "Name": "Software Inventory",
  "RelatedItem": [],
  "RelatedItem@odata.count": 0,
  "SoftwareId": "0x0018",
  "Status": {
    "Conditions": [],
    "Health": "OK",
    "HealthRollup": "OK",
    "State": "Enabled"
  },
  "Updateable": true,
  "Version": "BF-25.04-7",
  "WriteProtected": false
```

As DPF is now using v25.7.0, maybe I need to upgrade BMC.

## Installing stuck

ssh into one of the DPU BMC and check process table for `curl`:

```
$ ssh root@192.168.68.100
$ ps | grep curl
22400 root      8404 S    curl -vlf --progress-bar --max-time 2700 -w %{json}\n -o /dev/rshim0/boot http://192.168.68.105:8080/bfb/??dpf-operator-system-bf-bundle.bfb,bfcfg/dpf-operator-system_dpu-node-mt2428x
2
```

This shows the curl command pulling BFB image from the control planes node IP (note: I would have expected to see the VIP used here insted), but either will work.


### DPU serial console via BMC IP

Log into DPU console via BMC, change the default ubuntu/ubuntu password and check interfaces

```
$ ssh root@192.168.68.97
$ export TERM=xterm         # screen doesn't like some other TERM settings
$ screen /dev/rshim0/console 115200
<hit enter a few times to get the login prompt>
dpu-node-mt2428xz0r48-mt2428xz0r48 login:
dpu-node-mt2428xz0r48-mt2428xz0r48 login:
dpu-node-mt2428xz0r48-mt2428xz0r48 login: ubuntu
Password:
You are required to change your password immediately (administrator enforced).
Changing password for ubuntu.
Current password:
New password:
Retype new password:
Welcome to Ubuntu 22.04.5 LTS (GNU/Linux 5.15.0-1074-bluefield aarch64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Mon Sep 29 08:55:11 UTC 2025

  System load:  0.52               Swap usage:  0%       Users logged in: 0
  Usage of /:   4.8% of 116.76GB   Temperature: 75.0 C
  Memory usage: 3%                 Processes:   340

Expanded Security Maintenance for Applications is not enabled.

0 updates can be applied immediately.

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status



The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

ubuntu@dpu-node-mt2428xz0r48-mt2428xz0r48:~$ ip -br a
lo               UNKNOWN        127.0.0.1/8 ::1/128
oob_net0         DOWN
tmfifo_net0      DOWN
p0               UP             fe80::5e25:73ff:fee7:906e/64
p1               UP             fe80::5e25:73ff:fee7:906f/64
pf0hpf           UP             fe80::a81f:f2ff:fe36:ba8b/64
pf1hpf           UP             fe80::3:89ff:fed4:66ef/64
en3f0pf0sf0      UP
enp3s0f0s0       UP             fe80::9f:3fff:fe8d:69a7/64
en3f1pf1sf0      UP
enp3s0f1s0       UP             fe80::a3:88ff:fed2:7d4a/64
ovs-doca         DOWN
ubuntu@dpu-node-mt2428xz0r48-mt2428xz0r48:~$
```

Terminate screen by typing `Ctrl-a :quit`, then exit ssh

```
[screen is terminating]

root@dpu-bmc:~#
root@dpu-bmc:~# exit
logout
Connection to 192.168.68.97 closed.
```

The DPU itself doesn't run dhcpclient, so it is only reachable via console.

## Caveats

If imaging the DPU via DPF suddenly stops working with 

`FailedToSetUpMTLS     18m    failed to set up mTLS: failed to replace CA cert, unexpected response status: 500 Internal Server`

check if the cert truststore of the DPU has filled up. It has 11 slots.
The script checks the cert slots, showing all full. Use the delete script to clear all but the first one, then check again.
This will resove the issue and imaging proceeds.

```
$ scripts/check-dpu-truststore-certs.sh worker1-dpu-bmc
===== worker1-dpu-bmc /redfish/v1/CertificateService/CertificateLocations =====
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  1547  100  1547    0     0   8458      0 --:--:-- --:--:-- --:--:--  8500
{
  "@odata.id": "/redfish/v1/CertificateService/CertificateLocations",
  "@odata.type": "#CertificateLocations.v1_0_0.CertificateLocations",
  "Description": "Defines a resource that an administrator can use in order to locate all certificates installed on a given service",
  "Id": "CertificateLocations",
  "Links": {
    "Certificates": [
      {
        "@odata.id": "/redfish/v1/Managers/Bluefield_BMC/Truststore/Certificates/1"
      },
      {
        "@odata.id": "/redfish/v1/Managers/Bluefield_BMC/Truststore/Certificates/10"
      },
      {
        "@odata.id": "/redfish/v1/Managers/Bluefield_BMC/Truststore/Certificates/2"
      },
      {
        "@odata.id": "/redfish/v1/Managers/Bluefield_BMC/Truststore/Certificates/3"
      },
      {
        "@odata.id": "/redfish/v1/Managers/Bluefield_BMC/Truststore/Certificates/4"
      },
      {
        "@odata.id": "/redfish/v1/Managers/Bluefield_BMC/Truststore/Certificates/5"
      },
      {
        "@odata.id": "/redfish/v1/Managers/Bluefield_BMC/Truststore/Certificates/6"
      },
      {
        "@odata.id": "/redfish/v1/Managers/Bluefield_BMC/Truststore/Certificates/7"
      },
      {
        "@odata.id": "/redfish/v1/Managers/Bluefield_BMC/Truststore/Certificates/8"
      },
      {
        "@odata.id": "/redfish/v1/Managers/Bluefield_BMC/Truststore/Certificates/9"
      },
      {
        "@odata.id": "/redfish/v1/Managers/Bluefield_BMC/NetworkProtocol/HTTPS/Certificates/1"
      }
    ],
    "Certificates@odata.count": 11
  },
  "Name": "Certificate Locations"
}
```

```
$ ./scripts/delete-dpu-truststore-certs.sh worker1-dpu-bmc
Deleting truststore certificates on worker1-dpu-bmc (keeping slot 1) ===
Deleting certificate slot 2: /redfish/v1/Managers/Bluefield_BMC/Truststore/Certificates/2
  Deleted slot 2 successfully (HTTP 204)
Deleting certificate slot 3: /redfish/v1/Managers/Bluefield_BMC/Truststore/Certificates/3
  Deleted slot 3 successfully (HTTP 204)
Deleting certificate slot 4: /redfish/v1/Managers/Bluefield_BMC/Truststore/Certificates/4
  Deleted slot 4 successfully (HTTP 204)
Deleting certificate slot 5: /redfish/v1/Managers/Bluefield_BMC/Truststore/Certificates/5
  Deleted slot 5 successfully (HTTP 204)
Deleting certificate slot 6: /redfish/v1/Managers/Bluefield_BMC/Truststore/Certificates/6
  Deleted slot 6 successfully (HTTP 204)
Deleting certificate slot 7: /redfish/v1/Managers/Bluefield_BMC/Truststore/Certificates/7
  Deleted slot 7 successfully (HTTP 204)
Deleting certificate slot 8: /redfish/v1/Managers/Bluefield_BMC/Truststore/Certificates/8
  Deleted slot 8 successfully (HTTP 204)
Deleting certificate slot 9: /redfish/v1/Managers/Bluefield_BMC/Truststore/Certificates/9
  Deleted slot 9 successfully (HTTP 204)
Deleting certificate slot 10: /redfish/v1/Managers/Bluefield_BMC/Truststore/Certificates/10
  Deleted slot 10 successfully (HTTP 204)
Done. Remaining slots ===
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   738  100   738    0     0   1740      0 --:--:-- --:--:-- --:--:--  1744
[
  {
    "@odata.id": "/redfish/v1/Managers/Bluefield_BMC/Truststore/Certificates/1"
  },
  {
    "@odata.id": "/redfish/v1/Managers/Bluefield_BMC/Truststore/Certificates/11"
  },
  {
    "@odata.id": "/redfish/v1/Managers/Bluefield_BMC/NetworkProtocol/HTTPS/Certificates/1"
  }
]
```

## Resources

- https://github.com/NVIDIA/doca-platform/blob/public-release-v25.7/docs/public/user-guides/zero-trust/use-cases/passthrough/README.md
