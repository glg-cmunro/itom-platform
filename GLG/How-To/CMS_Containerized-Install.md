# Installation instructions for CMS Containerized in SMAX cluster

1. CMS install working directory
    ```
    mkdir ~/cms
    cd ~/cms
    ```

2. Download / Extract CMS Helm chart package  
    ```
    curl -kLs https://owncloud.gitops.com/index.php/s/ipLquypHVdCsaii/download -o ~/cms/CMS_Helm_Chart-2022.11.zip
    unzip CMS_Helm_Chart-2022.11.zip -d ~/cms
    tar -zxvf ~/cms/CMS_Helm_Chart-2022.11/cms-helm-charts-2022.11.tgz -C ~/cms
    ```
cp ~/cms/cms-helm-charts/samples/values-with-smax.yaml ~/cms/testing_cms-values-with-smax.yaml
cp ~/cms/cms-helm-charts/samples/cms-pv.yaml ~/cms/testing_cms-pv.yaml
cp ~/cms/cms-helm-charts/samples/values-probe.yaml ~/cms/testing_cms-values-probe.yaml

##### one-time get required cms images
$CDF_HOME/scripts/refresh-ecr-secret.sh -r us-east-1
$CDF_HOME/tools/generate-download/generate_download_bundle.sh --chart ~/cms/cms-helm-charts/charts/cms-1.7.0+20221100.256.tgz -o hpeswitom -d ~/cms/cms_images
unzip ~/cms/cms_images/offline-download.zip -d ~/cms/cms_images
 > copy image-set.json to BYOK folder for Ansible

ansible-playbook /opt/glg/aws-smax/ansible/playbooks/aws-config-smax-images.yaml --ask-vault-pass -e image_set_file=/opt/glg/aws-smax/BYOK/2022.11/2022.11_cms-image-set.json -e region=us-east-1

3. Create EFS directories for CMS  
    ```
    sudo mkdir -p /mnt/efs/var/vols/itom/cms/data
    sudo mkdir -p /mnt/efs/var/vols/itom/cms/conf
    sudo mkdir -p /mnt/efs/var/vols/itom/cms/log
    sudo chmod -R 775 /mnt/efs/var/vols/itom/cms
    sudo chown -R 1999:1999 /mnt/efs/var/vols/itom/cms
    ```

4. Create RDS PostgreSQL Databases for CMS
    ```
    export PGHOST=$(kubectl get cm -n core default-database-configmap -o json | jq -r .data.DEFAULT_DB_HOST)
    export PGUSER=$(kubectl get cm -n core default-database-configmap -o json | jq -r .data.DEFAULT_DB_USERNAME)
    export PGPASSWORD=Gr33nl1ght_

    psql -d postgres
    
    CREATE USER cms_ucmdb PASSWORD 'Gr33nl1ght_';
    GRANT cms_ucmdb to dbadmin;
    CREATE DATABASE cms_ucmdb_db OWNER cms_ucmdb;
    
    CREATE USER cms_autopass PASSWORD 'Gr33nl1ght_';
    GRANT cms_autopass to dbadmin;
    CREATE DATABASE cms_autopass_db OWNER cms_autopass; 
    
    \c cms_ucmdb_db
    CREATE SCHEMA ucmdb AUTHORIZATION cms_ucmdb;
    ALTER USER cms_ucmdb SET search_path TO ucmdb;

    \c cms_autopass_db
    CREATE SCHEMA autopass AUTHORIZATION cms_autopass;
    ALTER USER cms_autopass SET search_path TO autopass;

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
  /opt/smax/2022.11/scripts/gen_secrets.sh -n cms -c ~/cms/cms-helm-charts/charts/cms-1.7.0+20221100.256.tgz -o ~/cms/testing_cms-secrets.yaml
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
  > CMS Master Key = Gr33nL1ghtGroupMasterKey_CMSPass

9. HELM Install CMS
  ```
  /opt/smax/2022.11/bin/helm install cms ~/cms/cms-helm-charts/charts/cms-1.7.0+20221100.256.tgz --namespace cms -f ~/cms/testing_cms-secrets.yaml -f ~/cms/testing_cms-values-with-smax.yaml
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

