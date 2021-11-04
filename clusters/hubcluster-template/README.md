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
cd <git root>/clusters/my-mgmt
oc apply -k .
```

## Get argocd admin password and argocd web-ui url

Get access to ArgoCD interface:

```bash
ARGOCD_ADMIN_PASSWORD=$(oc -n openshift-gitops get secret openshift-gitops-cluster -o jsonpath='{.data.admin\.password}' | base64 -d)
echo $ARGOCD_ADMIN_PASSWORD
ARGOCD_HOST="$(oc -n openshift-gitops get route openshift-gitops-server -o jsonpath='{.spec.host}')"
echo $ARGOCD_HOST
argocd login --username admin --password ${ARGOCD_ADMIN_PASSWORD} ${ARGOCD_HOST}
```

