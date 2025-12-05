#!/bin/bash

source .env

if [ $# -ne 1 ]; then
  echo "Usage: $0 <BMC_IP>"
  exit 1
fi

ip="$1"

# Replace with your actual BMC credentials
BMC_USER=root

echo "===== $ip /redfish/v1/CertificateService/CertificateLocations ====="
curl -k -u "$BMC_USER:$BMC_ROOT_PASSWORD" https://$ip/redfish/v1/CertificateService/CertificateLocations | jq .
