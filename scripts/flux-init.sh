#!/usr/bin/env bash

set -e

if [[ ! -x "$(command -v kubectl)" ]]; then
    echo "kubectl not found"
    exit 1
fi

if [[ ! -x "$(command -v helm)" ]]; then
    echo "helm not found"
    exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_URL=${1:-git@github.com:jwenz723/kubernetes-workshop-flux}
GIT_PATH=${2:-k8s/}
REPO_BRANCH=master
TEMP=${REPO_ROOT}/temp

rm -rf ${TEMP} && mkdir ${TEMP}

cat <<EOF >> ${TEMP}/flux-values.yaml
helmOperator:
  create: true
  createCRD: true
  configureRepositories:
    enable: true
    volumeName: repositories-yaml
    secretName: flux-helm-repositories
    cacheVolumeName: repositories-cache
    repositories:
      - caFile: ""
        cache: stable-index.yaml
        certFile: ""
        keyFile: ""
        name: stable
        password: ""
        url: https://kubernetes-charts.storage.googleapis.com
        username: ""
EOF

helm repo add fluxcd https://charts.fluxcd.io

echo ">>> Installing Flux for ${REPO_URL}"
helm upgrade -i flux --wait \
--set git.url=${REPO_URL} \
--set git.branch=${REPO_BRANCH} \
--set git.path=${GIT_PATH} \
--set git.pollInterval=15s \
--set registry.pollInterval=15s \
--namespace flux \
-f ${TEMP}/flux-values.yaml \
fluxcd/flux

kubectl -n flux rollout status deployment/flux

echo '>>> GitHub deploy key'
echo "Browse to https://github.com/settings/ssh/new and create a new github sshkey with a title of 'kubernetes-workshop' and a 'key' value of:"
kubectl -n flux logs deployment/flux | grep identity.pub | cut -d '"' -f2

