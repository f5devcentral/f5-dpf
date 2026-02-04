#!/usr/bin/env bash
set -euo pipefail
SECONDS=0

# Resolve git repo root reliably
REPO_ROOT="$(git rev-parse --show-toplevel)"

# Source .env from repo root
source "${REPO_ROOT}/.env"

echo ""
echo "Helm Registry ${F5_ARTIFACTORY} Login using ${F5_PULL_SECRET} ..."
cat ${F5_PULL_SECRET} | helm registry login -u _json_key_base64 --password-stdin ${F5_ARTIFACTORY}
echo ""
helm pull ${F5_BNK_MANIFEST_URL} --version ${F5_BNK_MANIFEST_VERSION}
F5_BNK_MANIFEST="${F5_BNK_MANIFEST_URL##*/}-${F5_BNK_MANIFEST_VERSION}"
echo "Extracting ..."
tar zxvf ${F5_BNK_MANIFEST}.tgz
REPO=$(yq -r '.f5_docker_repo' "${F5_BNK_MANIFEST}/bigip-k8s-manifest-${F5_BNK_MANIFEST_VERSION}.yaml")

get_chart_version() {
  local name="$1"

  yq -r "
    .releases[].helm_charts[]
    | select(.name | test(\"${name}\$\"))
    | .version
  " "${F5_BNK_MANIFEST}/bigip-k8s-manifest-${F5_BNK_MANIFEST_VERSION}.yaml"
}

echo ""
echo "F5 Artifacts Registry (FAR) authentication token ..."

# Read the content of pull secret into the SERVICE_ACCOUNT_KEY variable
SERVICE_ACCOUNT_KEY=$(cat ${F5_PULL_SECRET})
# Create the SERVICE_ACCOUNT_K8S_SECRET variable by appending "_json_key_base64:" to the base64 encoded SERVICE_ACCOUNT_KEY
SERVICE_ACCOUNT_K8S_SECRET=$(echo "_json_key_base64:${SERVICE_ACCOUNT_KEY}" | base64 -w 0)

echo ""
echo "Create the secret.yaml file with the provided content ..."
cat << EOF > ${REPO_ROOT}/far-secret.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: far-secret
data:
  .dockerconfigjson: $(echo "{\"auths\": {\
\"${REPO}\":\
{\"auth\": \"$SERVICE_ACCOUNT_K8S_SECRET\"}}}" | base64 -w 0)
type: kubernetes.io/dockerconfigjson
EOF

echo ""
echo "Create far-secret in f5-utils and f5-operators namespaces ..."
kubectl create ns f5-utils || true
kubectl create ns f5-operators || true

kubectl -n default  apply -f ${REPO_ROOT}/far-secret.yaml
kubectl -n f5-utils apply -f ${REPO_ROOT}/far-secret.yaml
kubectl -n f5-operators apply -f ${REPO_ROOT}/far-secret.yaml

echo ""
echo "Install OTEL prerequired cert ..."
kubectl apply -f resources/otel-cert.yaml

echo ""
echo "Install Cluster Wide Controller (CWC) to manage license and debug API ..."
rm -rf ~/cwc || true

helm pull oci://${REPO}/utils/f5-cert-gen --version $(get_chart_version f5-cert-gen)  --untar --untardir ~/cwc
mv ~/cwc/f5-cert-gen ~/cwc/cert-gen
pushd ~/cwc && sh cert-gen/gen_cert.sh -s=api-server -a=f5-spk-cwc.f5-utils -n=1 && popd
kubectl apply -f ~/cwc/cwc-license-certs.yaml -n f5-utils

echo "Create directory for API client certs for easier reference ..."
pushd ~/cwc && \
  mkdir -p cwc_api && \
  cp api-server-secrets/ssl/client/certs/client_certificate.pem \
  api-server-secrets/ssl/ca/certs/ca_certificate.pem \
  api-server-secrets/ssl/client/secrets/client_key.pem \
  cwc_api
popd

echo "waiting for pods be ready in kube-system namespace ..."
sleep 2
until kubectl wait --for=condition=Ready pods --all -n kube-system; do
  echo "retrying in 5 secs ..."
  sleep 5
done

echo ""
echo "Install F5 Lifecycle Opertaor (FLO) ..."

export JWT=$(cat ~/.jwt)
if cut -d\. -f1 ~/.jwt | base64 -d | grep tst; then
  envsubst < resources/flo-value-tst.yaml >/tmp/flo-value.yaml
else
  envsubst < resources/flo-value.yaml >/tmp/flo-value.yaml
fi

helm upgrade --install flo oci://${REPO}/charts/f5-lifecycle-operator --version $(get_chart_version f5-lifecycle-operator) -f /tmp/flo-value.yaml --namespace f5-operators

echo ""
echo "Deployment completed in $SECONDS secs."
