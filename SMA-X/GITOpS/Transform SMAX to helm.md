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
   - Get current INGRESS
3. Transform SMA classic to ESM Helm
   - Stop OMT and SMA
   - Verify resources are 'DOWN'
   - Delete SMA namespace
   - Sync Data Volumes (incremental)
   - Patch OMT deployment
4. Deploy ESM
   - Execute helm install
   - Redeploy Ingress
5. Post Transform Tasks
   - Re-Install ITOM Toolkit
   - Cleanup OMT

--- 

### Environment Variables used throughout this document  
```
CDF_HOME=/opt/cdf
NAMESPACE=`kubectl get namespace|grep itsma | cut -f1 -d " "`
SYSTEM_USER_ID=$(kubectl get configmap -o jsonpath='{.data.system_user_id}' itsma-common-configmap -n $NAMESPACE)
SYSTEM_GROUP_ID=$(kubectl get configmap -o jsonpath='{.data.system_group_id}' itsma-common-configmap -n $NAMESPACE)
SIZE=$(kubectl get configmap -o jsonpath='{.data.itom_suite_size}' itsma-common-configmap -n $NAMESPACE)

```

---

### Backup Cluster  
Backup Cluster and SUITE before making any changes  
[AWS Backup Cluster](https://github.com/GreenlightGroup/how-tos/blob/main/docs/Ansible/AWS/AWS_Cluster-Backup.md)

### Execute Actions  
#### Download/Extract ESM Helm Chart  
<details><summary>Download/Extract ESM Heln Chart</summary>  

> Create ESM working directory
   ```
   mkdir -p ~/esm/24.2.2
   
   ```

> Download the ESM Helm chart matching existing SMAX deployment (ESM 24.2 Patch 2)
   ```
   curl https://owncloud.gitops.com/index.php/s/eYjtMSYnEi8Qtax/download -o ~/esm/24.2.2/ESM_Helm_Chart-24.2.2.zip
   unzip ~/esm/24.2.2/ESM_Helm_Chart-24.2.2.zip -d ~/esm/24.2.2/
   unzip ~/esm/24.2.2/esm-1.0.2+24.2.2-18.zip -d ~/esm/24.2.2/
   rm ~/esm/24.2.2/esm-1.0.2+24.2.2-18.zip
   rm ~/esm/24.2.2/esm-1.0.2+24.2.2-18.zip.sig
   
   ```

> Set execute for requisite scripts
   ```
   chmod u+x ~/esm/24.2.2/scripts/transformation/syncData.sh
   chmod u+x ~/esm/24.2.2/scripts/transformation/generateBasicValuesYaml.sh
   chmod u+x ~/esm/24.2.2/scripts/custom_settings/generateCustomSettings.sh
   chmod u+x ~/esm/24.2.2/scripts/transformation/refinePV.sh
   chmod u+x ~/esm/24.2.2/scripts/transformation/updateAutopassKey.sh
   
   ```
</details>

---

#### Pre-requisites  
<details><summary>Pre-requisites</summary>  

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

**_When prompted: Press 'y' to proceed with the sync copy_**  
```
sudo ~/esm/24.2.2/scripts/transformation/syncData.sh \
--globalVolumePath /mnt/efs/var/vols/itom/itsma/global-volume \
--smartanalyticsVolumePath /mnt/efs/var/vols/itom/itsma/smartanalytics-volume \
--configVolumePath /mnt/efs/var/vols/itom/itsma/config-volume

```

> Get Basic environment Helm values  

   *_When prompted: Press 'y' to use the discovered itsma namespace__*  

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

> Get current Alertmanager settings  

   *_Perform these steps if 'Monitoring' has been deployed to the cluster_*  

   ```
   kubectl get secret -n core alertmanager-itom-prometheus-alertmanager -o json | jq -r '.data."alertmanager.yaml"' | base64 -d > ~/esm/alert-manager.yml
   
   ```
   *_Verify details of Alertmanager ConfigMap before contiuning . . ._*  
   ```
   cat ~/esm/alert-manager.yml
   
   ```

> Get current INGRESS for SMA
```
kubectl get ing -n $NS sma-ingress -o yaml > ~/esm/sma-ingress.yml
kubectl get ing -n $NS sma-integration-ingress -o yaml > ~/esm/sma-integration-ingress.yml

```
*_Verify details of INGRESS before contiuning . . ._*  
```
cat ~/esm/sma-ingress.yml

```
```
cat ~/esm/sma-integration-ingress.yml

```
</details>

---

#### ESM Helm Transformation  
<details><summary>SMAX metadata to ESM Helm Transformation</summary>  

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
VAULT_PATH=$(kubectl get pv itom-vol -o json | jq -r .spec.nfs.path)
sudo cp -R /mnt/efs${VAULT_PATH}/vault /mnt/efs/var/vols/itom/itsma/global-volume/
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
watch -n 10 'kubectl get pods -n core|grep -v -E "1/1|2/2|3/3|4/4|Completed'

```
</details>

---

#### Deploy ESM Helm chart  
<details><summary>Deploy ESM Helm Chart</summary>  

```
$CDF_HOME/bin/helm install sma ~/esm/24.2.2/charts/esm-1.0.2+24.2.2-18.tgz -n $NAMESPACE --set global.nodeSelector.Worker=label -f  ~/esm/customized_values.yaml -f ~/esm/values.yaml
```

**_After helm deployment completes, ensure SMAX is up and running and healthy before continuing_**

```
watch -n 10 'kubectl get pods -n ${NAMESPACE}|grep -v -E "1/1|2/2|3/3|4/4|Completed'

```
> Redeploy sma-ingress
```
kubectl create -f ~/esm/sma-ingress.yml; \
kubectl create -f ~/esm/sma-integration-ingress.yml

```
> Update helm autopass
```
~/esm/24.2.2/scripts/transformation/updateAutopassKey.sh -n $NAMESPACE

```
</details>

---

### Post Transform Tasks  
<details><summary>Post Transformation Tasks</summary>  

#### Re-Install ITOM Toolkit  
> Create working directory for Toolkit Framework  
```
mkdir -p ~/toolkit/24.3 

```

> Download and extract Toolkit  
```
curl -gkLs https://owncloud.gitops.com/index.php/s/Q91ZKRmLTcCDKce/download -o ~/toolkit/24.3/itom-toolkit-framework-24.3.tar.gz
tar -zxvf ~/toolkit/24.3/itom-toolkit-framework-24.3.tar.gz -C ~/toolkit/24.3/
chmod a+x ~/toolkit/24.3/toolkit_framework/install.sh

```

> Install Toolkit
> **_NOTE: You must execute the install.sh from the toolkit_framework directory or paths will not line up_**
```
cd ~/toolkit/24.3/toolkit_framework/
./install.sh

```

#### Cleanup unused OMT resources  
> Drop unused Apphub features  
```
sudo chmod g+rx ${CDF_HOME}/charts
sudo chmod g+rw ${CDF_HOME}/charts/*

APPHUB_CHART=$(cd ${CDF_HOME}/charts && ls apphub-1*.tgz) && echo ${APPHUB_CHART}

helm upgrade apphub $CDF_HOME/charts/${APPHUB_CHART} --reuse-values --set global.services.suiteDeploymentManagement=false -n core

```

> Delete unused SMAX metadata pods  
```
kubectl delete deploy suite-conf-pod-itsma -n core --ignore-not-found=true
kubectl delete svc suite-conf-svc-itsma  -n core --ignore-not-found=true
kubectl delete ingress suite-conf-ing-itsma -n core --ignore-not-found=true

```

> Delete :3000 Ingress
```
kubectl delete ingress -n core -l app=install-ingress

```

#Reconfigure monitoring
</details>

---

##### End of Doc  