## HBN in DPF Zero Trust

Source: https://github.com/NVIDIA/doca-platform/tree/public-release-v25.7/docs/public/user-guides/zero-trust/use-cases/hbn

Deploy with

```
make all
make hbn-pf
```

watch DPU imaging and provisioning progress with `scripts/check-dpudeployments.sh` and remove annotation with 
`scripts/remove-dpu-reboot-annotation.sh` once status 'WaitingForManualPowerCycleOrReboot' is shown. 

PF only manifests are applied.

worker1 netplan:

```
root@worker1:/home/mwiget# cat /etc/netplan/10-static.yaml
# /etc/netplan/10-static-enp7s0np0.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp7s0np0:
      dhcp4: no
      addresses:
        - 10.0.121.9/29
      routes:
        - to: 10.0.121.0/24
          via: 10.0.121.10
          on-link: true
```

worker2 netplan:

```
root@worker2:/home/mwiget# cat /etc/netplan/10-static.yaml
# /etc/netplan/10-static-enp7s0np0.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp8s0np0:
      dhcp4: no
      addresses:
        - 10.0.121.1/29
      routes:
        - to: 10.0.121.0/24
          via: 10.0.121.2
          on-link: true
```

Not sure why the interfaces are crossed, but the setup is using KVM with PIC passthru, which could explain it.

Test connectivity from worker1 to worker2 via PF's:

```
root@worker1:/home/mwiget# ip -br a
lo               UNKNOWN        127.0.0.1/8 ::1/128
enp1s0           UP             192.168.68.76/22 metric 100 fe80::5054:ff:fe77:f04f/64
enp7s0np0        UP             10.0.121.9/29 fe80::5e25:73ff:fee7:905e/64
enp8s0np0        DOWN
root@worker1:/home/mwiget# ping 10.0.121.1 -c3
PING 10.0.121.1 (10.0.121.1) 56(84) bytes of data.
64 bytes from 10.0.121.1: icmp_seq=1 ttl=62 time=0.294 ms
64 bytes from 10.0.121.1: icmp_seq=2 ttl=62 time=0.245 ms
64 bytes from 10.0.121.1: icmp_seq=3 ttl=62 time=0.215 ms

--- 10.0.121.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2036ms
rtt min/avg/max/mdev = 0.215/0.251/0.294/0.032 manifests
```


Checking HBN on DPU1:

```
ssh worker1-dpu
sudo

root@dpu-node-mt2428xz0n1d-mt2428xz0n1d:/home/ubuntu# crictl ps
CONTAINER           IMAGE               CREATED             STATE               NAME                ATTEMPT             POD ID              POD                                                NAMESPACE
ad9ef6507fcda       a006d46d2a784       26 hours ago        Running             hbn-sidecar         0                   9d955f0dc6ed8       dpu-cplane-tenant1-doca-hbn-8d5f9-ds-77bwg         dpf-operator-system
e084f223c4898       a006d46d2a784       26 hours ago        Running             doca-hbn            0                   9d955f0dc6ed8       dpu-cplane-tenant1-doca-hbn-8d5f9-ds-77bwg         dpf-operator-system
27ccdffcd9ea7       150fdcc3f7f83       26 hours ago        Running             node                0                   dffa0d1588d17       dpu-cplane-tenant1-nvidia-k8s-ipam-node-ds-5jccf   dpf-operator-system
7c06fbbde1cfd       f72407be9e08c       26 hours ago        Running             coredns             0                   c8dd12a160380       coredns-796d84c46b-g7tq6                           kube-system
31b2ee3b063c4       25f5b8af4a486       26 hours ago        Running             sfc-controller      0                   96e73f05193e7       dpu-cplane-tenant1-sfc-controller-node-ds-g7z42    dpf-operator-system
9debe15361f37       f66f17ad70562       26 hours ago        Running             kube-flannel        0                   ca6987fe47798       kube-flannel-ds-ppflq                              dpf-operator-system
12c8a414bd3e1       baa9c041885c2       26 hours ago        Running             kube-sriovdp        0                   e096ce6f4ac85       kube-sriov-device-plugin-dwxgr                     dpf-operator-system
32227c2ca0ea7       9882f97bd9ab5       26 hours ago        Running             kube-multus         0                   3c2805f1daea0       kube-multus-ds-6dmvw                               dpf-operator-system
b41837af7e051       220e6b426b002       26 hours ago        Running             ovs-cni-marker      0                   4adc39c7d7b80       dpu-cplane-tenant1-ovs-cni-arm64-dcnql             dpf-operator-system
b83d1ec744e1e       8d27a60846a20       26 hours ago        Running             kube-proxy          0                   073b57e74fba4       kube-proxy-9lzhl                                   kube-system
root@dpu-node-mt2428xz0n1d-mt2428xz0n1d:/home/ubuntu#
root@dpu-node-mt2428xz0n1d-mt2428xz0n1d:/home/ubuntu# crictl exec -ti e084f223c4898 bash
root@dpu-cplane-tenant1-doca-hbn-8d5f9-ds-77bwg:/tmp#
root@dpu-cplane-tenant1-doca-hbn-8d5f9-ds-77bwg:/tmp# ip -br a
lo               UNKNOWN        127.0.0.1/8 11.0.0.0/32 ::1/128
eth0@if100       UP             10.244.0.5/24 fe80::1807:2fff:fe13:c461/64
mgmt             UP             127.0.0.1/8 ::1/128
BLUE             UP             127.0.0.1/8 127.0.1.1/8 ::1/128
vxlan48          UNKNOWN        fe80::e4db:12ff:feb0:8d26/64
br_default       UP             fe80::e4db:12ff:feb0:8d26/64
vlan4006_l3@br_default UP             fe80::e4db:12ff:feb0:8d26/64
RED              UP             127.0.0.1/8 127.0.1.1/8 ::1/128
vlan4063_l3@br_default UP             fe80::e4db:12ff:feb0:8d26/64
pf1hpf_if        UP             10.0.122.2/29 fe80::6cb1:2fff:feed:d3f1/64
p0_if            UP             fe80::f4af:9ff:fe4b:d271/64
pf0hpf_if        UP             10.0.121.2/29 fe80::f01f:10ff:fed0:8b06/64
p1_if            UP             fe80::306b:5ff:fea4:7cfd/64
root@dpu-cplane-tenant1-doca-hbn-8d5f9-ds-77bwg:/tmp#
root@dpu-cplane-tenant1-doca-hbn-8d5f9-ds-77bwg:/tmp# vtysh

Hello, this is FRRouting (version 8.4.3).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

dpu-cplane-tenant1-doca-hbn-8d5f9-ds-77bwg# show bgp summary

IPv4 Unicast Summary (VRF default):
BGP router identifier 11.0.0.0, local AS number 65101 vrf-id 0
BGP table version 2
RIB entries 3, using 672 bytes of memory
Peers 2, using 40 KiB of memory
Peer groups 1, using 64 bytes of memory

Neighbor                                          V         AS   MsgRcvd   MsgSent   TblVer  InQ OutQ  Up/Down State/PfxRcd   PfxSnt Desc
dpu-cplane-tenant1-doca-hbn-8d5f9-ds-pgv7p(p0_if) 4      65201     31228     31228        0    0    0 1d02h00m            1        2 N/A
dpu-cplane-tenant1-doca-hbn-8d5f9-ds-pgv7p(p1_if) 4      65201     31228     31228        0    0    0 1d02h00m            1        2 N/A

Total number of neighbors 2

L2VPN EVPN Summary (VRF default):
BGP router identifier 11.0.0.0, local AS number 65101 vrf-id 0
BGP table version 0
RIB entries 7, using 1568 bytes of memory
Peers 2, using 40 KiB of memory
Peer groups 1, using 64 bytes of memory

Neighbor                                          V         AS   MsgRcvd   MsgSent   TblVer  InQ OutQ  Up/Down State/PfxRcd   PfxSnt Desc
dpu-cplane-tenant1-doca-hbn-8d5f9-ds-pgv7p(p0_if) 4      65201     31228     31228        0    0    0 1d02h00m            2        4 N/A
dpu-cplane-tenant1-doca-hbn-8d5f9-ds-pgv7p(p1_if) 4      65201     31228     31228        0    0    0 1d02h00m            2        4 N/A

Total number of neighbors 2

```

```

dpu-cplane-tenant1-doca-hbn-8d5f9-ds-77bwg# show running-config
Building configuration...

Current configuration:
!
frr version 8.4.3
frr defaults datacenter
hostname dpu-cplane-tenant1-doca-hbn-8d5f9-ds-77bwg
log syslog informational
log timestamp precision 6
bgp graceful-restart
service integrated-vtysh-config
!
vrf BLUE
 vni 100002
exit-vrf
!
vrf RED
 vni 100001
exit-vrf
!
router bgp 65101
 bgp router-id 11.0.0.0
 bgp bestpath as-path multipath-relax
 neighbor hbn peer-group
 neighbor hbn remote-as external
 neighbor hbn advertisement-interval 0
 neighbor hbn timers 3 9
 neighbor hbn timers connect 10
 neighbor p0_if interface peer-group hbn
 neighbor p0_if advertisement-interval 0
 neighbor p0_if timers 3 9
 neighbor p0_if timers connect 10
 neighbor p1_if interface peer-group hbn
 neighbor p1_if advertisement-interval 0
 neighbor p1_if timers 3 9
 neighbor p1_if timers connect 10
 !
 address-family ipv4 unicast
  redistribute connected
  maximum-paths 16
  maximum-paths ibgp 64
 exit-address-family
 !
 address-family l2vpn evpn
  neighbor hbn activate
  advertise-all-vni
 exit-address-family
exit
!
router bgp 65101 vrf RED
 !
 address-family ipv4 unicast
  redistribute connected
  maximum-paths 64
  maximum-paths ibgp 64
 exit-address-family
 !
 address-family l2vpn evpn
  advertise ipv4 unicast
 exit-address-family
exit
!
router bgp 65101 vrf BLUE
 !
 address-family ipv4 unicast
  redistribute connected
  maximum-paths 64
  maximum-paths ibgp 64
 exit-address-family
 !
 address-family l2vpn evpn
  advertise ipv4 unicast
 exit-address-family
exit
!
bfd
exit
!
end
```

```
dpu-cplane-tenant1-doca-hbn-8d5f9-ds-77bwg# show ip route
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, A - Babel, D - SHARP, F - PBR, f - OpenFabric,
       Z - FRR,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

C>* 11.0.0.0/32 is directly connected, lo, 1d02h03m
B>* 11.0.0.1/32 [20/0] via fe80::b810:f7ff:fe22:82cc, p1_if, weight 1, 1d02h03m
  *                    via fe80::e08a:e2ff:fe5a:1da7, p0_if, weight 1, 1d02h03m
```

```
dpu-cplane-tenant1-doca-hbn-8d5f9-ds-77bwg# show interface vrf RED brief
Interface       Status  VRF             Addresses
---------       ------  ---             ---------
RED             up      RED
pf0hpf_if       up      RED             10.0.121.2/29
vlan4063_l3     up      RED

dpu-cplane-tenant1-doca-hbn-8d5f9-ds-77bwg#
dpu-cplane-tenant1-doca-hbn-8d5f9-ds-77bwg# show interface vrf RED
Interface RED is up, line protocol is up
  Link ups:       0    last: (never)
  Link downs:     0    last: (never)
  vrf: RED
  index 11 metric 0 mtu 65575 speed 0
  flags: <UP,RUNNING,NOARP>
  Type: Ethernet
  HWaddr: 12:93:a2:02:4d:f5
  Interface Type VRF
  Interface Slave Type None
  protodown: off
Interface pf0hpf_if is up, line protocol is up
  Link ups:       0    last: (never)
  Link downs:     0    last: (never)
  vrf: RED
  index 69 metric 0 mtu 9000 speed 200000
  flags: <UP,BROADCAST,RUNNING,MULTICAST>
  Type: Ethernet
  HWaddr: f2:1f:10:d0:8b:06
  inet 10.0.121.2/29
  inet6 fe80::f01f:10ff:fed0:8b06/64
  Interface Type Other
  Interface Slave Type Vrf
  protodown: off
Interface vlan4063_l3 is up, line protocol is up
  Link ups:       0    last: (never)
  Link downs:     0    last: (never)
  vrf: RED
  index 12 metric 0 mtu 9216 speed 4294967295
  flags: <UP,BROADCAST,RUNNING,MULTICAST>
  Type: Ethernet
  HWaddr: e6:db:12:b0:8d:26
  inet6 fe80::e4db:12ff:feb0:8d26/64
  Interface Type Vlan
  Interface Slave Type Vrf
  VLAN Id 4063
  protodown: off
  Parent interface: br_default
```

```
dpu-cplane-tenant1-doca-hbn-8d5f9-ds-77bwg# show evpn vni
VNI        Type VxLAN IF              # MACs   # ARPs   # Remote VTEPs  Tenant VRF      VLAN       BRIDGE
100001     L3   vxlan48               1        1        n/a             RED
100002     L3   vxlan48               1        1        n/a             BLUE

```

```
dpu-cplane-tenant1-doca-hbn-8d5f9-ds-77bwg# show bgp vrf RED ipv4 unicast
BGP table version is 2, local router ID is 10.0.121.2, vrf id 11
Default local pref 100, local AS 65101
Status codes:  s suppressed, d damped, h history, u unsorted, * valid, > best, = multipath, + multipath nhg,
               i internal, r RIB-failure, S Stale, R Removed
Nexthop codes: @NNN nexthop's vrf id, < announce-nh-self
Origin codes:  i - IGP, e - EGP, ? - incomplete
RPKI validation codes: V valid, I invalid, N Not found

   Network          Next Hop            Metric LocPrf Weight Path
*> 10.0.121.0/29    0.0.0.0(dpu-cplane-tenant1-doca-hbn-8d5f9-ds-77bwg)
                                             0         32768 ?
*> 10.0.121.8/29    11.0.0.1(dpu-cplane-tenant1-doca-hbn-8d5f9-ds-pgv7p)<
                                             0             0 65201 ?
*                   11.0.0.1(dpu-cplane-tenant1-doca-hbn-8d5f9-ds-pgv7p)<
                                             0             0 65201 ?

Displayed  2 routes and 3 total paths
```

Access kamaji cluster via kubeconfig:

```
$ scripts/kamaji-cluster-access.sh
kubeconfig written to dpu-cplane-tenant1.kubeconfig

Kubernetes control plane is running at https://192.168.68.20:30114
CoreDNS is running at https://192.168.68.20:30114/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.

$ export KUBECONFIG=$PWD/dpu-cplane-tenant1.kubeconfig

$ kubectl get pod -A
NAMESPACE             NAME                                                             READY   STATUS    RESTARTS   AGE
dpf-operator-system   dpu-cplane-tenant1-doca-hbn-8d5f9-ds-77bwg                       2/2     Running   0          47h
dpf-operator-system   dpu-cplane-tenant1-doca-hbn-8d5f9-ds-pgv7p                       2/2     Running   0          47h
dpf-operator-system   dpu-cplane-tenant1-nvidia-k8s-ipam-controller-6cb8f65fc5-8hkt7   1/1     Running   0          2d
dpf-operator-system   dpu-cplane-tenant1-nvidia-k8s-ipam-node-ds-5jccf                 1/1     Running   0          47h
dpf-operator-system   dpu-cplane-tenant1-nvidia-k8s-ipam-node-ds-c2h7z                 1/1     Running   0          47h
dpf-operator-system   dpu-cplane-tenant1-ovs-cni-arm64-dcnql                           1/1     Running   0          47h
dpf-operator-system   dpu-cplane-tenant1-ovs-cni-arm64-zgm92                           1/1     Running   0          47h
dpf-operator-system   dpu-cplane-tenant1-sfc-controller-node-ds-g7z42                  1/1     Running   0          47h
dpf-operator-system   dpu-cplane-tenant1-sfc-controller-node-ds-rsr6p                  1/1     Running   0          47h
dpf-operator-system   kube-flannel-ds-ppflq                                            1/1     Running   0          47h
dpf-operator-system   kube-flannel-ds-sndqv                                            1/1     Running   0          47h
dpf-operator-system   kube-multus-ds-6dmvw                                             1/1     Running   0          47h
dpf-operator-system   kube-multus-ds-jqxg4                                             1/1     Running   0          47h
dpf-operator-system   kube-sriov-device-plugin-4vthv                                   1/1     Running   0          47h
dpf-operator-system   kube-sriov-device-plugin-dwxgr                                   1/1     Running   0          47h
kube-system           coredns-796d84c46b-dtksm                                         1/1     Running   0          2d
kube-system           coredns-796d84c46b-g7tq6                                         1/1     Running   0          2d
kube-system           kube-proxy-9lzhl                                                 1/1     Running   0          47h
kube-system           kube-proxy-j8cw8                                                 1/1     Running   0          47h
```


```
root@dpu-cplane-tenant1-doca-hbn-8d5f9-ds-pgv7p:/tmp# brctl show
bridge name     bridge id               STP enabled     interfaces
br_default              8000.4ef227be4c6c       no              vxlan48
root@dpu-cplane-tenant1-doca-hbn-8d5f9-ds-pgv7p:/tmp# ip link show dev pf0hpf_if    
74: pf0hpf_if: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9000 qdisc mq master RED state UP mode DEFAULT group default qlen 1000
    link/ether 0e:d6:7e:dc:e8:b7 brd ff:ff:ff:ff:ff:ff
root@dpu-cplane-tenant1-doca-hbn-8d5f9-ds-pgv7p:/tmp# ip link show red
Device "red" does not exist.
root@dpu-cplane-tenant1-doca-hbn-8d5f9-ds-pgv7p:/tmp# ip -d link show RED
11: RED: <NOARP,MASTER,UP,LOWER_UP> mtu 65575 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether 96:15:10:96:87:f6 brd ff:ff:ff:ff:ff:ff promiscuity 0 minmtu 1280 maxmtu 65575 
    vrf table 1003 addrgenmode eui64 numtxqueues 1 numrxqueues 1 gso_max_size 65536 gso_max_segs 65535 
root@dpu-cplane-tenant1-doca-hbn-8d5f9-ds-pgv7p:/tmp# 
root@dpu-cplane-tenant1-doca-hbn-8d5f9-ds-pgv7p:/tmp# ip -br link show type vrf
mgmt             UP             0e:1a:3d:e8:bc:a5 <NOARP,MASTER,UP,LOWER_UP> 
BLUE             UP             fa:1d:c0:7d:5e:59 <NOARP,MASTER,UP,LOWER_UP> 
RED              UP             96:15:10:96:87:f6 <NOARP,MASTER,UP,LOWER_UP> 
root@dpu-cplane-tenant1-doca-hbn-8d5f9-ds-pgv7p:/tmp# ip link show dev pf0hpf_if  
74: pf0hpf_if: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9000 qdisc mq master RED state UP mode DEFAULT group default qlen 1000
    link/ether 0e:d6:7e:dc:e8:b7 brd ff:ff:ff:ff:ff:fff

root@dpu-cplane-tenant1-doca-hbn-8d5f9-ds-pgv7p:/tmp# ip link show master RED
12: vlan4063_l3@br_default: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9216 qdisc noqueue master RED state UP mode DEFAULT group default qlen 1000
    link/ether 4e:f2:27:be:4c:6c brd ff:ff:ff:ff:ff:ff
74: pf0hpf_if: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9000 qdisc mq master RED state UP mode DEFAULT group default qlen 1000
    link/ether 0e:d6:7e:dc:e8:b7 brd ff:ff:ff:ff:ff:ff
root@dpu-cplane-tenant1-doca-hbn-8d5f9-ds-pgv7p:/tmp# ip link show master BLUE
10: vlan4006_l3@br_default: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9216 qdisc noqueue master BLUE state UP mode DEFAULT group default qlen 1000
    link/ether 4e:f2:27:be:4c:6c brd ff:ff:ff:ff:ff:ff
77: pf1hpf_if: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9000 qdisc mq master BLUE state UP mode DEFAULT group default qlen 1000
    link/ether da:64:8b:3a:2d:f2 brd ff:ff:ff:ff:ff:ff

root@dpu-cplane-tenant1-doca-hbn-8d5f9-ds-pgv7p:/tmp# ip route show table 1003
unreachable default metric 4278198272 
10.0.121.0/29 nhid 44 proto bgp metric 20 
10.0.121.8/29 dev pf0hpf_if proto kernel scope link src 10.0.121.10 
local 10.0.121.10 dev pf0hpf_if proto kernel scope host src 10.0.121.10 
broadcast 10.0.121.15 dev pf0hpf_if proto kernel scope link src 10.0.121.10 
127.0.0.0/8 dev RED proto kernel scope link src 127.0.0.1 
local 127.0.0.1 dev RED proto kernel scope host src 127.0.0.1 
local 127.0.1.1 dev RED proto kernel scope host src 127.0.0.1 
broadcast 127.255.255.255 dev RED proto kernel scope link src 127.0.0.1 
root@dpu-cplane-tenant1-doca-hbn-8d5f9-ds-pgv7p:/tmp# 

root@dpu-cplane-tenant1-doca-hbn-8d5f9-ds-pgv7p:/tmp# ip route show table 1002
unreachable default metric 4278198272 
10.0.122.0/29 nhid 43 proto bgp metric 20 
10.0.122.8/29 dev pf1hpf_if proto kernel scope link src 10.0.122.10 
local 10.0.122.10 dev pf1hpf_if proto kernel scope host src 10.0.122.10 
broadcast 10.0.122.15 dev pf1hpf_if proto kernel scope link src 10.0.122.10 
127.0.0.0/8 dev BLUE proto kernel scope link src 127.0.0.1 
local 127.0.0.1 dev BLUE proto kernel scope host src 127.0.0.1 
local 127.0.1.1 dev BLUE proto kernel scope host src 127.0.0.1 
broadcast 127.255.255.255 dev BLUE proto kernel scope link src 127.0.0.1
```

ovs bridges on DPU:

```
root@dpu-node-mt2428xz0n1d-mt2428xz0n1d:/home/ubuntu# ovs-vsctl show
2bc41997-03b1-4926-bfa8-69e50f7eb4b3
    Bridge br-hbn
        fail_mode: secure
        datapath_type: netdev
        Port pen3f0pf0sf5brhbn
            Interface pen3f0pf0sf5brhbn
                type: patch
                options: {peer=pen3f0pf0sf5brsfc}
        Port en3f0pf0sf19
            Interface en3f0pf0sf19
                type: dpdk
        Port en3f0pf0sf9
            Interface en3f0pf0sf9
                type: dpdk
        Port vxlan0
            Interface vxlan0
                type: vxlan
                options: {explicit="true", remote_ip=flow, tos=inherit}
        Port pen3f0pf0sf9brhbn
            Interface pen3f0pf0sf9brhbn
                type: patch
                options: {peer=pen3f0pf0sf9brsfc}
        Port pen3f0pf0sf10brhbn
            Interface pen3f0pf0sf10brhbn
                type: patch
                options: {peer=pen3f0pf0sf10brsfc}
        Port pen3f0pf0sf19brhbn
            Interface pen3f0pf0sf19brhbn
                type: patch
                options: {peer=pen3f0pf0sf19brsfc}
        Port en3f0pf0sf10
            Interface en3f0pf0sf10
                type: dpdk
        Port en3f0pf0sf5
            Interface en3f0pf0sf5
                type: dpdk
    Bridge br-sfc
        fail_mode: secure
        datapath_type: netdev
        Port pf1hpf
            Interface pf1hpf
                type: dpdk
        Port br-sfc
            Interface br-sfc
                type: internal
        Port pen3f0pf0sf10brsfc
            Interface pen3f0pf0sf10brsfc
                type: patch
                options: {peer=pen3f0pf0sf10brhbn}
        Port p1
            Interface p1
                type: dpdk
        Port pen3f0pf0sf5brsfc
            Interface pen3f0pf0sf5brsfc
                type: patch
                options: {peer=pen3f0pf0sf5brhbn}
        Port p0
            Interface p0
                type: dpdk
        Port pf0hpf
            Interface pf0hpf
                type: dpdk
        Port pen3f0pf0sf19brsfc
            Interface pen3f0pf0sf19brsfc
                type: patch
                options: {peer=pen3f0pf0sf19brhbn}
        Port pen3f0pf0sf9brsfc
            Interface pen3f0pf0sf9brsfc
                type: patch
                options: {peer=pen3f0pf0sf9brhbn}
    ovs_version: "3.1.0057"
```


```
scripts/get-evpn-route.sh

Namespace : dpf-operator-system
Pod prefix: dpu-cplane-tenant1-doca-hbn
Container : 
vtysh cmd : show bgp l2vpn evpn

============================================================
Pod: dpu-cplane-tenant1-doca-hbn-bksgp-ds-l9dmx
------------------------------------------------------------
BGP table version is 1, local router ID is 11.0.0.1
Status codes: s suppressed, d damped, h history, * valid, > best, i - internal
Origin codes: i - IGP, e - EGP, ? - incomplete
EVPN type-1 prefix: [1]:[EthTag]:[ESI]:[IPlen]:[VTEP-IP]:[Frag-id]
EVPN type-2 prefix: [2]:[EthTag]:[MAClen]:[MAC]:[IPlen]:[IP]
EVPN type-3 prefix: [3]:[EthTag]:[IPlen]:[OrigIP]
EVPN type-4 prefix: [4]:[ESI]:[IPlen]:[OrigIP]
EVPN type-5 prefix: [5]:[EthTag]:[IPlen]:[IP]

   Network          Next Hop            Metric LocPrf Weight Path
Route Distinguisher: 10.0.121.2:3
*> [5]:[0]:[29]:[10.0.121.0]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-lr4pv)
                                             0             0 65101 ?
                    RT:65101:100001 ET:8 Rmac:ae:3f:c1:0f:8b:20
*                   11.0.0.0 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-lr4pv)
                                             0             0 65101 ?
                    RT:65101:100001 ET:8 Rmac:ae:3f:c1:0f:8b:20
Route Distinguisher: 10.0.121.10:3
*> [5]:[0]:[29]:[10.0.121.8]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-l9dmx)
                                             0         32768 ?
                    ET:8 RT:65201:100001 Rmac:ee:9c:f3:bc:0e:73
Route Distinguisher: 11.0.0.0:4
*> [2]:[0]:[48]:[5c:25:73:e6:38:45]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-lr4pv)
                                                           0 65101 i
                    RT:65101:10 ET:8
*                   11.0.0.0 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-lr4pv)
                                                           0 65101 i
                    RT:65101:10 ET:8
*> [2]:[0]:[48]:[5c:25:73:e6:38:45]:[32]:[192.168.100.1]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-lr4pv)
                                                           0 65101 i
                    RT:65101:10 ET:8
*                   11.0.0.0 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-lr4pv)
                                                           0 65101 i
                    RT:65101:10 ET:8
*> [2]:[0]:[48]:[5c:25:73:e6:38:45]:[128]:[fe80::5e25:73ff:fee6:3845]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-lr4pv)
                                                           0 65101 i
                    RT:65101:10 ET:8
*                   11.0.0.0 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-lr4pv)
                                                           0 65101 i
                    RT:65101:10 ET:8
*> [2]:[0]:[48]:[c2:76:ee:0b:2a:ba]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-lr4pv)
                                                           0 65101 i
                    RT:65101:10 ET:8
*                   11.0.0.0 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-lr4pv)
                                                           0 65101 i
                    RT:65101:10 ET:8
*> [2]:[0]:[48]:[c2:76:ee:0b:2a:ba]:[128]:[fe80::c076:eeff:fe0b:2aba]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-lr4pv)
                                                           0 65101 i
                    RT:65101:10 ET:8
*                   11.0.0.0 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-lr4pv)
                                                           0 65101 i
                    RT:65101:10 ET:8
*> [3]:[0]:[32]:[11.0.0.0]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-lr4pv)
                                                           0 65101 i
                    RT:65101:10 ET:8
*                   11.0.0.0 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-lr4pv)
                                                           0 65101 i
                    RT:65101:10 ET:8
Route Distinguisher: 11.0.0.1:4
*> [2]:[0]:[48]:[36:55:fe:5a:e4:84]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-l9dmx)
                                                       32768 i
                    ET:8 RT:65201:10
*> [2]:[0]:[48]:[36:55:fe:5a:e4:84]:[128]:[fe80::3455:feff:fe5a:e484]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-l9dmx)
                                                       32768 i
                    ET:8 RT:65201:10
*> [2]:[0]:[48]:[5c:25:73:e7:90:5f]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-l9dmx)
                                                       32768 i
                    ET:8 RT:65201:10
*> [2]:[0]:[48]:[5c:25:73:e7:90:5f]:[32]:[192.168.100.9]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-l9dmx)
                                                       32768 i
                    ET:8 RT:65201:10
*> [2]:[0]:[48]:[5c:25:73:e7:90:5f]:[128]:[fe80::5e25:73ff:fee7:905f]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-l9dmx)
                                                       32768 i
                    ET:8 RT:65201:10
*> [3]:[0]:[32]:[11.0.0.1]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-l9dmx)
                                                       32768 i
                    ET:8 RT:65201:10

Displayed 14 out of 21 total prefixes

============================================================
Pod: dpu-cplane-tenant1-doca-hbn-bksgp-ds-lr4pv
------------------------------------------------------------
BGP table version is 1, local router ID is 11.0.0.0
Status codes: s suppressed, d damped, h history, * valid, > best, i - internal
Origin codes: i - IGP, e - EGP, ? - incomplete
EVPN type-1 prefix: [1]:[EthTag]:[ESI]:[IPlen]:[VTEP-IP]:[Frag-id]
EVPN type-2 prefix: [2]:[EthTag]:[MAClen]:[MAC]:[IPlen]:[IP]
EVPN type-3 prefix: [3]:[EthTag]:[IPlen]:[OrigIP]
EVPN type-4 prefix: [4]:[ESI]:[IPlen]:[OrigIP]
EVPN type-5 prefix: [5]:[EthTag]:[IPlen]:[IP]

   Network          Next Hop            Metric LocPrf Weight Path
Route Distinguisher: 10.0.121.2:3
*> [5]:[0]:[29]:[10.0.121.0]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-lr4pv)
                                             0         32768 ?
                    ET:8 RT:65101:100001 Rmac:ae:3f:c1:0f:8b:20
Route Distinguisher: 10.0.121.10:3
*> [5]:[0]:[29]:[10.0.121.8]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-l9dmx)
                                             0             0 65201 ?
                    RT:65201:100001 ET:8 Rmac:ee:9c:f3:bc:0e:73
*                   11.0.0.1 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-l9dmx)
                                             0             0 65201 ?
                    RT:65201:100001 ET:8 Rmac:ee:9c:f3:bc:0e:73
Route Distinguisher: 11.0.0.0:4
*> [2]:[0]:[48]:[5c:25:73:e6:38:45]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-lr4pv)
                                                       32768 i
                    ET:8 RT:65101:10
*> [2]:[0]:[48]:[5c:25:73:e6:38:45]:[32]:[192.168.100.1]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-lr4pv)
                                                       32768 i
                    ET:8 RT:65101:10
*> [2]:[0]:[48]:[5c:25:73:e6:38:45]:[128]:[fe80::5e25:73ff:fee6:3845]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-lr4pv)
                                                       32768 i
                    ET:8 RT:65101:10
*> [2]:[0]:[48]:[c2:76:ee:0b:2a:ba]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-lr4pv)
                                                       32768 i
                    ET:8 RT:65101:10
*> [2]:[0]:[48]:[c2:76:ee:0b:2a:ba]:[128]:[fe80::c076:eeff:fe0b:2aba]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-lr4pv)
                                                       32768 i
                    ET:8 RT:65101:10
*> [3]:[0]:[32]:[11.0.0.0]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-lr4pv)
                                                       32768 i
                    ET:8 RT:65101:10
Route Distinguisher: 11.0.0.1:4
*> [2]:[0]:[48]:[36:55:fe:5a:e4:84]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-l9dmx)
                                                           0 65201 i
                    RT:65201:10 ET:8
*                   11.0.0.1 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-l9dmx)
                                                           0 65201 i
                    RT:65201:10 ET:8
*> [2]:[0]:[48]:[36:55:fe:5a:e4:84]:[128]:[fe80::3455:feff:fe5a:e484]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-l9dmx)
                                                           0 65201 i
                    RT:65201:10 ET:8
*                   11.0.0.1 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-l9dmx)
                                                           0 65201 i
                    RT:65201:10 ET:8
*> [2]:[0]:[48]:[5c:25:73:e7:90:5f]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-l9dmx)
                                                           0 65201 i
                    RT:65201:10 ET:8
*                   11.0.0.1 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-l9dmx)
                                                           0 65201 i
                    RT:65201:10 ET:8
*> [2]:[0]:[48]:[5c:25:73:e7:90:5f]:[32]:[192.168.100.9]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-l9dmx)
                                                           0 65201 i
                    RT:65201:10 ET:8
*                   11.0.0.1 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-l9dmx)
                                                           0 65201 i
                    RT:65201:10 ET:8
*> [2]:[0]:[48]:[5c:25:73:e7:90:5f]:[128]:[fe80::5e25:73ff:fee7:905f]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-l9dmx)
                                                           0 65201 i
                    RT:65201:10 ET:8
*                   11.0.0.1 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-l9dmx)
                                                           0 65201 i
                    RT:65201:10 ET:8
*> [3]:[0]:[32]:[11.0.0.1]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-l9dmx)
                                                           0 65201 i
                    RT:65201:10 ET:8
*                   11.0.0.1 (dpu-cplane-tenant1-doca-hbn-bksgp-ds-l9dmx)
                                                           0 65201 i
                    RT:65201:10 ET:8

Displayed 14 out of 21 total prefixes
```
