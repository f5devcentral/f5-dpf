#!/bin/bash
source .env
BMC_USER=root
BMC_IP=$1

curl -k -u $BMC_USER:$BMC_ROOT_PASSWORD -H "Content-Type: application/json" -X POST https://$BMC_IP/redfish/v1/Managers/Bluefield_BMC/Actions/Manager.ResetToDefaults -d '{"ResetToDefaultsType": "ResetAll"}'
echo ""
