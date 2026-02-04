## Deploy HBN alpine service 

DPUServiceConfiguration alpine-sfc is attached to HBN pod via two interfaces, internal_sf and
external_sf. 


```
     leaf1            leaf2              leaf1            leaf2
       |                |                  |                |
+------+----------------+-------+   +------+----------------+-------+
|      p0   DPU1 HBN    p1      |   |      p0   DPU2 HBN    p1      |
|        merged eSwitch         |   |        merged eSwitch         |
|                               |   |                               |
|    +--------------------+     |   |    +--------------------+     |
|    |        TMM         |     |   |    |        TMM         |     |
|    +--+--------------+--+     |   |    +--+--------------+--+     |
|       |              |        |   |       |              |        |
|   external       internal     |   |   external       internal     |
|   external_if    internal_if  |   |   external_if    internal_if  |
|       |              |        |   |       |              |        |
| +-----+------+ +-----+------+ |   | +-----+------+ +-----+------+ |
| |  vrf1 RED  | | br_default | |   | |  vrf1 RED  | | br_default | |
| |  EVPN T5   | | EVPN T2    | |   | |  EVPN T5   | | EVPN T2    | |
| | vni 100001 | |  vni 10    | |   | | vni 100001 | |  vni 10    | |
| |            | |  avlan 10  | |   | |            | |  avlan 10  | |
| +-----+------+ +-----+------+ |   | +-----+------+ +-----+------+ |
|       |              |        |   |       |              |        |
|     pf0hpf         pf1hpf     |   |     pf0hpf         pf1hpf     |
+-------|--------------|--------+   +-------|--------------|--------+
        |              |                    |              |         
+-------+--------------+--------+   +-------+--------------+--------+
|   enp7s0np0      enp8s0np0    |   |   enp7s0np0      enp8s0np0    |
| 10.0.121.9/29 192.168.100.9/24|   | 10.0.121.1/29 192.168.100.1/24|
|            worker1            |   |            worker2            |
+-------------------------------+   +-------------------------------+

```
The required alpine helm chart is created from this repo's folder ../../alpine-sfc-chart/.  
DPF adds label `svc.dpu.nvidia.com/service=dpudeployment_hbn_alpine-sfc` to the helm deployment,
which must be passed to the pod via helm template. Trusted SF must be requested as part of
the DPUServiceConfiguration, which also needs to be passed onto the pod via helm template.

To check proper label and resource allocation, use:

```
mwiget@nuc1:~/f5-dpf/alpine-sfc-chart/templates$ d describe pod dpu-cplane-tenant1-alpine-sfc-6dffg-gsqhz | sed -n '/Limits:/,/Environment:/p'
    Limits:
      cpu:                       500m
      hugepages-2Mi:             512Mi
      memory:                    256Mi
      nvidia.com/bf_sf_trusted:  2
    Requests:
      cpu:                       50m
      hugepages-2Mi:             512Mi
      memory:                    64Mi
      nvidia.com/bf_sf_trusted:  2
    Environment:                 <none>
```

```
$ d describe pod dpu-cplane-tenant1-alpine-sfc-6dffg-gsqhz | sed -n '/Labels:/,/Status:/p'
Labels:           app.kubernetes.io/instance=dpu-cplane-tenant1-alpine-sfc-6dffg
                  app.kubernetes.io/name=alpine-sfc
                  controller-revision-hash=7cf5676785
                  pod-template-generation=1
                  svc.dpu.nvidia.com/service=dpudeployment_hbn_alpine-sfc
Annotations:      k8s.v1.cni.cncf.io/network-status:
                    [{
                        "name": "default-cni-network",
                        "interface": "eth0",
                        "ips": [
                            "10.244.1.87"
                        ],
                        "mac": "ee:6f:72:55:d8:00",
                        "default": true,
                        "dns": {}
                    },{
                        "name": "dpf-operator-system/mybrsfc-hbn-trusted",
                        "interface": "external",
                        "mac": "aa:2a:72:b8:9e:6c",
                        "dns": {}
                    },{
                        "name": "dpf-operator-system/mybrsfc-hbn-trusted",
                        "interface": "internal",
                        "mac": "22:d2:68:49:09:91",
                        "dns": {}
                    }]
                  k8s.v1.cni.cncf.io/networks:
                    [{"name":"mybrsfc-hbn-trusted","namespace":"dpf-operator-system","interface":"external","cni-args":{"mtu":1500}},{"name":"mybrsfc-hbn-trus...
                  k8s.v1.cni.cncf.io/networks-status:
                    [{
                        "name": "default-cni-network",
                        "interface": "eth0",
                        "ips": [
                            "10.244.1.87"
                        ],
                        "mac": "ee:6f:72:55:d8:00",
                        "default": true,
                        "dns": {}
                    },{
                        "name": "dpf-operator-system/mybrsfc-hbn-trusted",
                        "interface": "external",
                        "mac": "aa:2a:72:b8:9e:6c",
                        "dns": {}
                    },{
                        "name": "dpf-operator-system/mybrsfc-hbn-trusted",
                        "interface": "internal",
                        "mac": "22:d2:68:49:09:91",
                        "dns": {}
                    }]
Status:           Running
```


To test connectivity via internal network (connected to vlan10 evpn/vxlan type 2), assign IP address
to the alpine-sfc pod in subnet 192.168.100.0/24 network and check reachability to worker1 and worker2:

```
mwiget@nuc1:~/f5-dpf/resources$ d exec -ti dpu-cplane-tenant1-alpine-sfc-6dffg-gsqhz -- ash
/ # ip -br a
lo               UNKNOWN        127.0.0.1/8 ::1/128
eth0@if173       UP             10.244.1.87/24 fe80::ec6f:72ff:fe55:d800/64
external         UP             fe80::a82a:72ff:feb8:9e6c/64
internal         UP             192.168.100.20/24 fe80::20d2:68ff:fe49:991/64
/ #
/ # ping 192.168.100.1 -c3
PING 192.168.100.1 (192.168.100.1): 56 data bytes
64 bytes from 192.168.100.1: seq=0 ttl=64 time=0.518 ms
64 bytes from 192.168.100.1: seq=1 ttl=64 time=0.366 ms
64 bytes from 192.168.100.1: seq=2 ttl=64 time=0.340 ms

--- 192.168.100.1 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.340/0.408/0.518 ms
/ # ping 192.168.100.9 -c3
PING 192.168.100.9 (192.168.100.9): 56 data bytes
64 bytes from 192.168.100.9: seq=0 ttl=64 time=0.972 ms
64 bytes from 192.168.100.9: seq=1 ttl=64 time=0.661 ms
64 bytes from 192.168.100.9: seq=2 ttl=64 time=0.371 ms

--- 192.168.100.9 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.371/0.668/0.972 ms
/ #
```


```

mwiget@worker1:~$ ip -br a
lo               UNKNOWN        127.0.0.1/8 ::1/128
enp1s0           UP             192.168.68.76/22 metric 100 fe80::5054:ff:fe77:f04f/64
enp7s0np0        UP             10.0.121.9/29 fe80::5e25:73ff:fee7:905e/64
enp8s0np0        UP             192.168.100.9/24 fe80::5e25:73ff:fee7:905f/64
```

```
mwiget@worker2:~$ ip -br a
lo               UNKNOWN        127.0.0.1/8 ::1/128
enp1s0           UP             192.168.68.101/22 metric 100 2a02:168:5e2b::100b/128 fe80::5054:ff:fe19:a916/64
enp7s0np0        UP             10.0.121.1/29 fe80::5e25:73ff:fee6:3844/64
enp8s0np0        UP             192.168.100.1/24 fe80::5e25:73ff:fee6:3845/64
```

```
mwiget@nuc1:~/f5-dpf$ scripts/get-evpn-route.sh |grep 192.168.100
Defaulted container "doca-hbn" out of: doca-hbn, hbn-sidecar, hbn-init (init)
*> [2]:[0]:[48]:[22:d2:68:49:09:91]:[32]:[192.168.100.20]
*> [2]:[0]:[48]:[5c:25:73:e6:38:45]:[32]:[192.168.100.1]
*> [2]:[0]:[48]:[5c:25:73:e7:90:5f]:[32]:[192.168.100.9]
Defaulted container "doca-hbn" out of: doca-hbn, hbn-sidecar, hbn-init (init)
*> [2]:[0]:[48]:[22:d2:68:49:09:91]:[32]:[192.168.100.20]
*> [2]:[0]:[48]:[5c:25:73:e6:38:45]:[32]:[192.168.100.1]
*> [2]:[0]:[48]:[5c:25:73:e7:90:5f]:[32]:[192.168.100.9]
```

```
$ scripts/get-evpn-route.sh

Namespace : dpf-operator-system
Pod prefix: dpu-cplane-tenant1-doca-hbn
Container : 
vtysh cmd : show bgp l2vpn evpn

============================================================
Pod: dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx
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
Route Distinguisher: 10.0.121.2:2
*> [5]:[0]:[29]:[10.0.121.0]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                             0             0 65101 ?
                    RT:65101:100001 ET:8 Rmac:3a:6f:70:4a:92:78
*                   11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                             0             0 65101 ?
                    RT:65101:100001 ET:8 Rmac:3a:6f:70:4a:92:78
Route Distinguisher: 10.0.121.10:2
*> [5]:[0]:[29]:[10.0.121.8]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                             0         32768 ?
                    ET:8 RT:65201:100001 Rmac:42:d2:c0:f0:f0:10
Route Distinguisher: 11.0.0.0:3
*> [2]:[0]:[48]:[06:a2:e4:ff:83:10]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                           0 65101 i
                    RT:65101:10 ET:8
*                   11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                           0 65101 i
                    RT:65101:10 ET:8
*> [2]:[0]:[48]:[06:a2:e4:ff:83:10]:[128]:[fe80::4a2:e4ff:feff:8310]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                           0 65101 i
                    RT:65101:10 ET:8
*                   11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                           0 65101 i
                    RT:65101:10 ET:8
*> [2]:[0]:[48]:[22:d2:68:49:09:91]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                           0 65101 i
                    RT:65101:10 ET:8
*                   11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                           0 65101 i
                    RT:65101:10 ET:8
*> [2]:[0]:[48]:[22:d2:68:49:09:91]:[32]:[192.168.100.20]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                           0 65101 i
                    RT:65101:10 ET:8
*                   11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                           0 65101 i
                    RT:65101:10 ET:8
*> [2]:[0]:[48]:[22:d2:68:49:09:91]:[128]:[fe80::20d2:68ff:fe49:991]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                           0 65101 i
                    RT:65101:10 ET:8
*                   11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                           0 65101 i
                    RT:65101:10 ET:8
*> [2]:[0]:[48]:[4a:d2:c5:93:df:f6]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                           0 65101 i
                    RT:65101:10 ET:8
*                   11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                           0 65101 i
                    RT:65101:10 ET:8
*> [2]:[0]:[48]:[4a:d2:c5:93:df:f6]:[128]:[fe80::48d2:c5ff:fe93:dff6]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                           0 65101 i
                    RT:65101:10 ET:8
*                   11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                           0 65101 i
                    RT:65101:10 ET:8
*> [2]:[0]:[48]:[5c:25:73:e6:38:45]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                           0 65101 i
                    RT:65101:10 ET:8
*                   11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                           0 65101 i
                    RT:65101:10 ET:8
*> [2]:[0]:[48]:[5c:25:73:e6:38:45]:[32]:[192.168.100.1]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                           0 65101 i
                    RT:65101:10 ET:8
*                   11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                           0 65101 i
                    RT:65101:10 ET:8
*> [2]:[0]:[48]:[5c:25:73:e6:38:45]:[128]:[fe80::5e25:73ff:fee6:3845]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                           0 65101 i
                    RT:65101:10 ET:8
*                   11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                           0 65101 i
                    RT:65101:10 ET:8
*> [3]:[0]:[32]:[11.0.0.0]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                           0 65101 i
                    RT:65101:10 ET:8
*                   11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                           0 65101 i
                    RT:65101:10 ET:8
Route Distinguisher: 11.0.0.1:3
*> [2]:[0]:[48]:[22:47:04:66:49:59]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                                       32768 i
                    ET:8 RT:65201:10
*> [2]:[0]:[48]:[22:47:04:66:49:59]:[128]:[fe80::2047:4ff:fe66:4959]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                                       32768 i
                    ET:8 RT:65201:10
*> [2]:[0]:[48]:[5c:25:73:e7:90:5f]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                                       32768 i
                    ET:8 RT:65201:10
*> [2]:[0]:[48]:[5c:25:73:e7:90:5f]:[32]:[192.168.100.9]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                                       32768 i
                    ET:8 RT:65201:10
*> [2]:[0]:[48]:[5c:25:73:e7:90:5f]:[128]:[fe80::5e25:73ff:fee7:905f]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                                       32768 i
                    ET:8 RT:65201:10
*> [2]:[0]:[48]:[86:bd:c9:bd:0d:a0]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                                       32768 i
                    ET:8 RT:65201:10
*> [2]:[0]:[48]:[86:bd:c9:bd:0d:a0]:[128]:[fe80::84bd:c9ff:febd:da0]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                                       32768 i
                    ET:8 RT:65201:10
*> [2]:[0]:[48]:[de:8c:db:5f:e3:ee]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                                       32768 i
                    ET:8 RT:65201:10
*> [2]:[0]:[48]:[de:8c:db:5f:e3:ee]:[128]:[fe80::dc8c:dbff:fe5f:e3ee]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                                       32768 i
                    ET:8 RT:65201:10
*> [3]:[0]:[32]:[11.0.0.1]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                                       32768 i
                    ET:8 RT:65201:10

Displayed 23 out of 35 total prefixes

============================================================
Pod: dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c
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
Route Distinguisher: 10.0.121.2:2
*> [5]:[0]:[29]:[10.0.121.0]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                             0         32768 ?
                    ET:8 RT:65101:100001 Rmac:3a:6f:70:4a:92:78
Route Distinguisher: 10.0.121.10:2
*> [5]:[0]:[29]:[10.0.121.8]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                             0             0 65201 ?
                    RT:65201:100001 ET:8 Rmac:42:d2:c0:f0:f0:10
*                   11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                             0             0 65201 ?
                    RT:65201:100001 ET:8 Rmac:42:d2:c0:f0:f0:10
Route Distinguisher: 11.0.0.0:3
*> [2]:[0]:[48]:[06:a2:e4:ff:83:10]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                       32768 i
                    ET:8 RT:65101:10
*> [2]:[0]:[48]:[06:a2:e4:ff:83:10]:[128]:[fe80::4a2:e4ff:feff:8310]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                       32768 i
                    ET:8 RT:65101:10
*> [2]:[0]:[48]:[22:d2:68:49:09:91]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                       32768 i
                    ET:8 RT:65101:10
*> [2]:[0]:[48]:[22:d2:68:49:09:91]:[32]:[192.168.100.20]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                       32768 i
                    ET:8 RT:65101:10
*> [2]:[0]:[48]:[22:d2:68:49:09:91]:[128]:[fe80::20d2:68ff:fe49:991]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                       32768 i
                    ET:8 RT:65101:10
*> [2]:[0]:[48]:[4a:d2:c5:93:df:f6]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                       32768 i
                    ET:8 RT:65101:10
*> [2]:[0]:[48]:[4a:d2:c5:93:df:f6]:[128]:[fe80::48d2:c5ff:fe93:dff6]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                       32768 i
                    ET:8 RT:65101:10
*> [2]:[0]:[48]:[5c:25:73:e6:38:45]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                       32768 i
                    ET:8 RT:65101:10
*> [2]:[0]:[48]:[5c:25:73:e6:38:45]:[32]:[192.168.100.1]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                       32768 i
                    ET:8 RT:65101:10
*> [2]:[0]:[48]:[5c:25:73:e6:38:45]:[128]:[fe80::5e25:73ff:fee6:3845]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                       32768 i
                    ET:8 RT:65101:10
*> [3]:[0]:[32]:[11.0.0.0]
                    11.0.0.0 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c)
                                                       32768 i
                    ET:8 RT:65101:10
Route Distinguisher: 11.0.0.1:3
*> [2]:[0]:[48]:[22:47:04:66:49:59]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                                           0 65201 i
                    RT:65201:10 ET:8
*                   11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                                           0 65201 i
                    RT:65201:10 ET:8
*> [2]:[0]:[48]:[22:47:04:66:49:59]:[128]:[fe80::2047:4ff:fe66:4959]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                                           0 65201 i
                    RT:65201:10 ET:8
*                   11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                                           0 65201 i
                    RT:65201:10 ET:8
*> [2]:[0]:[48]:[5c:25:73:e7:90:5f]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                                           0 65201 i
                    RT:65201:10 ET:8
*                   11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                                           0 65201 i
                    RT:65201:10 ET:8
*> [2]:[0]:[48]:[5c:25:73:e7:90:5f]:[32]:[192.168.100.9]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                                           0 65201 i
                    RT:65201:10 ET:8
*                   11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                                           0 65201 i
                    RT:65201:10 ET:8
*> [2]:[0]:[48]:[5c:25:73:e7:90:5f]:[128]:[fe80::5e25:73ff:fee7:905f]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                                           0 65201 i
                    RT:65201:10 ET:8
*                   11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                                           0 65201 i
                    RT:65201:10 ET:8
*> [2]:[0]:[48]:[86:bd:c9:bd:0d:a0]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                                           0 65201 i
                    RT:65201:10 ET:8
*                   11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                                           0 65201 i
                    RT:65201:10 ET:8
*> [2]:[0]:[48]:[86:bd:c9:bd:0d:a0]:[128]:[fe80::84bd:c9ff:febd:da0]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                                           0 65201 i
                    RT:65201:10 ET:8
*                   11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                                           0 65201 i
                    RT:65201:10 ET:8
*> [2]:[0]:[48]:[de:8c:db:5f:e3:ee]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                                           0 65201 i
                    RT:65201:10 ET:8
*                   11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                                           0 65201 i
                    RT:65201:10 ET:8
*> [2]:[0]:[48]:[de:8c:db:5f:e3:ee]:[128]:[fe80::dc8c:dbff:fe5f:e3ee]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                                           0 65201 i
                    RT:65201:10 ET:8
*                   11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                                           0 65201 i
                    RT:65201:10 ET:8
*> [3]:[0]:[32]:[11.0.0.1]
                    11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                                           0 65201 i
                    RT:65201:10 ET:8
*                   11.0.0.1 (dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx)
                                                           0 65201 i
                    RT:65201:10 ET:8

Displayed 23 out of 34 total prefixes
```



```
mwiget@nuc1:~/f5-dpf$ d get pod -o wide
NAME                                                             READY   STATUS    RESTARTS   AGE    IP              NODE                                 NOMINATED NODE   READINESS GATES
dpu-cplane-tenant1-alpine-sfc-6dffg-gsqhz                        1/1     Running   0          164m   10.244.1.87     dpu-node-mt2428xz0n1d-mt2428xz0n1d   <none>           <none>
dpu-cplane-tenant1-alpine-sfc-6dffg-xh58h                        1/1     Running   0          164m   10.244.0.19     dpu-node-mt2428xz0r48-mt2428xz0r48   <none>           <none>
dpu-cplane-tenant1-doca-hbn-vpppk-ds-4mrlx                       2/2     Running   0          14h    10.244.0.13     dpu-node-mt2428xz0r48-mt2428xz0r48   <none>           <none>
dpu-cplane-tenant1-doca-hbn-vpppk-ds-v7b4c                       2/2     Running   0          14h    10.244.1.82     dpu-node-mt2428xz0n1d-mt2428xz0n1d   <none>           <none>
dpu-cplane-tenant1-nvidia-k8s-ipam-controller-6cb8f65fc5-c222k   1/1     Running   0          15h    10.244.0.3      dpu-node-mt2428xz0r48-mt2428xz0r48   <none>           <none>
dpu-cplane-tenant1-nvidia-k8s-ipam-node-ds-mlfpm                 1/1     Running   0          15h    10.244.1.2      dpu-node-mt2428xz0n1d-mt2428xz0n1d   <none>           <none>
dpu-cplane-tenant1-nvidia-k8s-ipam-node-ds-qlmrm                 1/1     Running   0          15h    10.244.0.5      dpu-node-mt2428xz0r48-mt2428xz0r48   <none>           <none>
dpu-cplane-tenant1-ovs-cni-arm64-h4nb9                           1/1     Running   0          15h    192.168.68.96   dpu-node-mt2428xz0r48-mt2428xz0r48   <none>           <none>
dpu-cplane-tenant1-ovs-cni-arm64-zsvwq                           1/1     Running   0          15h    192.168.68.79   dpu-node-mt2428xz0n1d-mt2428xz0n1d   <none>           <none>
dpu-cplane-tenant1-sfc-controller-node-ds-85v7z                  1/1     Running   0          15h    10.244.0.7      dpu-node-mt2428xz0r48-mt2428xz0r48   <none>           <none>
dpu-cplane-tenant1-sfc-controller-node-ds-lxcqg                  1/1     Running   0          15h    10.244.1.3      dpu-node-mt2428xz0n1d-mt2428xz0n1d   <none>           <none>
kube-flannel-ds-rjrf8                                            1/1     Running   0          15h    192.168.68.79   dpu-node-mt2428xz0n1d-mt2428xz0n1d   <none>           <none>
kube-flannel-ds-zs724              G                              1/1     Running   0          15h    192.168.68.96   dpu-node-mt2428xz0r48-mt2428xz0r48   <none>           <none>
kube-multus-ds-26km7                                             1/1     Running   0          15h    192.168.68.79   dpu-node-mt2428xz0n1d-mt2428xz0n1d   <none>           <none>
kube-multus-ds-ckgq5                                             1/1     Running   0          15h    192.168.68.96   dpu-node-mt2428xz0r48-mt2428xz0r48   <none>           <none>
kube-sriov-device-plugin-k4wvv                                   1/1     Running   0          15h    192.168.68.79   dpu-node-mt2428xz0n1d-mt2428xz0n1d   <none>           <none>
kube-sriov-device-plugin-r4rbx                                   1/1     Running   0          15h    192.168.68.96   dpu-node-mt2428xz0r48-mt2428xz0r48   <none>           <none>
```


```
mwiget@nuc1:~/f5-dpf$ scripts/check-services.sh
DPUServiceInterface:
NAME                         IFTYPE     IFNAME        READY   REASON    AGE
alpine-sfc-external-hhx2l    service    external      True    Success   164m
alpine-sfc-internal-mm5hm    service    internal      True    Success   164m
doca-hbn-external-if-h7hwq   service    external_if   True    Success   14h
doca-hbn-internal-if-qcp4x   service    internal_if   True    Success   14h
doca-hbn-p0-if-jzhqt         service    p0_if         True    Success   14h
doca-hbn-p1-if-28mjb         service    p1_if         True    Success   14h
doca-hbn-pf0hpf-if-plrvl     service    pf0hpf_if     True    Success   14h
doca-hbn-pf1hpf-if-47thl     service    pf1hpf_if     True    Success   14h
p0                           physical   p0            True    Success   15h
p1                           physical   p1            True    Success   15h
pf0hpf                       pf                       True    Success   15h
pf1hpf                       pf                       True    Success   15h

DPUService:
NAME                            READY   PHASE     AGE
alpine-sfc-6dffg                True    Success   164m
doca-hbn-vpppk                  True    Success   14h
flannel                         True    Success   15h
multus                          True    Success   15h
nvidia-k8s-ipam                 True    Success   15h
ovs-cni                         True    Success   15h
servicechainset-controller      True    Success   15h
servicechainset-rbac-and-crds   True    Success   15h
sfc-controller                  True    Success   15h
sriov-device-plugin             True    Success   15h

DPUServiceChain:
NAME        READY   REASON    AGE
hbn-5xrwj   True    Success   3h35m

DPUServiceTemplate:
NAME         AGE
alpine-sfc   15h
doca-hbn     15h

DPUServiceConfiguration:
NAME         AGE
alpine-sfc   15h
doca-hbn     15h
```


```
root@dpu-node-mt2428xz0n1d-mt2428xz0n1d:/home/ubuntu# ovs-vsctl show
2b9d4030-4f2a-42c3-933c-9d393a4546f1
    Bridge br-sfc
        fail_mode: secure
        datapath_type: netdev
        Port pf0hpf
            Interface pf0hpf
                type: dpdk
        Port pf1hpf
            Interface pf1hpf
                type: dpdk
        Port pen3f0pf0sf13brsfc
            Interface pen3f0pf0sf13brsfc
                type: patch
                options: {peer=pen3f0pf0sf13brhbn}
        Port pen3f0pf0sf5brsfc
            Interface pen3f0pf0sf5brsfc
                type: patch
                options: {peer=pen3f0pf0sf5brhbn}
        Port en3f0pf0sf102
            Interface en3f0pf0sf102
                type: dpdk
        Port pen3f0pf0sf10brsfc
            Interface pen3f0pf0sf10brsfc
                type: patch
                options: {peer=pen3f0pf0sf10brhbn}
        Port en3f0pf0sf101
            Interface en3f0pf0sf101
                type: dpdk
        Port p0
            Interface p0
                type: dpdk
        Port pen3f0pf0sf6brsfc
            Interface pen3f0pf0sf6brsfc
                type: patch
                options: {peer=pen3f0pf0sf6brhbn}
        Port pen3f0pf0sf8brsfc
            Interface pen3f0pf0sf8brsfc
                type: patch
                options: {peer=pen3f0pf0sf8brhbn}
        Port br-sfc
            Interface br-sfc
                type: internal
        Port pen3f0pf0sf3brsfc
            Interface pen3f0pf0sf3brsfc
                type: patch
                options: {peer=pen3f0pf0sf3brhbn}
        Port p1
            Interface p1
                type: dpdk
    Bridge br-hbn
        fail_mode: secure
        datapath_type: netdev
        Port en3f0pf0sf10
            Interface en3f0pf0sf10
                type: dpdk
        Port en3f0pf0sf5
            Interface en3f0pf0sf5
                type: dpdk
        Port pen3f0pf0sf5brhbn
            Interface pen3f0pf0sf5brhbn
                type: patch
                options: {peer=pen3f0pf0sf5brsfc}
        Port en3f0pf0sf3
            Interface en3f0pf0sf3
                type: dpdk
        Port en3f0pf0sf13
            Interface en3f0pf0sf13
                type: dpdk
        Port pen3f0pf0sf8brhbn
            Interface pen3f0pf0sf8brhbn
                type: patch
                options: {peer=pen3f0pf0sf8brsfc}
        Port vxlan0
            Interface vxlan0
                type: vxlan
                options: {explicit="true", remote_ip=flow, tos=inherit}
        Port pen3f0pf0sf3brhbn
            Interface pen3f0pf0sf3brhbn
                type: patch
                options: {peer=pen3f0pf0sf3brsfc}
        Port pen3f0pf0sf13brhbn
            Interface pen3f0pf0sf13brhbn
                type: patch
                options: {peer=pen3f0pf0sf13brsfc}
        Port pen3f0pf0sf10brhbn
            Interface pen3f0pf0sf10brhbn
                type: patch
                options: {peer=pen3f0pf0sf10brsfc}
        Port pen3f0pf0sf6brhbn
            Interface pen3f0pf0sf6brhbn
                type: patch
                options: {peer=pen3f0pf0sf6brsfc}
        Port en3f0pf0sf6
            Interface en3f0pf0sf6
                type: dpdk
        Port en3f0pf0sf8
            Interface en3f0pf0sf8
                type: dpdk
    ovs_version: "3.1.0057"
```
