#!/bin/sh

CERT="$(cat certs/fullchain.crt | sed -e 's/^/          /')"
KEY="$(cat certs/server.key | sed -e 's/^/          /')"
ARGOCD_HOST=openshift-gitops-server-openshift-gitops.mgmt.espoo.nsn-rdnet.net

cat << EOF > x-02-argocd-certs.yaml  
apiVersion: argoproj.io/v1alpha1
kind: ArgoCD
metadata:
  name: openshift-gitops
  namespace: openshift-gitops
spec:
  server:
    route:
      router: ${ARGOCD_HOST}
      enabled: true
      tls:
        insecureEdgeTerminationPolicy: Redirect
        termination: reencrypt
        certificate: |-
${CERT}
        key: |-
${KEY}
EOF
