#!/bin/sh

CERT="$(cat certs/fullchain.crt | sed -e 's/^/          /')"
KEY="$(cat certs/server.key | sed -e 's/^/          /')"

cat << EOF > x-02-argocd-certs.yaml  
apiVersion: argoproj.io/v1alpha1
kind: ArgoCD
metadata:
  name: openshift-gitops
  namespace: openshift-gitops
spec:
  server:
    route:
      enabled: true
      tls:
        insecureEdgeTerminationPolicy: Redirect
        termination: reencrypt
        certificate: |-
${CERT}
        key: |-
${KEY}
EOF
