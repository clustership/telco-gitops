# ODF deployment from cli

## Step 1: Installing the Local Storage Operator

Create openshift-local-storage namespace

```bash
cat << EOF | oc create -f -
apiVersion: v1
kind: Namespace
metadata:
  annotations:
    openshift.io/node-selector: ""
  labels:
    openshift.io/cluster-monitoring: "true"
  name: openshift-local-storage
EOF
```

Create LocalStorate OperatorGroup and Subscription. In case of disconnected installation, replace Subscription source by the name of your disconnected CatalogSource.

```bash
cat << EOF | oc create -f -
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: openshift-local-storage
  namespace: openshift-local-storage
spec:
  targetNamespaces:
  - openshift-local-storage
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-local-storage-operator
  namespace: openshift-local-storage
spec:
  channel: "4.9"  # <- replace with appropriate version
  installPlanApproval: Automatic
  name: local-storage-operator
  source: redhat-operators # <- replace by mirrored-rh-operator-catalog in case of disconnected installation using mirrored-rh-operator-catalog CatallogSource
  sourceNamespace: openshift-marketplace
EOF
```

Wait for Operator deployment reconcilliation (Job is missing for csv checking).
```bash
$ oc -n openshift-local-storage get csv | egrep Succeeded
NAME                                        DISPLAY         VERSION              REPLACES   PHASE
local-storage-operator.4.9.0-202111151318   Local Storage   4.9.0-202111151318              Succeeded
```

## Configure localstorage operator

If disk are not clean, wipe them before configuring local storage operator

```bash
DISK_DEVICE=/dev/sdb
for i in $(oc get node -l node-role.kubernetes.io/master= -o jsonpath='{ .items[*].metadata.name }'); do oc debug node/${i} -- chroot /host /usr/sbin/sgdisk --zap-all ${DISK_DEVICE}; done
```

Create a LocalVolume on storage nodes on /dev/sdb device (masters in this case)

```bash
cat << EOF | oc create -f -
---
apiVersion: local.storage.openshift.io/v1
kind: LocalVolume
metadata:
  name: local-disks
  namespace: openshift-local-storage
spec:
  managementState: Managed
  nodeSelector:
    nodeSelectorTerms:
    - matchExpressions:
      - key: node-role.kubernetes.io/master
        operator: Exists
  storageClassDevices:
  - devicePaths:
    - /dev/sdb
    storageClassName: localblock-sc
    volumeMode: Block
EOF
```

It creates a storageClass named localblock-sc and a PersistentVolume for each disk available on master nodes.
Check with

```bash
$ oc get sc
NAME            PROVISIONER                    RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
localblock-sc   kubernetes.io/no-provisioner   Delete          WaitForFirstConsumer   false                  12m

$ oc get pv
NAME                CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS    REASON   AGE
local-pv-3d3cf27f   1788Gi     RWO            Delete           Available           localblock-sc            12m
local-pv-63857859   1788Gi     RWO            Delete           Available           localblock-sc            12m
local-pv-b62ee641   1788Gi     RWO            Delete           Available           localblock-sc            12m
```

## Step 3: Installing OpenShift Data Foundation

### Install Operator

Create openshift-storage namespace for ODF

```bash
cat << EOF | oc create -f -
---
apiVersion: v1
kind: Namespace
metadata:
  labels:
    openshift.io/cluster-monitoring: "true"
  name: openshift-storage
EOF
```

Label nodes for ODF storage cluster deployment. In this case, we use master nodes but it can be other nodes as long as 3 storage nodes are defined.

```bash
oc label nodes $(oc get nodes -l node-role.kubernetes.io/master='' -o jsonpath='{..metadata.name}') cluster.ocs.openshift.io/openshift-storage=''
```

Create the OperatorGroup and the Subscription for ODF

```bash
cat << EOF | oc create -f -
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: openshift-storage-operatorgroup
  namespace: openshift-storage
spec:
  targetNamespaces:
  - openshift-storage
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  labels:
    operators.coreos.com/odf-operator.openshift-storage: ""
  name: odf-operator
  namespace: openshift-storage
spec:
  channel: stable-4.9
  installPlanApproval: Automatic
  name: odf-operator
  # source: redhat-operators # <- replace by mirrored-rh-operator-catalog in case of disconnected installation using mirrored-rh-operator-catalog CatallogSource
  source: mirrored-rh-operator-catalog
  sourceNamespace: openshift-marketplace
EOF
```

Wait for all 3 csv(s) to be in Suceeded state

```bash
$ oc get csv
NAME                  DISPLAY                       VERSION   REPLACES   PHASE
mcg-operator.v4.9.0   NooBaa Operator               4.9.0                Succeeded
ocs-operator.v4.9.0   OpenShift Container Storage   4.9.0                Succeeded
odf-operator.v4.9.0   OpenShift Data Foundation     4.9.0                Succeeded
```

### Create Storage System

```bash
cat << EOF | oc create -f -
apiVersion: odf.openshift.io/v1alpha1
kind: StorageSystem
metadata:
  name: ocs-storagecluster-storagesystem
  namespace: openshift-storage
spec:
  kind: storagecluster.ocs.openshift.io/v1
  name: ocs-storagecluster
  namespace: openshift-storage
EOF
```

### Create the Ceph StorageCluster

```bash
cat << EOF | oc create -f -
apiVersion: ocs.openshift.io/v1
kind: StorageCluster
metadata:
  annotations:
    argocd.argoproj.io/sync-options: SkipDryRunOnMissingResource=true
    argocd.argoproj.io/sync-wave: "45"
  name: ocs-storagecluster
  namespace: openshift-storage
spec:
  monDataDirHostPath: /var/lib/rook
  storageDeviceSets:
  - name: ocs-deviceset-localblock-sc
    count: 3
    dataPVCTemplate:
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 1
        storageClassName: localblock-sc
        volumeMode: Block
    placement: {}
EOF
```


### Step 4: Verifying the Installation

Verify if all the pods are up and running

```bash
oc get pods -n openshift-storage
```

*All the pods in the openshift-storage namespace must be in either Running or Completed state.
Cluster creation might take around 5 mins to complete. Please keep monitoring until you see the expected state or you see an error or you find progress stuck even after waiting for a longer period.*


### Step 5: Creating test CephRBD PVC and CephFS PVC.


```bash
cat << EOF | oc create -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: rbd-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: ocs-storagecluster-ceph-rbd
EOF
```

```bash
cat <<EOF | oc create -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cephfs-pvc
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  storageClassName: ocs-storagecluster-cephfs
EOF
```

Validate that the new PVCs are created and available

```bash
oc get pvc | grep rbd-pvc
oc get pvc | grep cephfs-pvc
```


### Optional define default storageClass

*Undefined default storage class before if one already exists.*

```bash
DEFAULT_SC=ocs-storagecluster-ceph-rdb
oc patch storageclass ${DEFAULT_SC} -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'
```
