#!/bin/sh

export CLUSTER_NAME=$(oc get clusterdeployment nokia-poc-sno-bond -o jsonpath='{.metadata.name}')
oc get secret ${CLUSTER_NAME}-admin-kubeconfig -o jsonpath='{.data.kubeconfig}' | base64 -d > ./kubeconfig.${CLUSTER_NAME}
#
# Register cluster to argocd
#
argocd cluster add --kubeconfig `pwd`/kubeconfig.${CLUSTER_NAME} admin --name ${CLUSTER_NAME}
