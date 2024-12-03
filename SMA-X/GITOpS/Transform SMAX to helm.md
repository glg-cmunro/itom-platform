mkdir ~/esm

cdfctl deployment create -d esm

#Create ESM storage class
```
cat <<EOT > ~/esm/K8sStorageClass.yml
allowVolumeExpansion: true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-sc
parameters:
  archiveOnDelete: "true"
provisioner: <PROVISIONER>
reclaimPolicy: Retain
volumeBindingMode: Immediate
```

mkdir -p /mnt/efs/var/vols/itom/itsma/logging-volume
mkdir -p /mnt/efs/var/vols/itom/itsma/config-volume
mkdir -p /mnt/efs/var/vols/itom/itsma/data-volume

NFS_SERVER=$(kubectl get pv itom-vol -ojson | jq -r .spec.nfs.server)
```
cat <<EOL > ~/esm/esm_pvs.yml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: esm-logging-volume
spec:
  accessModes:
    - ReadWriteMany
  capacity:
    storage: 500Gi
  nfs:
    path: /var/vols/itom/itsma/logging-volume
    server: ${NFS_SERVER}
  persistentVolumeReclaimPolicy: Retain
  storageClassName: efs-sc
  claimRef:
    name: logging-volume
    namespace: esm
  volumeMode: Filesystem

---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: esm-config-volume
spec:
  accessModes:
    - ReadWriteMany
  capacity:
    storage: 100Gi
  nfs:
    path: /var/vols/itom/itsma/config-volume
    server: ${NFS_SERVER}
  persistentVolumeReclaimPolicy: Retain
  storageClassName: efs-sc
  claimRef:
    name: config-volume
    namespace: esm
  volumeMode: Filesystem

---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: esm-data-volume
spec:
  accessModes:
    - ReadWriteMany
  capacity:
    storage: 200Gi
  nfs:
    path: /var/vols/itom/itsma/data-volume
    server: ${NFS_SERVER}
  persistentVolumeReclaimPolicy: Retain
  storageClassName: efs-sc
  claimRef:
    name: data-volume
    namespace: esm
  volumeMode: Filesystem
EOL
