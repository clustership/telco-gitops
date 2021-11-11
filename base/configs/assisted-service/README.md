# Create global hive pull secret

Take care as the pull secret will be used for all clusters.
```bash
oc create secret generic global-pull-secret --from-file=.dockerconfigjson=./pull_secret.json --type=kubernetes.io/dockerconfigjson --namespace hive
```

You can manage private registry by using individual assisted-pull-secret.

# Add private registry ca cert

```bash
oc create configmap registry-cas -n openshift-config \
  --from-file=registry.clustership.com..5000=./registry-ca.crt
oc patch image.config.openshift.io/cluster --patch '{"spec":{"additionalTrustedCA":{"name":"registry-cas"}}}' --type=merge
```

# Mirror assisted-installer-agent-rhel8

```bash
cat << EOF > mirror-assisted-installer-agent.sh
#!/bin/bash

LOCAL_REGISTRY=registry.clustership.com:5000

echo skopeo copy registry.redhat.io/rhacm2/assisted-installer-agent-rhel8:v2.3.2-3 ${LOCAL_REGISTRY}/rhacm2/assisted-installer-agent-rhel8:v2.3.2-3
exit 0
podman pull registry.redhat.io/rhacm2/assisted-installer-agent-rhel8:v2.3.2-3
podman tag registry.redhat.io/rhacm2/assisted-installer-agent-rhel8:v2.3.2-3 ${LOCAL_REGISTRY}/rhacm2/assisted-installer-agent-rhel8:v2.3.2-3
podman push ${LOCAL_REGISTRY}/rhacm2/assisted-installer-agent-rhel8:v2.3.2-3

EOF
