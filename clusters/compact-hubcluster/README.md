# Preparation

## Remove key password for TLS certs

```bash
openssl rsa -in mgmt_espoo_nsn-rdnet_net.key -out unencryed.key
```

## Copy certs and keys to the cluster deployment folder

```bash
mkdir -p certs
cp fullchain.crt unencrypted.key certs
```

## Geneate embedded files with certs

```bash
./tools/xx
```

## Download argocd cli

For MacOS

```bash
brew install argocd
```

For RHEL/CentOS

```bash
sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo chmod +x /usr/local/bin/argocd
```

# Deploy a gitops managed hubCluster


## Deploy OpenShift GitOps operator and trigger post-configuration

First of all, GitOps operator must be deployed on the management cluster:

```bash
cd <git root>/clusters/<new-cluster>
oc apply -k .
```

Check that gitops operator deployed successfully:

```bash
$ oc -n openshift-operators get csv
NAME                               DISPLAY                    VERSION   REPLACES                           PHASE
openshift-gitops-operator.v1.3.2   Red Hat OpenShift GitOps   1.3.2     openshift-gitops-operator.v1.3.1   Succeeded # <- must be in Succeeded phase

$ oc -n openshift-gitops get pods
NAME                                                          READY   STATUS    RESTARTS   AGE
cluster-54b7b77995-qrzrj                                      1/1     Running   0          4m28s
kam-76f5ff8585-gslms                                          1/1     Running   0          4m28s
openshift-gitops-application-controller-0                     1/1     Running   0          4m28s
openshift-gitops-applicationset-controller-6948bcf87c-5mw7v   1/1     Running   0          4m28s
openshift-gitops-dex-server-dff54bb5c-b5bvm                   1/1     Running   0          4m28s
openshift-gitops-redis-7867d74fb4-vrbtq                       1/1     Running   0          4m28s
openshift-gitops-repo-server-6dc777c845-d96q9                 1/1     Running   0          4m28s

```

## Get argocd admin password and argocd web-ui url

Get access to ArgoCD interface:

```bash
ARGOCD_ADMIN_PASSWORD=$(oc -n openshift-gitops get secret openshift-gitops-cluster -o jsonpath='{.data.admin\.password}' | base64 -d)
echo $ARGOCD_ADMIN_PASSWORD
ARGOCD_HOST="$(oc -n openshift-gitops get route openshift-gitops-server -o jsonpath='{.spec.host}')"
echo $ARGOCD_HOST
argocd login --insecure --username admin --password ${ARGOCD_ADMIN_PASSWORD} ${ARGOCD_HOST}
```


# Deploy ACM + assisted service on hubcluster

Once GitOps operator is available on the cluster, you can deploy the ACM stack using it.

Edit post-configuration/kustomization.yaml to match your cluster configuration.

```bash
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

commonLabels:
  # topology.kubernetes.io/region: demo
  # Each SITE_ID is a different zone
  #topology.kubernetes.io/zone: sample-zone
  telco-gitops/cluster-name: compact-hubcluster  # <- change to match your cluster name
  telco-gitops/cluster-type: hubcluster

generatorOptions:
  # Annotations to work around automatically generated resoruces
  # to avoid ArgoCD reporing out-of-sync
  annotations:
    argcd.argoproj.io/compare-options: IgnoreExtraneous
    argocd.argoproj.io/sync-options: Prune=false


bases:
# - ../../base/configs/all-common
- ../../../blueprints/hubcluster-simple

#  # OpenShift Logging
#  # - ../../base/operators/openshift-logging
#  - github.com/openshift-telco/telco-gitops/base/operators/openshift-logging?ref=main

#resources:
#- node-role.yaml

images:
- name: registry.redhat.io/openshift4/ose-cli
  newName: hubcluster-registry.apps.mgmt.espoo.nsn-rdnet.net/openshift/ose-cli

patchesStrategicMerge:
- |-
  apiVersion: operators.coreos.com/v1alpha1
  kind: Subscription
  metadata:
    name: advanced-cluster-management
    namespace: open-cluster-management
  spec:
    source: mirrored-rh-operator-catalog
- |-
  apiVersion: operators.coreos.com/v1alpha1
  kind: Subscription
  metadata:
    name: openshift-local-storage-operator
    namespace: openshift-local-storage
  spec:
    source: mirrored-rh-operator-catalog
- |-
  apiVersion: operators.coreos.com/v1alpha1
  kind: Subscription
  metadata:
    name: odf-operator
    namespace: openshift-storage
  spec:
    source: mirrored-rh-operator-catalog

# patchesStrategicMerge:
# - |-
```

Then edit application/gitops-application.yaml to match your git repository for the ArgoCD resources to apply.

```bash
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: hubcluster-deploy
  namespace: openshift-gitops
spec:
  # The argocd project the application belongs to
  project: default
  destination:
    name: in-cluster
  # Source of the application manifests
  source:
    repoURL: 'https://gitlabe1.ext.net.nokia.com/rcp-infra/telco-gitops.git' # <- change to match your git repo server and git repository here
    targetRevision: hubcluster-4.9 # <- change to match your current branch
    path: clusters/compact-hubcluster/post-configuration # <- change to match the path of your cluster post-configuration
    directory:
      recurse: false
  # Sync policy
  [...]
```


Create the ArgoCD application to trigger hubcluster (ODF+ACM+AI deployment):

```bash
oc apply -k ./application

argocd app list

```
