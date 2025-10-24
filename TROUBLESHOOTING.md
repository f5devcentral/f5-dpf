
to get more details in the log of dpf-provisioning-controller-manager, use:

```
# See current args
kubectl -n dpf-operator-system get deploy dpf-provisioning-controller-manager \
  -o jsonpath='{.spec.template.spec.containers[?(@.name=="manager")].args}'; echo

# Add/override args (strategic merge; keeps everything else intact)
kubectl -n dpf-operator-system patch deploy dpf-provisioning-controller-manager \
  --type merge \
  -p '{
    "spec": {
      "template": {
        "spec": {
          "containers": [{
            "name": "manager",
            "args": [
              "--leader-elect",
              "--zap-devel=true",
              "--zap-encoder=console",
              "--zap-log-level=debug"
            ]
          }]
        }
      }
    }
  }'

# Watch the rollout and then tail logs
kubectl -n dpf-operator-system rollout status deploy/dpf-provisioning-controller-manager
kubectl -n dpf-operator-system logs deploy/dpf-provisioning-controller-manager -c manager -f
```

managed to capture this:

```

I1024 13:57:05.193060       1 crawler.go:163] "Processing IP" controller="dpudiscovery" controllerGroup="provisioning.dpu.nvidia.com" controllerKind="DPUDiscovery" DPUDiscovery="dpf-operator-system/dpu-discov
ery" namespace="dpf-operator-system" name="dpu-discovery" reconcileID="17538bb2-bc62-4bea-bc04-79b0f34cee76" ip="192.168.68.138"
E1024 13:57:06.027526       1 installing.go:72] "Failed to install BFB" err="get status: 404 Not Found" controller="dpu" controllerGroup="provisioning.dpu.nvidia.com" controllerKind="DPU" DPU="dpf-operator-sy
stem/dpu-node-mt2428xz0r48-mt2428xz0r48" namespace="dpf-operator-system" name="dpu-node-mt2428xz0r48-mt2428xz0r48" reconcileID="f7fb3a55-8859-430b-8080-10c80dc9d900" status="404 Not Found" body=<
        {
          "error": {
            "@Message.ExtendedInfo": [
              {
                "@odata.type": "#Message.v1_1_1.Message",
                "Message": "The requested resource of type Targets named '/dev/rshim0/boot' was not found.",
                "MessageArgs": [
                  "Targets",
                  "/dev/rshim0/boot"
                ],
                "MessageId": "Base.1.18.1.ResourceNotFound",
                "MessageSeverity": "Critical",
                "Resolution": "Provide a valid resource identifier and resubmit the request."
              }
            ],
            "code": "Base.1.18.1.ResourceNotFound",
            "message": "The requested resource of type Targets named '/dev/rshim0/boot' was not found."
          }
        }
 >
```

Resolution: stop and disable rshim.servic on the host. 

