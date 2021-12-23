#!/bin/sh

ARGOCD_ADMIN_PASSWORD=$(oc -n openshift-gitops get secret openshift-gitops-cluster -o jsonpath='{.data.admin\.password}' | base64 -d)
ARGOCD_HOST="$(oc -n openshift-gitops get route openshift-gitops-server -o jsonpath='{.spec.host}')"

argocd login --insecure --username admin --password ${ARGOCD_ADMIN_PASSWORD} ${ARGOCD_HOST}
