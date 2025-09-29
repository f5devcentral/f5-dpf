#!/bin/bash

# Starts an http service to host the bfb file and uses redfish to request BMC to pull it.

BMC_IP=$1
LOCAL_LISTEN_IP=$(ip r get $BMC_IP | awk '/src/ {print $5}')


# BFB full path
BFB_PATH=$2

PASSWD=$3

BFB_DIR=$(dirname $BFB_PATH)
BFB_FILE=$(basename $BFB_PATH)


# Start httpd server
busybox httpd -f -p 8080 -h $BFB_DIR &
HTTPD_PID=$!

# Enable rshim on BMC
curl -k -u root:"$PASSWD" -H "Content-Type: application/json" -XPATCH -d '{
     "BmcRShim": {
       "BmcRShimEnabled": true
     }
}' https://$BMC_IP/redfish/v1/Managers/Bluefield_BMC/Oem/Nvidia


curl -k -u root:"$PASSWD" \
   -H "Content-Type: application/json" \
   -X POST -d '{"TransferProtocol":"HTTP", "ImageURI":"http://$LOCAL_IP:8080/$BFB_FILE","Targets":["redfish/v1/UpdateService/FirmwareInventory/DPU_OS"]}' \
   https://$BMC_IP/redfish/v1/UpdateService/Actions/UpdateService.SimpleUpdate

while true; do
   STATE=$(curl -sk -u root:'F5site02@rocks!' \
       "https://$BMC_IP/redfish/v1/TaskService/Tasks/$TASK_ID" \
       | jq -r '.TaskState')

   echo "Task $TASK_ID state: $STATE"

   if [[ "$STATE" != "Running" ]]; then
       echo "Task finished with state: $STATE"
       break
   fi
   sleep 5
done

kill $HTTPD_PID
