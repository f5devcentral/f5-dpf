#!/bin/bash
source .env
BMC_USER=root
BMC_IP=$1

curl -k -u $BMC_USER:$BMC_ROOT_PASSWORD https://$BMC_IP/redfish/v1/UpdateService/FirmwareInventory/BMC_Firmware
echo ""
#curl -sku $BMC_USER:$BMC_ROOT_PASSWORD -X GET  https://$BMC_IP/redfish/v1/Systems/Bluefield/Bios
