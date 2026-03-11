```
~/f5-dpf$ ./scripts/check-dpusets.sh 
NAME                                 NAMESPACE            STATUS       REASON    SINCE  MESSAGE                                                                    
DPFOperatorConfig/dpfoperatorconfig  dpf-operator-system  Ready: True  Success   86s                                                                                
├─DPUServiceChains                                                                                                                                                  
│ └─DPUServiceChain/passthrough      dpf-operator-system  Ready: True  Success   104s                                                                               
├─DPUServiceInterfaces                                                                                                                                              
│ └─4 DPUServiceInterfaces...        dpf-operator-system  Ready: True  Success   109s   See p0, p1, pf0hpf, pf1hpf                                                  
├─DPUServiceNADs                                                                                                                                                    
│ └─DPUServiceNAD/mybrsfc            dpf-operator-system  Ready: True  Success   74m                                                                                
└─DPUSets                                                                                                                                                           
  └─DPUSet/passthrough               dpf-operator-system  Ready: True  Success   105s                                                                               
    ├─BFB/bf-bundle                  dpf-operator-system  Ready: True  Ready     72m    File: bf-bundle-2.9.4-38_25.12_ubuntu-22.04_prod.bfb, DOCA: 3.2.1           
    ├─DPUNodes                                                                                                                                                      
    │ └─2 DPUNodes...                dpf-operator-system  Ready: True  Ready     105s   See dpu-node-mt2428xz0n1d, dpu-node-mt2428xz0r48                            
    └─DPUs                                                                                                                                                          
      └─2 DPUs...                    dpf-operator-system  Ready: True  DPUReady  105s   See dpu-node-mt2428xz0n1d-mt2428xz0n1d, dpu-node-mt2428xz0r48-mt2428xz0r48  

~/f5-dpf$ k get dpu -A
NAMESPACE             NAME                                 READY   PHASE   AGE
dpf-operator-system   dpu-node-mt2428xz0n1d-mt2428xz0n1d   True    Ready   67m
dpf-operator-system   dpu-node-mt2428xz0r48-mt2428xz0r48   True    Ready   67m
```

