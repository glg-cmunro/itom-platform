# Step by Step - Deploy ITOM Cluster capability - OO Containerized - 2022.11
![GreenLight Group Logo](https://assets.website-files.com/5ebcb9396faf10d8f7644479/5ed6a066891af295a039860f_GLGLogolrg-p-500.png)

---

## Deployment Steps
 > - Backup Cluster before making ANY changes
 > - Download and Extract OO helm charts
 > - Create OO Deployment in OMT
 > - Prepare NFS/EFS directories for OO PVs
 >   - Prepare PV / PVC for OO
 > - Create Databases for OO
 > - Create IDM Admin account for OO
 > - Prepare oo-secrets
 > - 
 > - Download and Extract OO Patch 3 helm charts
 
## Install OO Containerized - 2022.11

### Backup Cluster and SUITE before making any changes  
> [AWS Backup Cluster](./AWS_BackupCluster.md)
    
### Download and extract OO Charts  
```
mkdir ~/oo
```

> OO_2022.11
```
curl -kLs https://owncloud.gitops.com/index.php/s/PEPTDATZ0sOItVm/download -o ~/oo/oo-1.0.3-20221101.8.zip
unzip ~/oo/oo-1.0.3-20221101.8.zip -d ~/oo/2022.11
```

### Create OO Deployment in OMT
```
/opt/smax/2022.11/scripts/cdfctl.sh deployment create -d oo -n oo
```

### Prepare NFS/EFS directories for OO PVs
```
sudo mkdir -p /mnt/efs/var/vols/itom/oo/oo_config_vol
sudo mkdir -p /mnt/efs/var/vols/itom/oo/oo_data_vol
sudo mkdir -p /mnt/efs/var/vols/itom/oo/oo_logs_vol
sudo mkdir -p /mnt/efs/var/vols/itom/oo/oo_data_export_vol
sudo mkdir -p /mnt/efs/var/vols/itom/oo/oo_ras_logs_vol
sudo chmod -R 775 /mnt/efs/var/vols/itom/oo
sudo chown -R 1999:1999 /mnt/efs/var/vols/itom/oo
```

### Prepare PV / PVC for OO  
> Edit oo-pv.yaml with proper cluster specific EFS_Host, EFS_Path, StorageClassName information
> - EFS_Host = NFS server used by cluster
> - EFS_Path = /var/vols/itom/oo/<volume>
> - StorageClassName = "itom-oo"

```
export CLUSTER_NAME=qa
cp ~/oo/2022.11/oo-1.0.3+20221101.8/oo-helm-charts/samples/persistent_storage/eks/volumes.yaml ~/oo/${CLUSTER_NAME}_oo-pv.yaml
vi ~/oo/${CLUSTER_NAME}_oo-pv.yaml
```

```
kubectl create -f ~/oo/${CLUSTER_NAME}_oo-pv.yaml
```

> Edit oo-pvc (one for all environments) with proper StorageClassName "itom-oo"
> - StorageClassName = "itom-oo"
```
cp ~/oo/2022.11/oo-1.0.3+20221101.8/oo-helm-charts/samples/persistent_storage/eks/claims.yaml ~/oo/oo-pvc.yaml
vi ~/oo/oo-pvc.yaml
```

```
kubectl create -f ~/oo/oo-pvc.yaml
```

### Create Databases for OO
```
export PGHOST=`kubectl get cm -n core default-database-configmap -ojson | jq -r .data.DEFAULT_DB_HOST`
export PGUSER=`kubectl get cm -n core default-database-configmap -ojson | jq -r .data.DEFAULT_DB_USERNAME`
export PGDATABASE=postgres
psql -W
```

> <CREATE DB SCRIPT>
```    
CREATE ROLE "oocentraldbuser" LOGIN ENCRYPTED PASSWORD 'Gr33nl1ght_' NOSUPERUSER INHERIT;
CREATE DATABASE "oocentraldb"; 
ALTER DATABASE "oocentraldb" OWNER TO "oocentraldbuser";
CREATE ROLE "oouidbuser" LOGIN ENCRYPTED PASSWORD 'Gr33nl1ght_' NOSUPERUSER INHERIT;
CREATE DATABASE "oouidb"; 
ALTER DATABASE "oouidb" OWNER TO "oouidbuser";
CREATE ROLE "oocontrollerdbuser" LOGIN ENCRYPTED PASSWORD 'Gr33nl1ght_' NOSUPERUSER INHERIT;
CREATE DATABASE "oocontrollerdb"; 
ALTER DATABASE "oocontrollerdb" OWNER TO "oocontrollerdbuser";
CREATE ROLE "ooscheduler" LOGIN ENCRYPTED PASSWORD 'Gr33nl1ght_' NOSUPERUSER INHERIT;
CREATE DATABASE "ooschedulerdb"; 
ALTER DATABASE "ooschedulerdb" OWNER TO "ooscheduler";
CREATE ROLE "aplsdbuser" LOGIN ENCRYPTED PASSWORD 'Gr33nl1ght_' NOSUPERUSER INHERIT;
CREATE DATABASE "aplsdb"; 
ALTER DATABASE "aplsdb" OWNER TO "aplsdbuser";
\q
```

> Add the SCHEMA for oo_sch_core (Must be the ooscheduler user)
```
psql -U ooscheduler -d ooschedulerdb -W
```

```
CREATE SCHEMA IF NOT EXISTS oo_sch_core AUTHORIZATION ooscheduler;
\q
```
    
### Create IDM Admin account for OO
> Login to the SUITE IDM Admin service  
> https://<Cluster FQDN>:443/idm-admin  
> > https://smax-west.gitops.com/idm-admin  
> > https://testing.dev.gitops.com/idm-admin  

Username: oo-integration-admin  
Display Name: OO Integration Admin  
Pass: <Keep track of this for the oo-secrets>  

> Add IDM Admin account for OO to administrators group
    
### Prepare oo-secrets
> You will need to gather the current values from the system for the Signing Key and Transpot Pass  
```
export SMAX_IDM_POD=$(echo `kubectl get pods -n $NS | grep -m1 idm- | head -1 | awk '{print $1}'`) && echo $SMAX_IDM_POD
```
```
export IDM_SIGNING_KEY=$(kubectl exec -it $SMAX_IDM_POD -n $NS -c idm -- bash -c "/bin/get_secret idm_token_signingkey_secret_key itom-bo" | awk -F= '{print$2}') 
```
```
export TRANSPORT_PASS=$(kubectl exec -it $SMAX_IDM_POD -n $NS -c idm -- bash -c "/bin/get_secret idm_transport_admin_password_secret_key" | awk -F= '{print$2}')
```
```
echo $IDM_SIGNING_KEY; echo $TRANSPORT_PASS;
```    

> You will need the IDM_SIGNING_KEY and TRANSPORT_PASS for this next step
- Generate OO secrets
```
/opt/smax/2022.11/scripts/gen_secrets.sh -n oo -c ~/oo/2022.11/oo-1.0.3+20221101.8/oo-helm-charts/charts/oo-1.0.3+20221101.8.tgz -o ~/oo/oo_secrets.yaml
```    

- Create OO Values
```
cp ~/oo/2022.11/oo-1.0.3+20221101.8/oo-helm-charts/samples/sizing/oo_default_sizing.yaml ~/oo/oo_size_values.yaml
#vi ~/oo/oo_size_values.yaml
```

```
cd ~/oo
tar -zxvf ./2022.11/oo-1.0.3+20221101.8/oo-helm-charts/charts/oo-1.0.3+20221101.8.tgz --directory=./2022.11/oo-1.0.3+20221101.8/oo-helm-charts/charts/
cp ~/oo/2022.11/oo-1.0.3+20221101.8/oo-helm-charts/charts/oo/values.yaml  ~/oo/${CLUSTER_NAME}_oo-values.yaml
vi ~/oo/${CLUSTER_NAME}_oo-values.yaml
```
> - global.acceptEula: true
> - global.isDemo: false
> - global.externalAccessHost: <CLUSTER_NAME>-oo.<DOMAIN>
> - global.externalAccessPort: 443
> - global.nginx.httpsPort: 443
> - global.cluster.k8sProvider: aws
> - global.persistence.enabled: true
> - global.persistence.configVolumeClaim: oo-config-pvc
> - global.persistence.dataVolumeClaim: oo-data-pvc
> - global.persistence.logVolumeClaim: oo-logs-pvc
> - global.persistence.rasLogVolumeClaim: oo-ras-logs-pvc
> - global.persistence.dataExportVolumeClaim: oo-data-export-pvc
> - global.persistence.storageClasses.ooGlobalStorageClassName: "itom-oo" 
> - global.docker.registry: <ECR REPO URL>
> - global.database.type: postgresql
> - global.database.host: <RDS Instance FQDN>
> - global.database.port: 5432
> - global.idm.idmAuthUrl: <SMAX Integration FQDN>:2443/idm-service
> - global.idm.idmServiceUrl: <SMAX FQDN>:443/idm-service
> - global.smaxFqdn: <SMAX FQDN>

### Install OO
```
/opt/smax/2022.11/bin/helm install oo ~/oo/2022.11/oo-1.0.3+20221101.8/oo-helm-charts/charts/oo-1.0.3+20221101.8.tgz --namespace oo -f ~/oo/qa_oo-values.yaml -f ~/oo/oo_size_values.yaml -f ~/oo/oo_secrets.yaml
```

```
/opt/smax/2022.11/bin/helm upgrade oo ~/oo/2022.11/oo-1.0.3+20221101.8/oo-helm-charts/charts/oo-1.0.3+20221101.8.tgz --namespace oo --reuse-values -f ~/oo/qa_oo-values.yaml
```
    helm install oo ~/oo/2022.11/oo-1.0.3+20221101.8/oo-helm-charts/charts/oo-1.0.3+20221101.8.tgz --namespace oo -f ~/oo/testing_oo-values.yaml -f ~/oo/oo_size_values.yaml
    helm install oo ~/oo/oo_chart/oo-1.0.3+20221101.8/oo-helm-charts/charts/oo-1.0.3+20221101.8.tgz --namespace oo -f oo_values.smax-west.yaml -f oo_size_values.yaml
    helm upgrade oo ~/oo/oo_chart/oo-1.0.3+20221101.8/oo-helm-charts/charts/oo-1.0.3+20221101.8.tgz --reuse-values --namespace oo -f ~/oo_values.optic.yaml -f ~/oo_size_values.yaml
    helm upgrade oo ~/oo/oo_chart/oo-1.0.3+20221101.8/oo-helm-charts/charts/oo-1.0.3+20221101.8.tgz --reuse-values --namespace oo -f ~/oo_values.smax-west.yaml -f ~/oo_size_values.yaml
    
    #Add oo-ingress for LoadBalancer
    kubectl create -f ~/oo-ingress.yaml

    helm upgrade oo ~/oo/oo_chart/oo-1.0.3+20221101.8/oo-helm-charts/charts/oo-1.0.3+20221101.8.tgz --reuse-values --namespace oo --set-file "caCertificates.oo_lb\.crt"=~/oo/testing_lb.crt --set-file "caCertificates.integration_lb\.crt"=~/oo/testing_lb.crt

    ##Install OO 2022.05.P1
    curl -k https://owncloud.gitops.com/index.php/s/Bbo8xNuDHQtWim6/download -o ~/oo-helm-charts-1.0.2+20220501P1-1.zip
    unzip ~/oo-helm-charts-1.0.2+20220501P1-1.zip -d ~/oo_2022.05.P1
    APLSDBNAME=$(echo `/opt/cdf/bin/yq e '.autopass.deployment.database.dbName' ~/oo_values.smax-west.yaml`) && echo $APLSDBNAME
    APLSDBUSER=$(echo `/opt/cdf/bin/yq e '.autopass.deployment.database.user' ~/oo_values.smax-west.yaml`) && echo $APLSDBUSER
    /opt/cdf/bin/yq e '.autopass-migration.deployment.database.dbName = "'${APLSDBNAME}'"' -i ~/oo_2022.05.P1/oo-1.0.2+20220501P1-1/oo-helm-charts/values/202205_P1.yaml
    /opt/cdf/bin/yq e '.autopass-migration.deployment.database.user = "'${APLSDBUSER}'"' -i ~/oo_2022.05.P1/oo-1.0.2+20220501P1-1/oo-helm-charts/values/202205_P1.yaml
    /opt/cdf/bin/yq e '.global.idm.idmServiceUrl = "https://smax-west.gitops.com:443/idm-service"' -i ~/oo_2022.05.P1/oo-1.0.2+20220501P1-1/oo-helm-charts/values/202205_P1.yaml
    helm upgrade oo -n oo --reuse-values -f ~/oo_2022.05.P1/oo-1.0.2+20220501P1-1/oo-helm-charts/values/202205_P1.yaml ~/oo_2022.05.P1/oo-1.0.2+20220501P1-1/oo-helm-charts/charts/oo-1.0.2+20220501P1.1.tgz --timeout 30m


    ## Upgrade OO 2022.11.P3
    curl -gkLs https://owncloud.gitops.com/index.php/s/mvm0f4n2CwJ45Ia/download -o ~/oo/oo-helm-charts-1.0.3-20221101P3.1.zip
    unzip ~/oo/oo-helm-charts-1.0.3-20221101P3.1.zip -d ~/oo/oo_2022.11.P3
    /opt/smax/2022.11/bin/helm get values -n oo oo > ~/oo/oo_2022.11-values.yaml
    cp ~/oo/oo_2022.11-values.yaml ~/oo/oo_2022.11.P3-values.yaml
    
    /opt/smax/2022.11/bin/yq eval 'del(.global.busybox)' -i ~/oo/oo_2022.11.P3-values.yaml
    /opt/smax/2022.11/bin/yq eval 'del(.global.opensuse)' -i ~/oo/oo_2022.11.P3-values.yaml
    /opt/smax/2022.11/bin/yq eval 'del(.global.vaultRenew)' -i ~/oo/oo_2022.11.P3-values.yaml
    /opt/smax/2022.11/bin/yq eval 'del(.global.vaultInit)' -i ~/oo/oo_2022.11.P3-values.yaml
    /opt/smax/2022.11/bin/yq eval 'del(.. | select(has("image")).image)' -i ~/oo/oo_2022.11.P3-values.yaml
    /opt/smax/2022.11/bin/yq eval 'del(.. | select(has("imageTag")).imageTag)' -i ~/oo/oo_2022.11.P3-values.yaml
    /opt/smax/2022.11/bin/yq eval 'del(.ootenants-sync.version)' -i ~/oo/oo_2022.11.P3-values.yaml

    /opt/smax/2022.11/bin/yq eval '.global.idm.idmServiceUrl = "https://testing-int.dev.gitops.com:2443/idm-service"' -i ~/oo/oo_2022.11.P3-values.yaml

    APLSDBNAME=$(echo `/opt/smax/2022.11/bin/yq eval '.autopass.deployment.database.dbName' ~/oo/oo_2022.11.P3-values.yaml`) && echo $APLSDBNAME
    APLSDBUSER=$(echo `/opt/smax/2022.11/bin/yq eval '.autopass.deployment.database.user' ~/oo/oo_2022.11.P3-values.yaml`) && echo $APLSDBUSER
    APLSMIGRATIONDBNAME=$(echo `/opt/smax/2022.11/bin/yq eval '.autopass-migration.deployment.database.dbName' ~/oo/oo_2022.11.P3-values.yaml`) && echo $APLSMIGRATIONDBNAME 
    APLSMIGRATIONDBUSER=$(echo `/opt/smax/2022.11/bin/yq eval '.autopass-migration.deployment.database.user' ~/oo/oo_2022.11.P3-values.yaml`) && echo $APLSMIGRATIONDBUSER
    [[ $APLSDBNAME == $APLSMIGRATIONDBNAME ]] && echo "Values of autopass db name and autopass migration db name is same. "
    [[ $APLSDBUSER == $APLSMIGRATIONDBUSER ]] && echo "Values of autopass db user and autopass migration db user is same. "

    /opt/smax/2022.11/bin/yq eval '.autopass-migration.deployment.database.dbName = "'${APLSDBNAME}'"' -i ~/oo/oo_2022.11.P3-values.yaml
    /opt/smax/2022.11/bin/yq eval '.autopass-migration.deployment.database.user = "'${APLSDBUSER}'"' -i ~/oo/oo_2022.11.P3-values.yaml

    helm upgrade oo -n oo ~/oo/oo_2022.11.P3/oo-helm-charts-1.0.3-20221101P3.1/oo-helm-charts/charts/oo-1.0.3+20221101P3.1.tgz -f ~/oo/oo_2022.11.P3-values.yaml --set global.deploymentType="upgrade" --set global.secretStorageType="null" --timeout 30m

    helm upgrade oo -n oo ~/oo/oo_2022.11.P3/oo-helm-charts-1.0.3-20221101P3.1/oo-helm-charts/charts/oo-1.0.3+20221101P3.1.tgz -f ~/oo/oo_2022.11.P3-values.yaml --set global.deploymentType="install" --set global.secretStorageType="null" --timeout 30m

### Download and extract OO Charts  
> OO_2022.11.P3
```
curl -kLs https://owncloud.gitops.com/index.php/s/mvm0f4n2CwJ45Ia/download -o ~/oo/oo-helm-charts-1.0.3-20221101P3.1.zip
unzip ~/oo/oo-helm-charts-1.0.3-20221101P3.1.zip -d ~/oo/2022.11.P3
```

##### Enable OO RAS and Designer downloads from Endpoint Manager
[OpenText DOC: Customize OO Download Link](https://docs.microfocus.com/doc/SMAX/2022.11/CustomizeOODownloadLinks)
> NOTE: Requires SMA Toolkit  
Example used for testing.dev.gitops.com
```
python3 ~/toolkit/enable_download/enable_download.py testing.dev.gitops.com 462039570 bo-integration@dummy.com Gr33nl1ght_ https://testing-oo.dev.gitpps.com:443/oo/downloader OO_DOWNLOAD_SERVICE
```

##### Install OO RAS Server (External RAS)
- NOTE: CMS Gateway (RAS Server) needs xorg-x11-auth, bzip2, gtk2 packages installed for OO RAS Installer
