# Environment Information  
<details open><summary>Environment Information</summary>  

> Add these variables to the environment to assist with tasks below  
## PROD Environment:  
```
EXT_ACCESS_FQDN=obm.trtc.com  
CLUSTER_NAME=BSMOBM  

VPC_ID=vpc-21efa145  
AZ1_SN=subnet-3d87114b  
AZ2_SN=subnet-96d0aff2  
AZ3_SN=subnet-fa7ca0a2  
DB1_SN=subnet-3a87114c  
DB2_SN=subnet-97d0aff3  

EFS_SG=sg-0c588cee580a7b049  
EKS_SG=sg-09304bd256473d613  
WKR_SG=sg-0736f2993f0e54781
RDS_SG=sg-0f0a7ae173043a1af  

NODE_ROLE=arn:aws:iam::365439582464:role/BSMOBMEKS-Cluster-NodeInstanceRole-T01CCAETYBOC

RDS_DATABASE=bsmobmrds-db  
RDS_HOSTNAME=$(aws rds describe-db-instances --profile bsmobm --db-instance-identifier ${RDS_DATABASE} | jq -r .DBInstances[].Endpoint.Address) && echo $RDS_HOSTNAME  
EFS_NAME="BSMOBMEFS-FS"  
EFS_ARN=$(aws efs describe-file-systems --profile bsmobm --query "FileSystems[?Name=='${EFS_NAME}'].FileSystemArn" --output text) && echo $EFS_ARN  
EFS_ID=$(aws efs describe-file-systems --profile bsmobm --query "FileSystems[?Name=='${EFS_NAME}'].FileSystemId" --output text) && echo $EFS_ID  
EFS_HOST=fs-09fbb0e8599fb487f.efs.us-west-2.amazonaws.com  
ECR_HOST=365439582464.dkr.ecr.us-west-2.amazonaws.com  
ECR_PASS=$(aws ecr get-login-password --profile bsmobm)  
CERT_ARN=$(aws acm list-certificates --profile bsmobm --query "CertificateSummaryList[?DomainName=='${EXT_ACCESS_FQDN}'].CertificateArn" --output text) && echo $CERT_ARN

```
## Maintenance Tasks
> Stop Instance
```
aws ec2 stop-instances --instance-ids i-0c359c2ea1fcae2f2 --profile bsmobm  #DR Vertica MC
```
> Start Instance
```
aws ec2 start-instances --instance-ids i-0c359c2ea1fcae2f2 --profile bsmobm  #DR Vertica MC
```
</details>

# Pre-Upgrade Activities
<details><summary>Pre-Upgrade Activities</summary>

## Backup the Database
> Using RDS_DATABASE from 'Environment Information' and SNAPSHOT_NAME below,  
> create a Database snapshot in AWS  
```
SNAPSHOT_NAME="obmprd-db-20250105"

aws rds create-db-snapshot --profile bsmobm \
 --db-snapshot-identifier="${SNAPSHOT_NAME}" \
 --db-instance-identifier="${RDS_DATABASE}"

```
## Backup Persistent Filesystem (EFS)
> Using EFS_ARN from 'Environmnet Information' and the BACKUP variables below,  
> create an AWS Backup of EFS in AWS 
```
BACKUP_DAYS=30
BACKUP_VAULT=trtc-strong-encrypted-vault
BACKUP_ROLE=arn:aws:iam::365439582464:role/service-role/AWSBackupDefaultServiceRole

aws backup start-backup-job --profile bsmobm \
 --resource-arn="${EFS_ARN}" \
 --iam-role-arn="${BACKUP_ROLE}" \
 --backup-vault-name="${BACKUP_VAULT}" \
 --lifecycle="DeleteAfterDays=${BACKUP_DAYS}"

```
## Backup K8s Cluster configuration
> Create a velero backup of the Kubernetes cluster resources 
```
VELERO_TTL=8765h
VELERO_BACKUP_NAME=obmprd-20250126  

velero backup create -n velero \
 --ttl ${VELERO_TTL} \
 ${VELERO_BACKUP_NAME}

```

## Backup Vertica DB  

</details>


## Application Upgrades

### OMT Upgrade
> Create OMT Working directory
```
mkdir -p ~/omt/24.2.P2
```

> Download / Extract OMT binaries
```
curl https://owncloud.gitops.com/index.php/s/soNXhHgmAKSqanG/download -o ~/omt/24.2.P2/OMT2422-161-15001-External-K8s.zip
unzip ~/omt/24.2.P2/OMT2422-161-15001-External-K8s.zip -d ~/omt/24.2.P2/
unzip ~/omt/24.2.P2/OMT_External_K8s_24.2.2-161.zip -d ~/omt/24.2.P2/
```

> Upload OMT container images to AWS ECR
```
ansible-playbook /opt/glg/aws-smax/ansible/playbooks/aws-config-ecr-images.yaml \
 --ask-vault-pass \
 -e region=us-west-2 \
 -e image_set_file=~/omt/24.2.P2/OMT_External_K8s_24.2.2-161/scripts/cdf-image-set.json
```

> Get OBM images from chart
```
unzip ~/obm/24.2.P1/opsbridge-suite-chart-24.2.1.zip -d ~/obm/24.2.P1/
```
```
helm get values -n obm obmprd > ~/obm/24.2.P1/obm-values.yml
$CDF_HOME/tools/generate-download/generate_download_bundle.sh -C ~/obm/24.2.P1/opsbridge-suite-chart/charts/opsbridge-suite-2.8.1+24.2.1-35.tgz -H ~/obm/24.2.P1/obm-values.yml -o hpeswitom -d ~/obm/24.2.P1/
```
```
unzip ~/obm/24.2.P1/offline-download.zip -d ~/obm/24.2.P1/

ansible-playbook /opt/glg/aws-smax/ansible/playbooks/aws-config-ecr-images.yaml \
 --ask-vault-pass \
 -e region=us-west-2 \
 -e image_set_file=~/obm/24.2.P1/offline-download/image-set.json
```

> Get NOM images from chart
```
tar -zxvf ~/nom/24.2.P1/nom-helm-charts-1.12.1.24.2.01.17.tgz -C ~/nom/24.2.P1/
```
```
helm get values -n nom nomqa > ~/nom/24.2.P1/nom-values.yml
$CDF_HOME/tools/generate-download/generate_download_bundle.sh -C ~/nom/24.2.P1/nom-helm-charts/charts/nom-1.12.1+24.2.01-17.tgz -H ~/nom/24.2.P1/nom-values.yml -o hpeswitom -d ~/nom/24.2.P1/
```
```
unzip ~/nom/24.2.P1/offline-download.zip -d ~/nom/24.2.P1/

ansible-playbook /opt/glg/aws-smax/ansible/playbooks/aws-config-ecr-images.yaml \
 --ask-vault-pass \
 -e region=us-west-2 \
 -e image_set_file=~/nom/24.2.P1/offline-download/image-set.json
```

### Execute OMT Upgrade
```
~/omt/24.2.P2/OMT_External_K8s_24.2.2-161/upgrade.sh -u

```

### Prepare Vertica Resource Pools
> On the Vertica DB Host as 'dbadmin' use vsql to search for and DROP Resource Pools
  > Resource Pools to DROP
  * itom_di_express_load_respool_provider_default
  * ro_user_pool
  * itom_monitor_respool_provider_default
  ```
  vsql -d itomdb
  
  ```
  ```
  SELECT * FROM v_monitor.resource_pool_status;

  DROP RESOURCE POOL itom_di_express_load_respool_provider_default;
  DROP RESOURCE POOL ro_user_pool;
  DROP RESOURCE POOL itom_monitor_respool_provider_default;

  ```

> On the Vertica DB Host as 'dbadmin' use vsql to create a new Resource Pool
  > Resource Pools to CREATE
  ```
  vsql -d itomdb
  
  ```
  ```
  CREATE RESOURCE POOL itom_di_aecbackground_respool_provider_default MEMORYSIZE '10%' MAXMEMORYSIZE '25%';
  
  GRANT USAGE ON RESOURCE POOL itom_di_aecbackground_respool_provider_default to vertica_rwuser WITH GRANT OPTION;
  
  ```

### Execute OBM Upgrade
> When uploading the chart you will be prompted for the admin password to continue
```
cdfctl chart upload ~/obm/24.2.P1/opsbridge-suite-chart/charts/opsbridge-suite-2.8.1+24.2.1-35.tgz -u admin

```
```
helm get values -n obm obmqa > ~/obm/obm-values_2023.05.yaml

helm upgrade -n obm obmqa ~/obm/24.2.P1/opsbridge-suite-chart/charts/opsbridge-suite-2.8.1+24.2.1-35.tgz -f ~/obm/obm-values_2023.05.yaml  --timeout 30m
```

### Execute NOM Upgrade
> When uploading the chart you will be prompted for the admin password to continue
```
cdfctl chart upload ~/nom/24.2.P1/nom-helm-charts/charts/nom-1.12.1+24.2.01-17.tgz -u admin

```
```
helm get values -n nom nomqa > ~/nom/nom-values_2023.05.yaml

#Use the AppHub UI due to SSL Certificate issues
#helm upgrade -n nom nomqa ~/nom/24.2.P1/nom-helm-charts/charts/nom-1.12.1+24.2.01-17.tgz -f ~/nom/nom-values_2023.05.yaml  --timeout 30m
```

### Upgrade Pulsar UDX Plugin
> On the Vertica DB Host copy the UDX Plugin from the opsbridge chart file
* Uninstall previous UDX Plugin  
```
/opt/vertica/bin/vsql -U dbadmin -d itomdb -f /usr/local/itom-di-pulsarudx/sql/uninstall.sql -w TRe6uMA2\$2022

```
* Stop / Re-start the Vertica DB
```
/opt/vertica/bin/admintools -t stop_db -d itomdb -p TRe6uMA2\$2022 -F

/opt/vertica/bin/admintools -t start_db -d itomdb -p TRe6uMA2\$2022

```

* Install the new UDX Plugin
```
sudo rpm -Uvh itom-di-pulsarudx-2.12.1-1.x86_64.rpm

sudo /usr/local/itom-di-pulsarudx/bin/dbinit.sh

```

### Upgrade EKS to 1.27
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM \
 -e eks_stack_name=BSMOBMEKS-Cluster \
 -e eks_version=1.27 \
 -e vpc_id=${VPC_ID} \
 -e region=us-west-2 \
 -e eks_worker_subnets=${AZ1_SN},${AZ2_SN},${AZ3_SN} \
 -e eks_security_group=${EKS_SG} \
/opt/glg/aws-obm/ansible/playbooks/aws-infra-cf-eks.yaml

```

### Upgrade EKS to 1.28
> After the upgrade to 1.27 is complete, then upgrade the cluster to 1.28
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM \
 -e eks_stack_name=BSMOBMEKS-Cluster \
 -e eks_version=1.28 \
 -e vpc_id=${VPC_ID} \
 -e region=us-west-2 \
 -e eks_worker_subnets=${AZ1_SN},${AZ2_SN},${AZ3_SN} \
 -e eks_security_group=${EKS_SG} \
/opt/glg/aws-obm/ansible/playbooks/aws-infra-cf-eks.yaml

```

### Upgrade EKS Worker nodes for each AZ
#Create EKS Nodes in separate Node Groups per AZ
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM \
 -e eks_stack_name=BSMOBMEKS-Cluster \
 -e eks_nodes_stack_name=BSMOBMEKS-Nodes-128-AZ1 \
 -e eks_version=1.28 \
 -e vpc_id=${VPC_ID} \
 -e region=us-west-2 \
 -e eks_nodes_subnets=${AZ1_SN} \
 -e eks_nodes_security_group=${WKR_SG} \
 -e eks_nodes_instance_type=m5.4xlarge \
 -e eks_nodes_ssh_key_pair_name=bsmobm-prd \
 -e eks_nodes_nodegroup_name=BSMOBM-128-workernodes-AZ1 \
 -e worker_nodes=2 \
 -e eks_nodes_instance_role=${NODE_ROLE} \
/opt/glg/aws-obm/ansible/playbooks/aws-infra-cf-eks-nodes.yaml

```
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM \
 -e eks_stack_name=BSMOBMEKS-Cluster \
 -e eks_nodes_stack_name=BSMOBMEKS-Nodes-128-AZ2 \
 -e eks_version=1.28 \
 -e vpc_id=${VPC_ID} \
 -e region=us-west-2 \
 -e eks_nodes_subnets=${AZ2_SN} \
 -e eks_nodes_security_group=${WKR_SG} \
 -e eks_nodes_instance_type=m5.4xlarge \
 -e eks_nodes_ssh_key_pair_name=bsmobm-prd \
 -e eks_nodes_nodegroup_name=BSMOBM-128-workernodes-AZ2 \
 -e worker_nodes=2 \
 -e eks_nodes_instance_role=${NODE_ROLE} \
/opt/glg/aws-obm/ansible/playbooks/aws-infra-cf-eks-nodes.yaml

```
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM \
 -e eks_stack_name=BSMOBMEKS-Cluster \
 -e eks_nodes_stack_name=BSMOBMEKS-Nodes-128-AZ3 \
 -e eks_version=1.28 \
 -e vpc_id=${VPC_ID} \
 -e region=us-west-2 \
 -e eks_nodes_subnets=${AZ3_SN} \
 -e eks_nodes_security_group=${WKR_SG} \
 -e eks_nodes_instance_type=m5.4xlarge \
 -e eks_nodes_ssh_key_pair_name=bsmobm-prd \
 -e eks_nodes_nodegroup_name=BSMOBM-128-workernodes-AZ3 \
 -e worker_nodes=2 \
 -e eks_nodes_instance_role=${NODE_ROLE} \
/opt/glg/aws-obm/ansible/playbooks/aws-infra-cf-eks-nodes.yaml

```

#Drop old workers by AZ
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM \
 -e eks_stack_name=BSMOBMEKS-Cluster \
 -e eks_nodes_stack_name=BSMOBMEKS-Nodes-AZ1 \
 -e eks_version=1.26 \
 -e vpc_id=${VPC_ID} \
 -e region=us-west-2 \
 -e eks_nodes_subnets=${AZ1_SN} \
 -e eks_nodes_security_group=${WKR_SG} \
 -e eks_nodes_instance_type=m5.4xlarge \
 -e eks_nodes_ssh_key_pair_name=bsmobm-prd \
 -e eks_nodes_nodegroup_name=BSMOBM-v126a-workernodes-AZ1 \
 -e worker_nodes=0 \
 -e eks_nodes_instance_role=${NODE_ROLE} \
 -e theState=absent \
/opt/glg/aws-obm/ansible/playbooks/aws-infra-cf-eks-nodes.yaml

```
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM \
 -e eks_stack_name=BSMOBMEKS-Cluster \
 -e eks_nodes_stack_name=BSMOBMEKS-Nodes-AZ2 \
 -e eks_version=1.26 \
 -e vpc_id=${VPC_ID} \
 -e region=us-west-2 \
 -e eks_nodes_subnets=${AZ2_SN} \
 -e eks_nodes_security_group=${WKR_SG} \
 -e eks_nodes_instance_type=m5.4xlarge \
 -e eks_nodes_ssh_key_pair_name=bsmobm-prd \
 -e eks_nodes_nodegroup_name=BSMOBM-v126a-workernodes-AZ2 \
 -e worker_nodes=0 \
 -e eks_nodes_instance_role=${NODE_ROLE} \
 -e theState=absent \
/opt/glg/aws-obm/ansible/playbooks/aws-infra-cf-eks-nodes.yaml

```
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM \
 -e eks_stack_name=BSMOBMEKS-Cluster \
 -e eks_nodes_stack_name=BSMOBMEKS-Nodes-AZ3 \
 -e eks_version=1.26 \
 -e vpc_id=${VPC_ID} \
 -e region=us-west-2 \
 -e eks_nodes_subnets=${AZ3_SN} \
 -e eks_nodes_security_group=${WKR_SG} \
 -e eks_nodes_instance_type=m5.4xlarge \
 -e eks_nodes_ssh_key_pair_name=bsmobm-prd \
 -e eks_nodes_nodegroup_name=BSMOBM-v126a-workernodes-AZ3 \
 -e worker_nodes=0 \
 -e eks_nodes_instance_role=${NODE_ROLE} \
 -e theState=absent \
/opt/glg/aws-obm/ansible/playbooks/aws-infra-cf-eks-nodes.yaml

```

### Upgrade EKS to 1.29
> After the old EKS 1.26 workers have been removed, then upgrade the cluster to 1.29
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM \
 -e eks_stack_name=BSMOBMEKS-Cluster \
 -e eks_version=1.29 \
 -e vpc_id=${VPC_ID} \
 -e region=us-west-2 \
 -e eks_worker_subnets=${AZ1_SN},${AZ2_SN},${AZ3_SN} \
 -e eks_security_group=${WKR_SG} \
/opt/glg/aws-obm/ansible/playbooks/aws-infra-cf-eks.yaml

```

### Upgrade EKS to 1.30
> After the EKS upgrade is complete, then upgrade the cluster to 1.30
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM \
 -e eks_stack_name=BSMOBMEKS-Cluster \
 -e eks_version=1.30 \
 -e vpc_id=${VPC_ID} \
 -e region=us-west-2 \
 -e eks_worker_subnets=${AZ1_SN},${AZ2_SN},${AZ3_SN} \
 -e eks_security_group=${WKR_SG} \
/opt/glg/aws-obm/ansible/playbooks/aws-infra-cf-eks.yaml

```

### Update kubectl client to match
```
curl https://s3.us-west-2.amazonaws.com/amazon-eks/1.30.4/2024-09-11/bin/linux/amd64/kubectl -o ~/kubectl
chmod a+x ~/kubectl
sudo mv ~/kubectl /usr/bin/kubectl

```

### Upgrade EKS Worker nodes for each AZ
#Create EKS Nodes in separate Node Groups per AZ
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM \
 -e eks_stack_name=BSMOBMEKS-Cluster \
 -e eks_nodes_stack_name=BSMOBMEKS-Nodes-AZ1 \
 -e eks_version=1.30 \
 -e vpc_id=${VPC_ID} \
 -e region=us-west-2 \
 -e eks_nodes_subnets=${AZ1_SN} \
 -e eks_nodes_security_group=${WKR_SG} \
 -e eks_nodes_instance_type=m6a.4xlarge \
 -e eks_nodes_ssh_key_pair_name=bsmobm-prd \
 -e eks_nodes_node_name=obmgrwnamw2lp1 \
 -e eks_nodes_nodegroup_name=BSMOBM-130-workernodes-AZ1 \
 -e worker_nodes=2 \
 -e eks_nodes_instance_role=${NODE_ROLE} \
/opt/glg/aws-obm/ansible/playbooks/aws-infra-cf-eks-nodes.yaml

```
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM \
 -e eks_stack_name=BSMOBMEKS-Cluster \
 -e eks_nodes_stack_name=BSMOBMEKS-Nodes-AZ2 \
 -e eks_version=1.30 \
 -e vpc_id=${VPC_ID} \
 -e region=us-west-2 \
 -e eks_nodes_subnets=${AZ2_SN} \
 -e eks_nodes_security_group=${WKR_SG} \
 -e eks_nodes_instance_type=m6a.4xlarge \
 -e eks_nodes_ssh_key_pair_name=bsmobm-prd \
 -e eks_nodes_node_name=obmgrwnamw2lp2 \
 -e eks_nodes_nodegroup_name=BSMOBM-130-workernodes-AZ2 \
 -e worker_nodes=2 \
 -e eks_nodes_instance_role=${NODE_ROLE} \
/opt/glg/aws-obm/ansible/playbooks/aws-infra-cf-eks-nodes.yaml

```
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM \
 -e eks_stack_name=BSMOBMEKS-Cluster \
 -e eks_nodes_stack_name=BSMOBMEKS-Nodes-AZ3 \
 -e eks_version=1.30 \
 -e vpc_id=${VPC_ID} \
 -e region=us-west-2 \
 -e eks_nodes_subnets=${AZ3_SN} \
 -e eks_nodes_security_group=${WKR_SG} \
 -e eks_nodes_instance_type=m6a.4xlarge \
 -e eks_nodes_ssh_key_pair_name=bsmobm-prd \
 -e eks_nodes_node_name=obmgrwnamw2lp3 \
 -e eks_nodes_nodegroup_name=BSMOBM-130-workernodes-AZ3 \
 -e worker_nodes=2 \
 -e eks_nodes_instance_role=${NODE_ROLE} \
/opt/glg/aws-obm/ansible/playbooks/aws-infra-cf-eks-nodes.yaml

```

#Drop old workers by AZ
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM \
 -e eks_stack_name=BSMOBMEKS-Cluster \
 -e eks_nodes_stack_name=BSMOBMEKS-Nodes-128-AZ1 \
 -e eks_version=1.28 \
 -e vpc_id=${VPC_ID} \
 -e region=us-west-2 \
 -e eks_nodes_subnets=${AZ1_SN} \
 -e eks_nodes_security_group=${WKR_SG} \
 -e eks_nodes_instance_type=m5.4xlarge \
 -e eks_nodes_node_name=obmgrwnamw2lq1 \
 -e eks_nodes_ssh_key_pair_name=bsmobm-prd \
 -e eks_nodes_nodegroup_name=BSMOBM-128-workernodes-AZ1 \
 -e worker_nodes=0 \
 -e eks_nodes_instance_role=${NODE_ROLE} \
 -e theState=absent \
/opt/glg/aws-obm/ansible/playbooks/aws-infra-cf-eks-nodes.yaml

```
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM \
 -e eks_stack_name=BSMOBMEKS-Cluster \
 -e eks_nodes_stack_name=BSMOBMEKS-Nodes-128-AZ2 \
 -e eks_version=1.28 \
 -e vpc_id=${VPC_ID} \
 -e region=us-west-2 \
 -e eks_nodes_subnets=${AZ2_SN} \
 -e eks_nodes_security_group=${WKR_SG} \
 -e eks_nodes_instance_type=m5.4xlarge \
 -e eks_nodes_ssh_key_pair_name=bsmobm-prd \
 -e eks_nodes_node_name=obmgrwnamw2lq2 \
 -e eks_nodes_nodegroup_name=BSMOBM-128-workernodes-AZ2 \
 -e worker_nodes=0 \
 -e eks_nodes_instance_role=${NODE_ROLE} \
 -e theState=absent \
/opt/glg/aws-obm/ansible/playbooks/aws-infra-cf-eks-nodes.yaml

```
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM \
 -e eks_stack_name=BSMOBMEKS-Cluster \
 -e eks_nodes_stack_name=BSMOBMEKS-Nodes-128-AZ3 \
 -e eks_version=1.28 \
 -e vpc_id=${VPC_ID} \
 -e region=us-west-2 \
 -e eks_nodes_subnets=${AZ3_SN} \
 -e eks_nodes_security_group=${WKR_SG} \
 -e eks_nodes_instance_type=m5.4xlarge \
 -e eks_nodes_ssh_key_pair_name=bsmobm-prd \
 -e eks_nodes_node_name=obmgrwnamw2lp3 \
 -e eks_nodes_nodegroup_name=BSMOBM-128-workernodes-AZ3 \
 -e worker_nodes=0 \
 -e eks_nodes_instance_role=${NODE_ROLE} \
 -e theState=absent \
/opt/glg/aws-obm/ansible/playbooks/aws-infra-cf-eks-nodes.yaml

```
