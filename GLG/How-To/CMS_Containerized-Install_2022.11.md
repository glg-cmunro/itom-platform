# Step by Step - Deploy ITOM Cluster capability - CMS Containerized - 2022.11
![GreenLight Group Logo](https://assets.website-files.com/5ebcb9396faf10d8f7644479/5ed6a066891af295a039860f_GLGLogolrg-p-500.png)

---

## Deployment Steps
> - Create CMS Install Working Directory
> - Download / Extract CMS helm chart package
> - Prepare EFS / NFS directories for CMS
> - Prepare CMS helm chart values
> - Create CMS Databases in RDS Instance
> - Create CMS Integration Admin user in SMAX IdM
> - Create OMT Deployment for CMS
> - Generate CMS vault secrets
> - Install CMS
> - Associate CMS SuperAdmin role

## Installation instructions for CMS Containerized in SMAX cluster

> Environment Variables to assist with installation
```
export CLUSTER_NAME=qa
export CDF_HOME=/opt/cdf
export CDF_NAMESPACE=core
export ECR_REPO=`kubectl get deployment -n $NS idm -o json | jq -r .spec.template.spec.containers[0].image | awk -F/ {'print $1'}`
```

1. Create CMS Install Working Directory
```
mkdir -p ~/cms/2022.11
cd ~/cms
```

2. Download / Extract CMS helm chart package  
```
curl -kLs https://owncloud.gitops.com/index.php/s/ipLquypHVdCsaii/download -o ~/cms/CMS_Helm_Chart-2022.11.zip
unzip ~/cms/CMS_Helm_Chart-2022.11.zip -d ~/cms
tar -zxvf ~/cms/CMS_Helm_Chart-2022.11/cms-helm-charts-2022.11.tgz -C ~/cms/2022.11
```

- Edit Environment Specific PV YAML
```
cp ~/cms/2022.11/cms-helm-charts/samples/cms-pv.yaml ~/cms/${CLUSTER_NAME}_cms-pv.yaml
vi ~/cms/${CLUSTER_NAME}_cms-pv.yaml
```
> - cms-config-volume.nfs.path: /var/vols/itom/cms/conf
> - cms-config-volume.nfs.server: <EFS Resource FQDN>
> - cms-config-volume.storageClassName: "itom-cms"
> - cms-data-volume.nfs.path: /var/vols/itom/cms/data
> - cms-data-volume.nfs.server: <EFS Resource FQDN>
> - cms-data-volume.storageClassName: "itom-cms"
> - cms-log-volume.nfs.path: /var/vols/itom/cms/log
> - cms-log-volume.nfs.server: <EFS Resource FQDN>
> - cms-log-volume.storageClassName: "itom-cms"

##FUTURE_STATE cp ~/cms/2022.11/cms-helm-charts/samples/values-probe.yaml ~/cms/${CLUSTER_NAME}_cms-values-probe.yaml

3. Prepare EFS / NFS directories for CMS
```
sudo mkdir -p /mnt/efs/var/vols/itom/cms/data
sudo mkdir -p /mnt/efs/var/vols/itom/cms/conf
sudo mkdir -p /mnt/efs/var/vols/itom/cms/log
sudo chmod -R 775 /mnt/efs/var/vols/itom/cms
sudo chown -R 1999:1999 /mnt/efs/var/vols/itom/cms
```
    
```
kubectl create -f ~/cms/${CLUSTER_NAME}_cms-pv.yaml
```

4. Create RDS PostgreSQL Databases for CMS
```
export PGHOST=$(kubectl get cm -n core default-database-configmap -o json | jq -r .data.DEFAULT_DB_HOST);
export PGUSER=$(kubectl get cm -n core default-database-configmap -o json | jq -r .data.DEFAULT_DB_USERNAME);
export PGPASSWORD=Gr33nl1ght_

psql -d postgres
```

```
CREATE USER cms_ucmdb PASSWORD 'Gr33nl1ght_';
GRANT cms_ucmdb to dbadmin;
CREATE DATABASE cms_ucmdb_db OWNER cms_ucmdb;

CREATE USER cms_autopass PASSWORD 'Gr33nl1ght_';
GRANT cms_autopass to dbadmin;
CREATE DATABASE cms_autopass_db OWNER cms_autopass; 

CREATE USER cms_probe PASSWORD 'Gr33nl1ght_';
GRANT cms_probe to dbadmin;
CREATE DATABASE cms_probe_db OWNER cms_probe;

\c cms_ucmdb_db
CREATE SCHEMA ucmdb AUTHORIZATION cms_ucmdb;
ALTER USER cms_ucmdb SET search_path TO ucmdb;

\c cms_autopass_db
CREATE SCHEMA autopass AUTHORIZATION cms_autopass;
ALTER USER cms_autopass SET search_path TO autopass;

\c cms_probe_db
CREATE SCHEMA probe AUTHORIZATION cms_probe;
ALTER USER cms_probe SET search_path TO probe;

\q
```

5. Create CMS Integration Admin
> Login to IDM-Admin service for SYSBO Organization
> Create SYSTEM user = cms-integration-admin
> Add cms-integration-admin to Administrators Group

6. Set values in cms-values.yaml
  > global.externalAccessHost: <cluster>-cms.<domain> (testing-cms.dev.gitops.com)
  > global.externalAccessPort: 443
  > ADD :: global.k8sProvider: aws
  > 
```
cp ~/cms/2022.11/cms-helm-charts/samples/values-with-smax.yaml ~/cms/${CLUSTER_NAME}_cms-values.yaml
vi ~/cms/${CLUSTER_NAME}_cms-values.yaml
```
> - global.acceptEula: true
> - global.externalAccessHost: <CLUSTER_NAME>-oo.<DOMAIN>
> - global.externalAccessPort: 443
> - ADD:: global.k8sProvider: aws
> - global.docker.registry: <AWS ECR Repository for CLUSTER>
> - global.idm.idmAuthUrl: <CLUSTER_NAME>.<DOMAIN>:443/idm-service
> - global.idm.idmServiceUrl: <CLUSTER_NAME>-int.<DOMAIN>:2443/idm-service
> - global.idm.idmIntegrationAdmin: cms-integration-admin
> - global.database.host: <CLUSTER RDS Instance FQDN>
> - global.database.port: 5432
> - global.database.type: postgresql
> - global.database.tlsEnabled: false
> - global.persistence.dataVolumeStorageClassName: itom-cms
> - global.persistence.configVolumeStorageClassName: itom-cms
> - global.persistence.logVolumeStorageClassName: itom-cms
> - ucmdbserver.deployment.database.user: cms_ucmdb
> - ucmdbserver.deployment.database.dbName: cms_ucmdb_db
> - ucmdbserver.deployment.database.schema: ucmdb
> - autopass.deployment.database.user: cms_autopass
> - autopass.deployment.database.dbName: cms_autopass_db
> - autopass.deployment.database.schema: autopass
> - ucmdbprobe.deployment.database.user: cms_probe
> - ucmdbprobe.deployment.database.dbName: cms_probe_db
> - ucmdbprobe.deployment.database.schema: probe
> - ucmdbprobe.deployment.discoverCloud: true
> - itom-ingress-controller.nginx.service.httpsPort: 30443
> - ADD:: itom-ingress-controller.nginx.service.external.type: NodePort
> - cmsGateway.deployment.smax.host: <CLUSTER_NAME>-int.<DOMAIN>
> - cmsGateway.deployment.smax.port: 2443
> - cmsGateway.deployment.sam.host: <CLUSTER_NAME>-int.<DOMAIN>
> - cmsGateway.deployment.sam.port: 2443
> - cmsGateway.deployment.sam.context: <CLUSTER_NAME>-int.<DOMAIN>

7. Create OMT Deployment for CMS
  ```
  /opt/smax/2022.11/bin/cdfctl deployment create -t helm -d cms -n cms
  ```
  Check the OMT Deployments
  ```
  /opt/smax/2022.11/bin/cdfctl deployment get
  ```

8. Generate CMS vault secrets
  ```
  /opt/smax/2022.11/scripts/gen_secrets.sh -n cms -c ~/cms/2022.11/cms-helm-charts/charts/cms-1.7.0+20221100.256.tgz -o ~/cms/testing_cms-secrets.yaml
  ```
  > `export ITOM_BO_UI_POD=$(kubectl get pods -n $NS | grep -m1 itom-bo-login | awk '{print $1}')`
  > Get IDM Signing Key from /BO
    ```
    IDM_SIGNING=$(kubectl exec -it ${ITOM_BO_UI_POD} -n $NS -c itom-bo-login -- bash -c "/bin/get_secret idm_token_signingkey_secret_key itom-bo")
    IDM_SIGNING_KEY=$(echo -n $IDM_SIGNING|base64)
    echo $IDM_SIGNING
    ```
  > Get SSO Init String from /BO
    ```
    HPSSO_INIT_STRING=$(kubectl exec -it ${ITOM_BO_UI_POD} -n $NS -c itom-bo-login -- bash -c "/bin/get_secret lwsso_init_string_secret_key itom-bo")
    HPSSO_INIT_STRING_KEY=$(echo -n $HPSSO_INIT_STRING|base64)
    echo $HPSSO_INIT_STRING
    ```
  > Get IDM Transport User Password
    ```
    IDM_TRANSPORT_USER_PASSWORD=$(kubectl exec -it ${ITOM_BO_UI_POD} -n $NS -c itom-bo-login -- bash -c "/bin/get_secret idm_transport_user_password_secret_key itom-idm")
    IDM_TRANSPORT_USER_PASSWORD_KEY=$(echo -n $IDM_TRANSPORT_USER_PASSWORD|base64)
    echo $IDM_TRANSPORT_USER_PASSWORD
    ```
  > CMS Master Key = Gr33nL1ghtGroupMasterKey_202211

*IMPORTANT* After createing secrets file you need to update it for the shared idm - MF script and steps found @ https://docs.microfocus.com/doc/SMAX/2022.11/CmsGenerateVaultEks

ADD kubernetes resource detail and kubectl create secret


9. HELM Install CMS
  ```
  /opt/smax/2022.11/bin/helm install cms ~/cms/2022.11/cms-helm-charts/charts/cms-1.7.0+20221100.256.tgz --namespace cms -f ~/cms/${CLUSTER_NAME}_cms-secrets.yaml -f ~/cms/${CLUSTER_NAME}_cms-values.yaml
  ```

10. Create CMS Ingress (Internal & External)


11. Create CMS Security Group
  ```
  aws ec2 create-security-group \
  --description "Base Security Group for End User Access to CMS" \
  --group-name "testing-SG-CMS-Base" \
  --vpc-id "vpc-0f354cb1c802be330" \
  --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=testing-SG-CMS-Base},{Key=Environment,Value=Development},{Key=Customer,Value=GITOpS},{Key=Application,Value=CMS}]" \
  --profile automation
  ```

  Get the Security Group ID output from the command above
  ```
  aws ec2 authorize-security-group-ingress \
  --group-name testing-SG-CMS-Base \
  #--group-id sg-0e1398eae02a74c5b \
  --tag-specifications "ResourceType=security-group-rule,Tags=[{Key=Environment,Value=Development},{Key=Customer,Value=GITOpS},{Key=Application,Value=CMS}]" \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0 \
  --color on \
  --profile automation
  ```

