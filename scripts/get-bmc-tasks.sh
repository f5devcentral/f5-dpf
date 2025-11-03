#!/bin/bash
source .env
BMC_USER=root
BMC_IP=$1

curl -sk -u $BMC_USER:$BMC_ROOT_PASSWORD https://$BMC_IP/redfish/v1/TaskService/Tasks/
echo ""
