## HBN in DPF Zero Trust

Source: https://github.com/NVIDIA/doca-platform/tree/public-release-v25.7/docs/public/user-guides/zero-trust/use-cases/hbn

Each node gets 2 PF's:

- pf0hpf_if: connected to vrf RED (evpn type 5), IP subnet per node
- pf1hpf_if: connected to layer2 (evpn type 2), shared network across node

```
+----------------------------+                +----------------------------+
|          worker1           |                |          worker2           |
|                            |                |                            |
|    10.0.121.9/29 enp7s0np0 +-- EVPN/VXLAN --+ enp7s0np0 10.0.121.1/29    |
|                            |     Type-5     |                            |
|                            |                |                            |
| 192.168.100.9/24 enp8s0np0 +-- EVPN/VXLAN --+ enp7s0np0 192.168.100.1/24 |
|                            |     Type-2     |                            |
|                            |                |                            |
+----------------------------+                +----------------------------+
```

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
    enp8s0np0:
      dhcp4: no
      addresses:
        - 192.168.100.9/24
```

worker2 netplan:

```
root@worker2:/home/mwiget# cat /etc/netplan/10-static.yaml
# /etc/netplan/10-static-enp7s0np0.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp7s0np0:
      dhcp4: no
      addresses:
        - 10.0.121.1/29
      routes:
        - to: 10.0.121.0/24
          via: 10.0.121.2
          on-link: true
    enp8s0np0:
      dhcp4: no
      addresses:
        - 192.168.100.1/24
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

```
root@worker1:/home/mwiget# ping 192.168.100.1 -c3
PING 192.168.100.1 (192.168.100.1) 56(84) bytes of data.
64 bytes from 192.168.100.1: icmp_seq=1 ttl=64 time=0.224 ms
64 bytes from 192.168.100.1: icmp_seq=2 ttl=64 time=0.218 ms
64 bytes from 192.168.100.1: icmp_seq=3 ttl=64 time=0.222 ms

--- 192.168.100.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2054ms
rtt min/avg/max/mdev = 0.218/0.221/0.224/0.002 ms
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
