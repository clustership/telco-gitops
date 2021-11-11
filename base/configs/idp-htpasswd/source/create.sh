#!/bin/sh

cat << EOF > ../01-htpasswd-secret.yaml
apiVersion: v1
data:
  htpasswd: $(cat ocp4.htpasswd | base64)
kind: Secret
metadata:
  creationTimestamp: null
  name: idp-htpass-secret
  namespace: openshift-config
EOF

