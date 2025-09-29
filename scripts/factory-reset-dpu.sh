#!/usr/bin/env bash

source .env
IP=$1

echo "requesting factory reset of DPU via BMC IP $1 ..."
curl -k -u root:"${BMC_ROOT_PASSWORD}" -H "Content-Type: application/json" -X POST https://$IP/redfish/v1/Managers/Bluefield_BMC/Actions/Manager.ResetToDefaults -d '{"ResetToDefaultsType": "ResetAll"}' 
echo ""
