#!/bin/bash
set -euo pipefail

source .env

if [ $# -ne 1 ]; then
  echo "Usage: $0 <BMC_IP>"
  exit 1
fi

IP="$1"
USER="root"

BASE_URI="/redfish/v1/Managers/Bluefield_BMC/Truststore/Certificates"

echo "Deleting truststore certificates on $IP (keeping slot 1) ==="

for SLOT in {2..11}; do
  URI="$BASE_URI/$SLOT"
  echo "Deleting certificate slot $SLOT: $URI"

  # Send DELETE request, capture HTTP status code
  STATUS=$(curl -k -u "$USER:$BMC_ROOT_PASSWORD" -s -o /dev/null -w "%{http_code}" -X DELETE "https://$IP$URI")

  if [ "$STATUS" = "200" ] || [ "$STATUS" = "204" ]; then
    echo "  Deleted slot $SLOT successfully (HTTP $STATUS)"
  elif [ "$STATUS" = "404" ]; then
    echo "  Slot $SLOT not present (HTTP 404), skipping"
  else
    echo "  Failed to delete slot $SLOT (HTTP $STATUS)"
    exit 1
  fi
done

echo "Done. Remaining slots ==="
curl -k -u "$USER:$BMC_ROOT_PASSWORD" "https://$IP/redfish/v1/CertificateService/CertificateLocations" | jq '.Links.Certificates'
