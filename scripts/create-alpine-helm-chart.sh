#!/usr/bin/env bash
set -euo pipefail

CHART_DIR="alpine-sfc-chart"
REGISTRY="oci://ghcr.io/mwiget/helm"
CHART_NAME="alpine-sfc"

# Extract version from Chart.yaml
CHART_VERSION=$(
  awk -F': ' '/^version:/ { print $2; exit }' "${CHART_DIR}/Chart.yaml"
)

if [[ -z "${CHART_VERSION}" ]]; then
  echo "ERROR: Failed to extract version from ${CHART_DIR}/Chart.yaml"
  exit 1
fi

echo "Detected chart version: ${CHART_VERSION}"

# Package chart
helm package "${CHART_DIR}"

# Login to GHCR
echo "Logging in to GHCR using Helm (OCI)..."
cat ~/.gh_pat | helm registry login ghcr.io \
  --username mwiget \
  --password-stdin

# Push chart
CHART_TGZ="${CHART_NAME}-${CHART_VERSION}.tgz"

echo "Pushing ${CHART_TGZ} to ${REGISTRY}"
helm push "${CHART_TGZ}" "${REGISTRY}"

echo ""
echo "to pull created chart, use"
echo "helm pull ${REGISTRY}/${CHART_NAME} --version ${CHART_VERSION}"
