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

```bash
argocd cluster add --kubeconfig /repos/RH_POC/mgmt/automate-assisted-service/transfert/nokia-poc-compact/kubeconfig.compact admin --name nokia-poc-compact
```


## Deploy configuration

### Copy template directory to create directory for your cluster

```bash
export CLUSTER_NAME=$(oc get clusterdeployment nokia-poc-compact -o jsonpath='{.metadata.name}')
mkdir -p clusters/${CLUSTER_NAME}
cp -r clusters/ran-du-template/* clusters/${CLUSTER_NAME}
oc apply -k ./clusters/${CLUSTER_NAME}
```
