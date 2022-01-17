#!/bin/sh

oc annotate storagecluster ocs-storagecluster uninstall.ocs.openshift.io/cleanup-policy="delete" --overwrite
oc annotate storagecluster ocs-storagecluster uninstall.ocs.openshift.io/mode="forced" --overwrite


RBD_PROVISIONER="openshift-storage.rbd.csi.ceph.com"
CEPHFS_PROVISIONER="openshift-storage.cephfs.csi.ceph.com"
NOOBAA_PROVISIONER="openshift-storage.noobaa.io/obc"
RGW_PROVISIONER="openshift-storage.ceph.rook.io/bucket"
NOOBAA_DB_PVC="noobaa-db"
NOOBAA_BACKINGSTORE_PVC="noobaa-default-backing-store-noobaa-pvc"
# Find all the OCS StorageClasses
OCS_STORAGECLASSES=$(oc get storageclasses | grep -e "$RBD_PROVISIONER" -e "$CEPHFS_PROVISIONER" -e "$NOOBAA_PROVISIONER" -e "$RGW_PROVISIONER" | awk '{print $1}')
# List PVCs in each of the StorageClasses
for SC in $OCS_STORAGECLASSES
do
        echo "======================================================================"
        echo "$SC StorageClass PVCs and OBCs"
        echo "======================================================================"
        oc get pvc  --all-namespaces --no-headers 2>/dev/null | grep $SC | grep -v -e "$NOOBAA_DB_PVC" -e "$NOOBAA_BACKINGSTORE_PVC"
        oc get obc  --all-namespaces --no-headers 2>/dev/null | grep $SC
        echo
done


oc delete -n openshift-storage storagesystem --all --wait=true

oc project default
oc delete project openshift-storage --wait=true --timeout=5m

NS_STATUS=$(oc get ns openshift-storage -oname)
while [ "$NS_STATUS" != "" ]; do
  echo "Waiting for the openshift-storage ns to be deleted. ($NS_STATUS)"
  sleep 5
  NS_STATUS=$(oc get ns openshift-storage -oname)
done
echo "ns deleted, moving forward"

oc delete crd backingstores.noobaa.io bucketclasses.noobaa.io cephblockpools.ceph.rook.io cephclusters.ceph.rook.io cephfilesystems.ceph.rook.io cephnfses.ceph.rook.io cephobjectstores.ceph.rook.io cephobjectstoreusers.ceph.rook.io noobaas.noobaa.io ocsinitializations.ocs.openshift.io storageclusters.ocs.openshift.io cephclients.ceph.rook.io cephobjectrealms.ceph.rook.io cephobjectzonegroups.ceph.rook.io cephobjectzones.ceph.rook.io cephrbdmirrors.ceph.rook.io storagesystems.odf.openshift.io --wait=true --timeout=5m

export SC=odf-localvolumeset-sc

oc -n openshift-local-storage delete localvolumeset odf-localvolumeset
oc get pv | grep $SC | awk '{print $1}'| xargs oc delete pv
oc delete sc $SC

[[ ! -z $SC ]] && for i in $(oc get node -l cluster.ocs.openshift.io/openshift-storage= -o jsonpath='{ .items[*].metadata.name }'); do oc debug node/${i} -- chroot /host rm -rfv /mnt/local-storage/${SC}/; done

oc delete localvolumediscovery.local.storage.openshift.io/auto-discover-devices -n openshift-local-storage

[[ ! -z $SC ]] && for i in $(oc get node -l cluster.ocs.openshift.io/openshift-storage= -o jsonpath='{ .items[*].metadata.name }'); do oc debug node/${i} -- chroot /host rm -rfv /mnt/local-storage/${SC}/; done

oc project default
oc delete project openshift-local-storage --wait=true --timeout=5m

NS_STATUS=$(oc get ns openshift-local-storage -oname)
while [ "$NS_STATUS" != "" ]; do
  echo "Waiting for the openshift-storage ns to be deleted. ($NS_STATUS)"
  sleep 5
  NS_STATUS=$(oc get ns openshift-local-storage -oname)
done
echo "ns deleted, moving forward"

exit 0
