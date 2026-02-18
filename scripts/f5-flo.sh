#!/usr/bin/env bash
set -euo pipefail

ts() { date '+%Y-%m-%d %H:%M:%S'; }
log() { printf '%s [%s] %s\n' "$(ts)" "$1" "$2" >&2; }
info(){ log INFO "$1"; }
warn(){ log WARN "$1"; }
err(){ log ERROR "$1"; }

source .env
#export BFB_URL

# configurable timing
: "${KWAIT_TIMEOUT:=600}"   # seconds to wait for resources/conditions
: "${KWAIT_INTERVAL:=5}"    # seconds between polls

echo ""
echo "Helm Registry repo.f5.com Login using ${HELM_REPOSITORY_USERNAME} ..."
echo ${HELM_REPOSITORY_KEY}| helm registry login -u _json_key_base64 --password-stdin --password-stdin repo.f5.com

echo ""
helm pull oci://repo.f5.com/release/f5-bigip-k8s-manifest --version ${F5_BNK_MANIFEST_VERSION}
F5_BNK_MANIFEST="f5-bigip-k8s-manifest-${F5_BNK_MANIFEST_VERSION}"
echo "Extracting ${F5_BNK_MANIFEST} ..."
tar zxvf ${F5_BNK_MANIFEST}.tgz && rm ${F5_BNK_MANIFEST}.tgz
REPO=$(yq -r '.f5_docker_repo' "${F5_BNK_MANIFEST}/bigip-k8s-manifest-${F5_BNK_MANIFEST_VERSION}.yaml")

get_chart_version() {
  local name="$1"

  yq -r "
    .releases[].helm_charts[]
    | select(.name | test(\"${name}\$\"))
    | .version
  " "${F5_BNK_MANIFEST}/bigip-k8s-manifest-${F5_BNK_MANIFEST_VERSION}.yaml"
}

build() {
  info "Install cert-manager and cluster issuer to manage pod-to-pod certs ..."

  helm repo add jetstack https://charts.jetstack.io --force-update
  helm upgrade --install -n cert-manager cert-manager jetstack/cert-manager --create-namespace --version v1.16.1 --set crds.enabled=true --wait
  kubectl wait --for=condition=Ready pods --all -n cert-manager

  info "prepare RBAC permissions ..."
  kubectl apply -f resources/f5-flo/flo-rbac.yaml
  info "configure certificate management ..."
  kubectl apply -f resources/f5-flo/cluster-issuer.yaml

  info "F5 Artifacts Registry (FAR) authentication token ..."
  # Create the SERVICE_ACCOUNT_K8S_SECRET variable by appending "_json_key_base64:" to the base64 encoded SERVICE_ACCOUNT_KEY
  SERVICE_ACCOUNT_K8S_SECRET=$(echo "_json_key_base64:${HELM_REPOSITORY_KEY}" | base64 -w 0)
  DOCKERCONFIGJSON_B64=$(
    printf '{"auths":{"%s":{"auth":"%s"}}}' \
      "${REPO}" \
      "${SERVICE_ACCOUNT_K8S_SECRET}" \
      | base64 -w 0
    )
  export DOCKERCONFIGJSON_B64
  envsubst < resources/f5-flo/far-secret.yaml | kubectl -n dpf-operator-system apply -f-

  info "render flo-value.yaml based on JWT prod/tst type ..."
  export JWT=$(cat ~/.jwt)
  if cut -d\. -f1 ~/.jwt | base64 -d | grep tst; then
    envsubst < resources/f5-flo/flo-value-tst.yaml >/tmp/flo-value.yaml
  else
    envsubst < resources/f5-flo/flo-value.yaml >/tmp/flo-value.yaml
  fi

  info "Install F5 Lifecycle Operator (FLO) ..."
  helm upgrade --install flo oci://${REPO}/charts/f5-lifecycle-operator --version $(get_chart_version f5-lifecycle-operator) -f /tmp/flo-value.yaml --namespace dpf-operator-system --wait --atomic

  # info "create cnemanifest ..." # missing from Wael's ailab repo, but
# mentioned as Step 4 in https://docs.f5net.com/spaces/~kondapaneni/pages/1176312338/BNK+Deployment+in+DPF+Trusted-Mode+hbn-ovnk+use-case

  info "deploy cne-instance ..."
  envsubst < resources/f5-flo/cne-instance.yaml | kubectl -n dpf-operator-system apply -f-

  info "Install argocd helm far secret ..."
  if ! cat resources/f5-flo/argocd-far-secret.yaml | envsubst | kubectl apply -f-; then
    err "Applying manifests failed"; return 1
  fi

  info "Install OTEL prerequired cert ..."
  kubectl apply -f resources/f5-flo/otel-certs.yaml

  info "Install Cluster Wide Controller (CWC) to manage license and debug API ..."
  rm -rf ~/cwc || true

  helm pull oci://${REPO}/utils/f5-cert-gen --version $(get_chart_version f5-cert-gen)  --untar --untardir ~/cwc
  mv ~/cwc/f5-cert-gen ~/cwc/cert-gen
  pushd ~/cwc && sh cert-gen/gen_cert.sh -s=api-server -a=f5-spk-cwc.dpf-operator-system -n=1 && popd
  kubectl apply -f ~/cwc/cwc-license-certs.yaml -n dpf-operator-system

  echo ""
  echo "done"
}

delete() {

  info "Delete cert-manager and cluster issuer ..."

  kubectl delete -f resources/f5-flo/cne-instance.yaml || true
  kubectl delete -f resources/f5-flo/cluster-issuer.yaml || true
  helm delete -n cert-manager cert-manager || true

  info "Delete argocd helm far secret ..."
  kubectl delete -f resources/f5-flo/argocd-far-secret.yaml || true
  info "Delete OTEL prerequired cert ..."
  kubectl delete -f resources/f5-flo/otel-certs.yaml || true
  info "Delete cwc .."
  kubectl delete -f ~/cwc/cwc-license-certs.yaml -n dpf-operator-system || true
  kubectl delete ns dpf-operator-system || true
  helm delete -n dpf-operator-system f5-lifecycle-operator || true
  kubectl delete -f resources/f5-flo/flo-rbac.yaml || true
}

case "${1:-build}" in
  delete) delete ;;
  *)      build  ;;
esac
