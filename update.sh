#!/bin/bash

set -x

if [ -z ${PLUGIN_NAMESPACE} ]; then
  PLUGIN_NAMESPACE="default"
fi

if [ ! -z ${PLUGIN_KUBERNETES_USER} ]; then
  KUBERNETES_USER=$PLUGIN_KUBERNETES_USER
fi


if [ ! -z ${PLUGIN_KUBERNETES_TOKEN} ]; then
  KUBERNETES_TOKEN=$PLUGIN_KUBERNETES_TOKEN
fi

if [ ! -z ${PLUGIN_KUBERNETES_SERVER} ]; then
  KUBERNETES_SERVER=$PLUGIN_KUBERNETES_SERVER
fi

if [ ! -z ${PLUGIN_KUBERNETES_CERT} ]; then
  KUBERNETES_CERT=${PLUGIN_KUBERNETES_CERT}
fi

if [ ! -z ${PLUGIN_KUBERNETES_CLUSTER} ]; then
  KUBERNETES_CLUSTER=${PLUGIN_KUBERNETES_CLUSTER}
fi


kubectl config set-credentials ${PLUGIN_KUBERNETES_USER} --token=${PLUGIN_KUBERNETES_TOKEN}
if [ ! -z ${KUBERNETES_CERT} ]; then
  echo ${KUBERNETES_CERT} | base64 -d > ca.crt
  kubectl config set-cluster ${KUBERNETES_CLUSTER} --server=${KUBERNETES_SERVER} --certificate-authority=ca.crt
else
  echo "WARNING: Using insecure connection to cluster"
  kubectl config set-cluster ${PLUGIN_KUBERNETES_CLUSTER} --server=${PLUGIN_KUBERNETES_SERVER} --insecure-skip-tls-verify=true
fi

kubectl config set-context ${PLUGIN_KUBERNETES_USER} --cluster=${PLUGIN_KUBERNETES_CLUSTER} --user=${PLUGIN_KUBERNETES_USER}
kubectl config use-context ${PLUGIN_KUBERNETES_USER}

echo "Plugin: ${PLUGIN_KUBERNETES_USER}"

# kubectl version
IFS=',' read -r -a DEPLOYMENTS <<< "${PLUGIN_DEPLOYMENT}"
IFS=',' read -r -a CONTAINERS <<< "${PLUGIN_CONTAINER}"
for DEPLOY in ${DEPLOYMENTS[@]}; do
  echo Deploying to $KUBERNETES_SERVER
  for CONTAINER in ${CONTAINERS[@]}; do
    if [[ ${PLUGIN_FORCE} == "true" ]]; then
      kubectl -n ${PLUGIN_NAMESPACE} set image deployment/${DEPLOY} \
        ${CONTAINER}=${PLUGIN_REPO}:${PLUGIN_TAG}FORCE
    fi
    kubectl -n ${PLUGIN_NAMESPACE} set image deployment/${DEPLOY} \
      ${CONTAINER}=${PLUGIN_REPO}:${PLUGIN_TAG} --record
  done
done
