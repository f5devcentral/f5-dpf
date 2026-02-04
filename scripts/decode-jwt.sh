#!/usr/bin/env bash
set -euo pipefail

# Example
#
# $  ./scripts/decode-jwt.sh ~/.jwt                                                                            
# {
#   "alg": "RS512",
#   "typ": "JWT",
#   "kid": "v1",
#   "jku": "https://product-tst.apis.f5networks.net/ee/v1/keys/jwks"
# }

JWT=~/.jwt
if [[ ! -f "$JWT" ]]; then
  echo "Error: File '$JWT' does not exist. Check path in ${REPO_ROOT}/.env" >&2
  exit 1
fi

f1=$(cut -d\. -f1 $JWT)
echo $f1 | base64 -d | jq
echo ""
