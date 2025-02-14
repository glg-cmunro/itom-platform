# GreenLight Group - How To - Transform SMA classic to ESM Helm  
# ![GreenLight Group Logo](https://assets.website-files.com/5ebcb9396faf10d8f7644479/5ed6a066891af295a039860f_GLGLogolrg-p-500.png)  

### Deployment Steps
1. Download/Extract ESM Helm Chart
2. Pre-Requisites
   - Gather System Information  
   - Extend EFS Volumes  
   - Sync Data Volumes  
   - Get basic values  
   - Get custom values  

3. Transform SMA classic to ESM Helm
   - Stop OMT and SMA
   - Verify resources are 'DOWN'
   - Delete SMA namespace
   - Sync Data Volumes (incremental)
   - Patch OMT deployment
   - Create ESM deployment


### Backup Cluster  
Backup Cluster and SUITE before making any changes  
[AWS Backup Cluster](/docs/Ansible/AWS/AWS_Cluster-Backup.md)

### Execute Actions

#### Download/Extract ESM Helm Chart
<details><summary>Download/Extract ESM Heln Chart</summary>  

> Create ESM working directory
```
mkdir -p ~/esm/24.2.2
```
> Download the ESM Helm chart for ESM 24.2 Patch 2
```
curl https://owncloud.gitops.com/index.php/s/eYjtMSYnEi8Qtax/download -o ~/esm/24.2.2/ESM_Helm_Chart-24.2.2.zip
unzip ~/esm/24.2.2/ESM_Helm_Chart-24.2.2.zip -d ~/esm/24.2.2/
unzip ~/esm/24.2.2/esm-1.0.2+24.2.2-18.zip -d ~/esm/24.2.2/
rm ~/esm/24.2.2/esm-1.0.2+24.2.2-18.zip
rm ~/esm/24.2.2/esm-1.0.2+24.2.2-18.zip.sig

chmod u+x ~/esm/24.2.2/scripts/transformation/syncData.sh
chmod u+x ~/esm/24.2.2/scripts/transformation/generateBasicValuesYaml.sh
chmod u+x ~/esm/24.2.2/scripts/custom_settings/generateCustomSettings.sh
chmod u+x ~/esm/24.2.2/scripts/transformation/refinePV.sh
```
</details>

#### Pre-requisites  
<details><summary>Pre-requisites</summary>  

> Gather system information  
```
NAMESPACE=`kubectl get namespace|grep itsma | cut -f1 -d " "`
SYSTEM_USER_ID=$(kubectl get configmap -o jsonpath='{.data.system_user_id}' itsma-common-configmap -n $NAMESPACE)
SYSTEM_GROUP_ID=$(kubectl get configmap -o jsonpath='{.data.system_group_id}' itsma-common-configmap -n $NAMESPACE)
SIZE=$(kubectl get configmap -o jsonpath='{.data.itom_suite_size}' itsma-common-configmap -n $NAMESPACE)

echo NAMESPACE: $NAMESPACE SYSTEM_USER_ID: ${SYSTEM_USER_ID}, SYSTEM_GROUP_ID: ${SYSTEM_GROUP_ID}, SIZE: ${SIZE}
```

> Extend EFS volumes  
```
sudo mkdir -p /mnt/efs/var/vols/itom/itsma/logging-volume
sudo mkdir -p /mnt/efs/var/vols/itom/itsma/config-volume

sudo chown -R 1999:1999 /mnt/efs/var/vols/itom/itsma/logging-volume
sudo chown -R 1999:1999 /mnt/efs/var/vols/itom/itsma/config-volume

sudo chmod g+w /mnt/efs/var/vols/itom/itsma/logging-volume
sudo chmod g+w /mnt/efs/var/vols/itom/itsma/config-volume
sudo chmod g+s /mnt/efs/var/vols/itom/itsma/logging-volume
sudo chmod g+s /mnt/efs/var/vols/itom/itsma/config-volume

#sudo find /mnt/efs/var/vols/itom -type d -exec stat --format='%u:%g %A %n' '{}' \;| grep -v 1999:1999

```

> Sync data volumes
```
sudo ~/esm/24.2.2/scripts/transformation/syncData.sh \
 --globalVolumePath /mnt/efs/var/vols/itom/itsma/global-volume \
 --smartanalyticsVolumePath /mnt/efs/var/vols/itom/itsma/smartanalytics-volume \
 --configVolumePath /mnt/efs/var/vols/itom/itsma/config-volume

```

> Get Basic environment Helm values  
```
cd ~/esm/24.2.2/scripts/transformation/
~/esm/24.2.2/scripts/transformation/generateBasicValuesYaml.sh

```
```
cp ~/esm/24.2.2/scripts/transformation/values.yaml ~/esm/
cd ~

```

> Get Customizations to resources Helm values  
```
cd ~/esm/24.2.2/scripts/custom_settings
~/esm/24.2.2/scripts/custom_settings/generateCustomSettings.sh

```
```
cp ~/esm/24.2.2/scripts/custom_settings/customized_values.yaml ~/esm/
cd ~

```
</details>

#### Start ESM Helm Transformation  
<details><summary>Start ESM Helm Transformation</summary>  

> Stop the Suite and OMT  
```
$CDF_HOME/bin/cdfctl runlevel set -l DOWN -n $NAMESPACE
$CDF_HOME/bin/cdfctl runlevel set -l DOWN -n core
```

> Verify everything is 'DOWN' before continuing on  
**_If any pods return, wait and check again_**  
```
kubectl get pod -n $NAMESPACE|grep -v -E 'throttling|opentelemetry|toolkit|Completed'
kubectl get pod -n core |grep -v Completed
```

> Delete classic SMA resources
```
kubectl delete ns $NAMESPACE
```

> Verify the namespace is successfully deleted  
**_If the ITSMA namespace still shows up, wait and check again_**  
```
kubectl get ns
```

> Sync ingremental data since pre-reqs
```
sudo ~/esm/24.2.2/scripts/transformation/syncData.sh \
 --globalVolumePath /mnt/efs/var/vols/itom/itsma/global-volume \
 --smartanalyticsVolumePath /mnt/efs/var/vols/itom/itsma/smartanalytics-volume \
 --configVolumePath /mnt/efs/var/vols/itom/itsma/config-volume
```

> Patch the deployment name for the core namespace
```
kubectl patch ns core -p '{"metadata":{"labels":{"deployments.microfocus.com/deployment-name":"cdf"}}}'
```

> Create new ESM deployment (using original itsma namespace name)
```
$CDF_HOME/bin/cdfctl deployment create -d $NAMESPACE

```

> Refine existing PVs for new deployment
```
cd ~/esm/24.2.2/scripts/transformation
~/esm/24.2.2/scripts/transformation/refinePV.sh $SIZE

```
```
cd ~

```

> Verify new PVs created
```
kubectl get pv|grep -E  "config-volume|logging-volume|data-volume"|grep itsma

```

> Check if new PVs are not yet 'Available'  
*_Will only return values for PVs that are NOT yet ready_*  
```
kubectl get pv|grep itsma|grep -v -E "db-volume|global-volume|smartanalytics"|awk '{if ($5!="Available") print $0}'

```


> Copy OMT vault data to global-volume for independant SMA vault
```
sudo cp -R /mnt/efs/var/vols/itom/core/vault /mnt/efs/var/vols/itom/itsma/global-volume/
sudo chown -R $SYSTEM_USER_ID:$SYSTEM_GROUP_ID /mnt/efs/var/vols/itom/itsma/global-volume/vault

```

> Cppy OMT vault secrets to SMA vault
```
#!/bin/bash
#NAMESPACE=${NAMESPACE}
releaseName=sma
for secret in vault-passphrase vault-credential vault-instance-id vault-root-cert
  do
  echo "-----copy secret $secret from core to ${NAMESPACE} -----"
kubectl get secrets -n core $secret -o yaml | sed "s/meta.helm.sh\/release-namespace\:\ core/meta.helm.sh\/release-namespace\:\ ${NAMESPACE}/g" | sed "s/meta.helm.sh\/release-name\:\ apphub/meta.helm.sh\/release-name\:\ \'${releaseName}\'/g" | sed "s/namespace\:\ core/namespace\:\ ${NAMESPACE}/g" | kubectl create -f -
  done
cm=public-ca-certificates
echo "-----create cm $cm from core to ${NAMESPACE} -----"
kubectl get cm -n core $cm -o yaml | sed "s/meta.helm.sh\/release-namespace\:\ core/meta.helm.sh\/release-namespace\:\ ${NAMESPACE}/g" | sed "s/meta.helm.sh\/release-name\:\ apphub/meta.helm.sh\/release-name\:\ \'${releaseName}\'/g" | sed "s/namespace\:\ core/namespace\:\ ${NAMESPACE}/g" | kubectl create -f -

```

> Start OMT back up to continue deployment
```
$CDF_HOME/bin/cdfctl runlevel set -l UP -n core

```

> Verify OMT is up and running completely before continuing
```
watch -n 10 'kubectl get pods -n core|grep -v 1/1|grep -v 2/2|grep -v 3/3|grep -v 4/4|grep -v Completed'

```
</details>

### Deploy ESM Helm chart
```
#$CDF_HOME/bin/helm install sma ~/esm/24.2/charts/esm-1.0.0+24.2-528.tgz -n $NAMESPACE -f ~/esm/24.2/charts/values.yaml --set global.nodeSelector.Worker=label -f  ~/esm/24.2/charts/customized_values.yaml
$CDF_HOME/bin/helm install sma ~/esm/24.2.2/charts/esm-1.0.2+24.2.2-18.tgz -n $NAMESPACE -f ~/esm/values.yaml --set global.nodeSelector.Worker=label -f  ~/esm/customized_values.yaml

```


> Redeploy sma-ingress
```
INTEGRATION_FQDN=t800-int.dev.gitops.com
CLUSTER_NAME=T800

ELB_NAME=$(kubectl get ing -n core mng-ingress -ojson | jq -r '.metadata.annotations["alb.ingress.kubernetes.io/group.name"]') && echo $ELB_NAME
EXT_ACCESS_FQDN=$(kubectl get ing -n core mng-ingress -ojson | jq -r '.spec.tls[].hosts[]') && echo $EXT_ACCESS_FQDN
CERT_ARN=$(kubectl get ing -n core mng-ingress -ojson | jq -r '.metadata.annotations["alb.ingress.kubernetes.io/certificate-arn"]') && echo $CERT_ARN

cat << EOT | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: "sma-ingress"
  namespace: $NAMESPACE
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/group.name: ${ELB_NAME}
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS": 443}]'
    alb.ingress.kubernetes.io/backend-protocol: HTTPS
    alb.ingress.kubernetes.io/healthcheck-protocol: HTTPS
    alb.ingress.kubernetes.io/healthcheck-port: traffic-port
    alb.ingress.kubernetes.io/healthcheck-path: /healthz
    alb.ingress.kubernetes.io/success-codes: 200-399
    alb.ingress.kubernetes.io/target-type: instance
    alb.ingress.kubernetes.io/load-balancer-attributes: idle_timeout.timeout_seconds=180
    alb.ingress.kubernetes.io/certificate-arn: ${CERT_ARN}
    alb.ingress.kubernetes.io/ssl-policy: ELBSecurityPolicy-TLS13-1-2-Res-2021-06
  labels:
    app: sma-ingress
spec:
  ingressClassName: alb
  tls:
  - hosts:
    - ${EXT_ACCESS_FQDN,,}
  rules:
    - host: 
      http:
        paths:
          - backend:
              service: 
                name: "itom-nginx-ingress-svc"
                port: 
                  number: 443
            path: /*
            pathType: ImplementationSpecific
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    alb.ingress.kubernetes.io/backend-protocol: HTTPS
    alb.ingress.kubernetes.io/certificate-arn: ${CERT_ARN}
    alb.ingress.kubernetes.io/group.name: ${CLUSTER_NAME,,}-int
    alb.ingress.kubernetes.io/healthcheck-path: /healthz
    alb.ingress.kubernetes.io/healthcheck-port: traffic-port
    alb.ingress.kubernetes.io/healthcheck-protocol: HTTPS
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS": 2443}]'
    alb.ingress.kubernetes.io/load-balancer-attributes: idle_timeout.timeout_seconds=180
    alb.ingress.kubernetes.io/scheme: internal
    alb.ingress.kubernetes.io/success-codes: 200-399
    alb.ingress.kubernetes.io/target-type: instance
  finalizers:
  - group.ingress.k8s.aws/${CLUSTER_NAME,,}-int
  labels:
    app: sma-integration-ingress
  name: sma-integration-ingress
  namespace: ${NS}
spec:
  ingressClassName: alb
  rules:
  - http:
      paths:
      - backend:
          service:
            name: itom-nginx-ingress-svc
            port:
              number: 443
        path: /*
        pathType: ImplementationSpecific
  tls:
  - hosts:
    - ${INTEGRATION_FQDN,,}
EOT

```


> Update helm autopass
```
#chmod u+x ~/esm/24.2/scripts/transformation/updateAutopassKey.sh
#~/esm/24.2/scripts/transformation/updateAutopassKey.sh -n $NAMESPACE

chmod u+x ~/esm/24.2.2/scripts/transformation/updateAutopassKey.sh
~/esm/24.2.2/scripts/transformation/updateAutopassKey.sh -n $NAMESPACE

```



#Install Support Assistant
#Reconfigure monitoring


### Cleanup unused OMT resources
```
sudo chmod g+rx ${CDF_HOME}/charts
sudo chmod g+rw ${CDF_HOME}/charts/*

APPHUB_CHART=$(cd ${CDF_HOME}/charts && ls apphub-1*.tgz) && echo ${APPHUB_CHART}

helm upgrade apphub $CDF_HOME/charts/${APPHUB_CHART} --reuse-values --set global.services.suiteDeploymentManagement=false -n core

```
```
kubectl delete deploy suite-conf-pod-itsma -n core --ignore-not-found=true
kubectl delete svc suite-conf-svc-itsma  -n core --ignore-not-found=true
kubectl delete ingress suite-conf-ing-itsma -n core --ignore-not-found=true

```
```
kubectl delete ingress -n core -l app=install-ingress 

```







NFS_SERVER=$(kubectl get pv itom-vol -ojson | jq -r .spec.nfs.server)

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
provisioner: gitops.com/external-nfs
reclaimPolicy: Retain
volumeBindingMode: Immediate
```

mkdir -p /mnt/efs/var/vols/itom/itsma/data-volume

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
