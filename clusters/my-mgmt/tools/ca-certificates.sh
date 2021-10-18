#!/bin/sh

CERT="$(cat certs/fullchain.crt | base64 -w0)"
KEY="$(cat certs/server.key | base64 -w0)"

cat << EOF > x-01-ingress-cert.yaml
---
apiVersion: v1
kind: Secret
data:
  tls.crt: "${CERT}"
  tls.key: "${KEY}"
metadata:
  name: letsencrypt-router-certs
  namespace: openshift-ingress
type: kubernetes.io/tls
---
apiVersion: v1
kind: Secret
data:
  tls.crt: "${CERT}"
  tls.key: "${KEY}"
metadata:
  name: letsencrypt-certs
  namespace: openshift-config
type: kubernetes.io/tls
EOF
