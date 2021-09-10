# Deploy a management cluster

## Pre-requisites

OCP cluster should be up and accessible with an account with cluster-admin rights

## Order of execution

The goal is to get everything under the control of GitOps operator (ArgoCD). But first of all, GitOps operator must be deployed on the targeted management cluster (or on a cluster that control the deployment of the targeted management cluster).


### Deploy gitops operator

```bash
oc apply -k ./cluster/mgmt/gitops-operator

```


Get access to ArgoCD interface:

```bash
ARGOCD_ADMIN_PASSWORD=$(oc -n telco-gitops get secret telco-gitops-cluster -o jsonpath='{.data.admin\.password}' | base64 -d)
echo $ARGOCD_ADMIN_PASSWORD
ARGOCD_HOST="https://$(oc -n telco-gitops get route telco-gitops-server -o jsonpath='{.spec.host}')"
echo $ARGOCD_HOST
```

### Create ArgoCD application to deploy ACM
