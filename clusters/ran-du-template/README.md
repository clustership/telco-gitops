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

# Deploy a gitops managed ran-du cluster (SNO, Compact, Multi nodes...)


## Register cluster to argocd

### Authenticate to argocd server

Get access to ArgoCD:

```bash
ARGOCD_ADMIN_PASSWORD=$(oc -n openshift-gitops get secret openshift-gitops-cluster -o jsonpath='{.data.admin\.password}' | base64 -d)
echo $ARGOCD_ADMIN_PASSWORD
ARGOCD_HOST="$(oc -n openshift-gitops get route openshift-gitops-server -o jsonpath='{.spec.host}')"
echo $ARGOCD_HOST
argocd login --username admin --password ${ARGOCD_ADMIN_PASSWORD} ${ARGOCD_HOST}
```

```bash
argocd cluster add --kubeconfig /repos/RH_POC/mgmt/automate-assisted-service/transfert/nokia-poc-compact/kubeconfig.compact admin --name nokia-poc-compact
```


## Deploy configuration

### Copy template directory to create directory for your cluster

```bash
export CLUSTER_NAMESPACE=<cluster-namespace>
export CLUSTER_NAME=$(oc get clusterdeployment ${CLUSTER_NAMESPACE} -o jsonpath='{.metadata.name}')
mkdir -p clusters/${CLUSTER_NAME}
cp -r clusters/ran-du-template/* clusters/${CLUSTER_NAME}
oc get secret ${CLUSTER_NAME}-admin-kubeconfig -o jsonpath='{.data.kubeconfig}' | base64 -d > clusters/${CLUSTER_NAME}/kubeconfig
#
# Register cluster to argocd
#
argocd cluster add --kubeconfig `pwd`/clusters/${CLUSTER_NAME}/kubeconfig admin --name ${CLUSTER_NAME}
#
# Wait for cluster to be added to argocd
# check with
# % argocd cluster list
#
# Then apply configuration
oc apply -k ./clusters/${CLUSTER_NAME}
```
