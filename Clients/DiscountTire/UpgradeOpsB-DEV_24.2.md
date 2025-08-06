# Environment Information  
<details open><summary>Environment Information</summary>  

> Add these variables to the environment to assist with tasks below  
## DEV Environment:  
```
EXT_ACCESS_FQDN=ombdev.trtc.com  
CLUSTER_NAME=BSMOBM-DR  

VPC_ID=vpc-92e486f6  
AZ1_SN=subnet-0bf7394d375e27b1c  
AZ2_SN=subnet-01696c4ee2c34c870  
AZ3_SN=N/A  
DB1_SN=subnet-d12e9da7  
DB2_SN=subnet-1822ba7c  

EFS_SG=sg-065c61602049b9fab  
EKS_SG=sg-0e47c12ddc0e449e7  
WKR_SG=sg-0f92d21651ef86dd7  
RDS_SG=sg-0d1955adf7826ced8  

NODE_ROLE=arn:aws:iam::222313454062:role/BSMOBM-DR-EKS-NodeInstanceRole-KwldlSQC6i1P  

EKS_ALBs=$(kubectl get svc -A | grep LoadBalancer | awk '{print $5}')
for alb in ${EKS_ALBs}; do
  nslookup $alb;
done

service.beta.kubernetes.io/aws-load-balancer-subnets: subnet-0bf7394d375e27b1c,subnet-01696c4ee2c34c870

RDS_DATABASE=bsmobm-dev-db  
RDS_HOSTNAME=$(aws rds describe-db-instances --profile bsmobm --db-instance-identifier ${RDS_DATABASE} | jq -r .DBInstances[].Endpoint.Address) && echo $RDS_HOSTNAME  
EFS_NAME="BSMOBM-DR-FS"  
EFS_ARN=$(aws efs describe-file-systems --profile bsmobm --query "FileSystems[?Name=='${EFS_NAME}'].FileSystemArn" --output text) && echo $EFS_ARN  
EFS_ID=$(aws efs describe-file-systems --profile bsmobm --query "FileSystems[?Name=='${EFS_NAME}'].FileSystemId" --output text) && echo $EFS_ID  
EFS_HOST=fs-00ed80b78f68a7b40.efs.us-west-2.amazonaws.com  
ECR_HOST=222313454062.dkr.ecr.us-west-2.amazonaws.com  
ECR_PASS=$(aws ecr get-login-password --profile bsmobm)  
CERT_ARN=arn:aws:acm:us-west-2:222313454062:certificate/3a261eff-0483-48a4-acba-ef0fd00e8b6c  

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
SNAPSHOT_NAME="obmdev-db-20250730"

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
BACKUP_ROLE=arn:aws:iam::222313454062:role/service-role/AWSBackupDefaultServiceRole

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
VELERO_BACKUP_NAME=obmdev-20250730

velero backup create -n velero \
 --ttl ${VELERO_TTL} \
 ${VELERO_BACKUP_NAME}

```

## Backup Vertica DB  

</details>


sudo alternatives --install /usr/bin/python python /usr/bin/python3.9

## Upgrade EKS Cluster and Workers  
### Upgrade EKS to 1.27  
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM-DR \
 -e eks_stack_name=BSMOBM-DR-EKS \
 -e eks_version=1.27 \
 -e vpc_id=${VPC_ID} \
 -e aws_region=us-west-2 \
 -e eks_worker_subnets=${AZ1_SN},${AZ2_SN} \
 -e eks_security_group=${EKS_SG} \
/opt/glg/aws-dr/ansible/playbooks/aws-infra-cf-eks-v3.0.1.yml

```

### Upgrade EKS to 1.28
> After the upgrade to 1.27 is complete, then upgrade the cluster to 1.28
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM-DR \
 -e eks_stack_name=BSMOBM-DR-EKS \
 -e eks_version=1.28 \
 -e vpc_id=${VPC_ID} \
 -e aws_region=us-west-2 \
 -e eks_worker_subnets=${AZ1_SN},${AZ2_SN} \
 -e eks_security_group=${EKS_SG} \
/opt/glg/aws-dr/ansible/playbooks/aws-infra-cf-eks-v3.0.1.yml

```

### Upgrade EKS Worker nodes for each AZ
#Drop old workers by AZ
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM-DR \
 -e eks_stack_name=BSMOBM-DR-EKS \
 -e eks_nodes_stack_name=BSMOBM-DR-EKS-Nodes-AZ1 \
 -e eks_version=1.26 \
 -e vpc_id=${VPC_ID} \
 -e aws_region=us-west-2 \
 -e eks_nodes_subnets=${AZ1_SN} \
 -e eks_nodes_security_group=${EKS_SG} \
 -e eks_nodes_instance_type=m5.2xlarge \
 -e eks_nodes_ssh_key_pair_name=obmgr-dev \
 -e eks_nodes_nodegroup_name=BSMOBM-DR-126-workernodes-AZ1 \
 -e worker_nodes=0 \
 -e eks_nodes_instance_role=${NODE_ROLE} \
 -e theState=absent \
/opt/glg/aws-dr/ansible/playbooks/aws-infra-cf-eks-nodes-v3.0.1.yml

```
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM-DR \
 -e eks_stack_name=BSMOBM-DR-EKS \
 -e eks_nodes_stack_name=BSMOBM-DR-EKS-Nodes-AZ2 \
 -e eks_version=1.28 \
 -e vpc_id=${VPC_ID} \
 -e aws_region=us-west-2 \
 -e eks_nodes_subnets=${AZ2_SN} \
 -e eks_nodes_security_group=${EKS_SG} \
 -e eks_nodes_instance_type=m5.2xlarge \
 -e eks_nodes_ssh_key_pair_name=obmgr-dev \
 -e eks_nodes_nodegroup_name=BSMOBM-DR-126-workernodes-AZ2 \
 -e worker_nodes=0 \
 -e eks_nodes_instance_role=${NODE_ROLE} \
 -e theState=absent \
/opt/glg/aws-dr/ansible/playbooks/aws-infra-cf-eks-nodes-v3.0.1.yml

```

### Upgrade EKS to 1.29
> After the old EKS 1.26 workers have been removed, then upgrade the cluster to 1.29
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM-DR \
 -e eks_stack_name=BSMOBM-DR-EKS \
 -e eks_version=1.29 \
 -e vpc_id=${VPC_ID} \
 -e aws_region=us-west-2 \
 -e eks_worker_subnets=${AZ1_SN},${AZ2_SN} \
 -e eks_security_group=${EKS_SG} \
/opt/glg/aws-dr/ansible/playbooks/aws-infra-cf-eks-v3.0.1.yml

```

### Upgrade EKS to 1.30
> After the EKS upgrade is complete, then upgrade the cluster to 1.30
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM-DR \
 -e eks_stack_name=BSMOBM-DR-EKS \
 -e eks_version=1.30 \
 -e vpc_id=${VPC_ID} \
 -e aws_region=us-west-2 \
 -e eks_worker_subnets=${AZ1_SN},${AZ2_SN} \
 -e eks_security_group=${EKS_SG} \
/opt/glg/aws-dr/ansible/playbooks/aws-infra-cf-eks-v3.0.1.yml

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
 -e stack_name=BSMOBM-DR \
 -e eks_stack_name=BSMOBM-DR-EKS \
 -e eks_nodes_stack_name=BSMOBM-DR-EKS-Nodes-AZ1 \
 -e eks_version=1.30 \
 -e vpc_id=${VPC_ID} \
 -e aws_region=us-west-2 \
 -e eks_nodes_subnets=${AZ1_SN} \
 -e eks_nodes_security_group=${EKS_SG} \
 -e eks_nodes_instance_type=m6a.2xlarge \
 -e eks_nodes_ssh_key_pair_name=obmgr-dev \
 -e eks_nodes_nodegroup_name=BSMOBM-DR-130-workernodes-AZ1 \
 -e worker_nodes=3 \
 -e eks_nodes_instance_role=${NODE_ROLE} \
/opt/glg/aws-dr/ansible/playbooks/aws-infra-cf-eks-nodes-v3.0.1.yml

```
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM-DR \
 -e eks_stack_name=BSMOBM-DR-EKS \
 -e eks_nodes_stack_name=BSMOBM-DR-EKS-Nodes-AZ2 \
 -e eks_version=1.30 \
 -e vpc_id=${VPC_ID} \
 -e aws_region=us-west-2 \
 -e eks_nodes_subnets=${AZ2_SN} \
 -e eks_nodes_security_group=${EKS_SG} \
 -e eks_nodes_instance_type=m6a.2xlarge \
 -e eks_nodes_ssh_key_pair_name=obmgr-dev \
 -e eks_nodes_nodegroup_name=BSMOBM-DR-130-workernodes-AZ2 \
 -e worker_nodes=3 \
 -e eks_nodes_instance_role=${NODE_ROLE} \
/opt/glg/aws-dr/ansible/playbooks/aws-infra-cf-eks-nodes-v3.0.1.yml

```

#Drop old workers by AZ
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM-DR \
 -e eks_stack_name=BSMOBM-DR-EKS \
 -e eks_nodes_stack_name=BSMOBM-DR-EKS-Nodes-AZ1 \
 -e eks_version=1.30 \
 -e vpc_id=${VPC_ID} \
 -e aws_region=us-west-2 \
 -e eks_nodes_subnets=${AZ1_SN} \
 -e eks_nodes_security_group=${EKS_SG} \
 -e eks_nodes_instance_type=m6a.2xlarge \
 -e eks_nodes_ssh_key_pair_name=obmgr-dev \
 -e eks_nodes_nodegroup_name=BSMOBM-DR-130-workernodes-AZ1 \
 -e worker_nodes=3 \
 -e eks_nodes_instance_role=${NODE_ROLE} \
 -e theState=absent \
/opt/glg/aws-dr/ansible/playbooks/aws-infra-cf-eks-nodes-v3.0.1.yml

```
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM-DR \
 -e eks_stack_name=BSMOBM-DR-EKS \
 -e eks_nodes_stack_name=BSMOBM-DR-EKS-Nodes-AZ2 \
 -e eks_version=1.30 \
 -e vpc_id=${VPC_ID} \
 -e aws_region=us-west-2 \
 -e eks_nodes_subnets=${AZ2_SN} \
 -e eks_nodes_security_group=${EKS_SG} \
 -e eks_nodes_instance_type=m6a.2xlarge \
 -e eks_nodes_ssh_key_pair_name=obmgr-dev \
 -e eks_nodes_nodegroup_name=BSMOBM-DR-130-workernodes-AZ2 \
 -e worker_nodes=3 \
 -e eks_nodes_instance_role=${NODE_ROLE} \
 -e theState=absent \
/opt/glg/aws-dr/ansible/playbooks/aws-infra-cf-eks-nodes-v3.0.1.yml

```

















## Create EKS Nodes  
### EKS Nodes in AZ1  
> Execute Ansible Playbook
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM-DR \
 -e eks_stack_name=BSMOBMEKS-Cluster \
 -e eks_nodes_stack_name=BSMOBM-DR-EKS-Nodes-AZ1 \
 -e eks_version=1.26 \
 -e vpc_id=vpc-92e486f6 \
 -e aws_region=us-west-2 \
 -e eks_nodes_subnets=subnet-0bf7394d375e27b1c \
 -e eks_nodes_security_group=sg-0f92d21651ef86dd7 \
 -e eks_nodes_instance_type=m6a.4xlarge \
 -e eks_nodes_ssh_key_pair_name=bsmobm-qa \
 -e eks_nodes_nodegroup_name=BSMOBM-DR-126-workernodes-AZ1 \
 -e worker_nodes=3 \
 -e eks_nodes_instance_role=arn:aws:iam::222313454062:role/BSMOBM-DR-EKS-NodeInstanceRole-KwldlSQC6i1P \
 -e tag_env=Development \
 -e tag_app=BSMOBM-DR \
 -e tag_cust="DiscountTire" \
 -e tag_costcenter=60002 \
 -e tag_costgroup=BSMOBMDR \
/opt/glg/aws-dr/ansible/playbooks/aws-infra-cf-eks-nodes-v3.0.1.yml
```

### EKS Nodes in AZ2
> Execute Ansible Playbook
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM-DR \
 -e eks_stack_name=BSMOBMEKS-Cluster \
 -e eks_nodes_stack_name=BSMOBM-DR-EKS-Nodes-AZ2 \
 -e eks_version=1.26 \
 -e vpc_id=vpc-92e486f6 \
 -e aws_region=us-west-2 \
 -e eks_nodes_subnets=subnet-01696c4ee2c34c870 \
 -e eks_nodes_security_group=sg-0f92d21651ef86dd7 \
 -e eks_nodes_instance_type=m6a.4xlarge \
 -e eks_nodes_ssh_key_pair_name=bsmobm-qa \
 -e eks_nodes_nodegroup_name=BSMOBM-DR-126-workernodes-AZ2 \
 -e worker_nodes=3 \
 -e eks_nodes_instance_role=arn:aws:iam::222313454062:role/BSMOBM-DR-EKS-NodeInstanceRole-KwldlSQC6i1P \
 -e tag_env=Development \
 -e tag_app=BSMOBM-DR \
 -e tag_cust="DiscountTire" \
 -e tag_costcenter=60002 \
 -e tag_costgroup=BSMOBMDR \
/opt/glg/aws-dr/ansible/playbooks/aws-infra-cf-eks-nodes-v3.0.1.yml
```

## Create Vertica Management Console
> Execute Ansible Playbook
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM-DR \
 -e vertica_stack_name=BSMOBM-DR-VDB-MC \
 -e vpc_id=vpc-92e486f6 \
 -e vpc_cidr="10.120.0.0/16" \
 -e aws_region=us-west-2 \
 -e vertica_instance_type=c5.large \
 -e vertica_public_subnet=subnet-0bf7394d375e27b1c \
 -e vertica_key_pair_name=obmgr-dev \
 -e tag_env=Development \
 -e tag_app=BSMOBM-DR \
 -e tag_cust="DiscountTire" \
 -e tag_costcenter=60002 \
 -e tag_costgroup=BSMOBMDR \
/opt/glg/aws-dr/ansible/playbooks/aws-infra-cf-vertica-mc-v3.0.1.yml
```

## Create OBM Load Balancer
> Create Certificate (self-signed)
```
openssl req -newkey rsa:4096 -nodes -config ~/omt/obmdev.trtc.com.conf -keyout ~/omt/obmdev.trtc.com.key -x509 -days 730 -out ~/omt/obmdev.trtc.com-ss.crt
```

> Create CERT ARN  
```
aws acm import-certificate --certificate $(cat ~/omt/obmdev.trtc.com.crt | base64 -w0) --private-key $(cat ~/omt/obmdev.trtc.com.key | base64 -w0) --profile bsmobm  
```
> Execute Ansible Playbook
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM-DR \
 -e nlb_stack_name=BSMOBM-DR-LB \
 -e vpc_id=vpc-92e486f6 \
 -e vpc_cidr="10.120.0.0/16" \
 -e aws_region=us-west-2 \
 -e nlb_public_subnets=subnet-0bf7394d375e27b1c,subnet-01696c4ee2c34c870 \
 -e nlb_ssh_key_pair_name=obmgr-dev \
 -e nlb_cert_chain="{{lookup('file', '~/obm/Certificates/OBMDEV/ChainCA.pem')}}" \
 -e nlb_certificate="{{lookup('file', '~/obm/Certificates/OBMDEV/OBMDEV-Cilent.pem')}}" \
 -e nlb_private_key="{{lookup('file', '~/obm/Certificates/OBMDEV/obmdev-key.pem')}}" \
 -e nlb_cert_arn="arn:aws:acm:us-west-2:222313454062:certificate/3a261eff-0483-48a4-acba-ef0fd00e8b6c" \
 -e tag_env=Development \
 -e tag_app=BSMOBM-DR \
 -e tag_cust="DiscountTire" \
 -e tag_costcenter=60002 \
 -e tag_costgroup=BSMOBMDR \
/opt/glg/aws-dr/ansible/playbooks/aws-infra-cf-nlb-obm-v3.0.1.yml
```

# Application Configuration

### Install kubectl
curl https://s3.us-west-2.amazonaws.com/amazon-eks/1.28.11/2024-07-12/bin/linux/amd64/kubectl -o ~/kubectl
chmod a+x ~/kubectl
sudo mv ~/kubectl /usr/bin/kubectl


### Create NFS Directories
sudo mkdir -p /mnt/efs
sudo chown ec2-user:wheel /mnt/efs
sudo mount ${EFS_HOST}:/ /mnt/efs

mkdir -p /mnt/efs/var/vols/itom/core
mkdir -p /mnt/efs/var/vols/itom/itom-logging-vol
mkdir -p /mnt/efs/var/vols/itom/itom-monitor-vol
mkdir -p /mnt/efs/var/vols/itom/db-single-vol
mkdir -p /mnt/efs/var/vols/itom/ospb/vol1
mkdir -p /mnt/efs/var/vols/itom/ospb/vol2
mkdir -p /mnt/efs/var/vols/itom/ospb/vol3
mkdir -p /mnt/efs/var/vols/itom/ospb/vol4
mkdir -p /mnt/efs/var/vols/itom/ospb/vol5
mkdir -p /mnt/efs/var/vols/itom/ospb/vol6
mkdir -p /mnt/efs/var/vols/itom/ospb/vol7
mkdir -p /mnt/efs/var/vols/itom/nom/vol1
mkdir -p /mnt/efs/var/vols/itom/nom/vol2
mkdir -p /mnt/efs/var/vols/itom/nom/vol3
mkdir -p /mnt/efs/var/vols/itom/nom/vol4
mkdir -p /mnt/efs/var/vols/itom/nom/vol1
mkdir -p /mnt/efs/var/vols/itom/nom/vol2
mkdir -p /mnt/efs/var/vols/itom/nom/vol3
mkdir -p /mnt/efs/var/vols/itom/minio1
mkdir -p /mnt/efs/var/vols/itom/minio2
mkdir -p /mnt/efs/var/vols/itom/minio3
mkdir -p /mnt/efs/var/vols/itom/minio4

sudo chown -R 1999:1999 /mnt/efs/var/vols/itom

### Create NFS PVs
```
export EFS_HOST=fs-00ed80b78f68a7b40.efs.us-west-2.amazonaws.com
```
```
cat << EOT | kubectl apply -f -
#---
#apiVersion: v1
#kind: PersistentVolume
#metadata:
#  name: itom-vol
#spec:
#  accessModes:
#  - ReadWriteMany
#  capacity:
#    storage: 20Gi
#  nfs:
#    path: /var/vols/itom/core
#    server: ${EFS_HOST}
#  persistentVolumeReclaimPolicy: Retain
#  claimRef:
#    apiVersion: v1
#    kind: PersistentVolumeClaim
#    name: itom-vol-claim
#  namespace: core
#  storageClassName: cdf-default
#  volumeMode: Filesystem
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: itom-logging-vol
spec:
  accessModes:
  - ReadWriteMany
  capacity:
    storage: 20Gi
  nfs:
    path: /var/vols/itom/itom-logging-vol
    server: ${EFS_HOST}
  persistentVolumeReclaimPolicy: Retain
#  claimRef:
#    apiVersion: v1
#    kind: PersistentVolumeClaim
#    name: itom-logging-vol-claim
#  namespace: core
  storageClassName: cdf-default
  volumeMode: Filesystem
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: itom-monitor-vol
spec:
  accessModes:
  - ReadWriteMany
  capacity:
    storage: 20Gi
  nfs:
    path: /var/vols/itom/itom-monitor-vol
    server: ${EFS_HOST}
  persistentVolumeReclaimPolicy: Retain
#  claimRef:
#    apiVersion: v1
#    kind: PersistentVolumeClaim
#    name: itom-monitor-vol-claim
#  namespace: core
  storageClassName: cdf-default
  volumeMode: Filesystem
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: db-single-vol
spec:
  accessModes:
  - ReadWriteMany
  capacity:
    storage: 20Gi
  nfs:
    path: /var/vols/itom/db-single-vol
    server: ${EFS_HOST}
  persistentVolumeReclaimPolicy: Retain
#  claimRef:
#    apiVersion: v1
#    kind: PersistentVolumeClaim
#    name: db-single-vol-claim
#  namespace: core
  storageClassName: cdf-default
  volumeMode: Filesystem
EOT
```
#OBM PVs
for i in {1..4}; do
    sudo mkdir "/mnt/efs/var/vols/itom/opsbvol$i"
    sudo chown 1999:1999 "/mnt/efs/var/vols/itom/opsbvol$i"
    sudo chmod g+w+s "/mnt/efs/var/vols/itom/opsbvol$i"
    kubectl apply -f - <<<"
apiVersion: v1
kind: PersistentVolume
metadata:
  name: opsbvol$i
spec:
  accessModes:
    - ReadWriteMany
  capacity:
    storage: 10Gi
  nfs:
    path: /var/vols/itom/opsbvol$i
    server: ${EFS_HOST}
  persistentVolumeReclaimPolicy: Retain
  storageClassName: opsb-default
  volumeMode: Filesystem
"
done

for i in 5; do
    sudo mkdir "/mnt/efs/var/vols/itom/opsbvol$i"
    sudo chown 1999:1999 "/mnt/efs/var/vols/itom/opsbvol$i"
    sudo chmod g+w+s "/mnt/efs/var/vols/itom/opsbvol$i"
    kubectl apply -f - <<<"
apiVersion: v1
kind: PersistentVolume
metadata:
  name: opsbvol$i
spec:
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 10Gi
  nfs:
    path: /var/vols/itom/opsbvol$i
    server: ${EFS_HOST}
  persistentVolumeReclaimPolicy: Retain
  storageClassName: opsb-default
  volumeMode: Filesystem
"
done

#NOM PVs
for i in {1..4}; do
    sudo mkdir -p "/mnt/efs/var/vols/itom/nom/vol$i"
    sudo chown 1999:1999 "/mnt/efs/var/vols/itom/nom/vol$i"
    sudo chmod g+w+s "/mnt/efs/var/vols/itom/nom/vol$i"
    kubectl apply -f - <<<"
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nomvol$i
spec:
  accessModes:
    - ReadWriteMany
  capacity:
    storage: 10Gi
  nfs:
    path: /var/vols/itom/nom/vol$i
    server: ${EFS_HOST}
  persistentVolumeReclaimPolicy: Retain
  storageClassName: cdf-nfs
  volumeMode: Filesystem
"
done


### Create OMT Database
```
psql -h ${RDS_HOSTNAME} -U dbadmin -d postgres
```
#### Delete if exists (Cleanup/Remove)
```
DROP DATABASE cdfidmdb IF EXISTS;
DROP ROLE cdfidmuser IF EXISTS;
DROP DATABASE cdfapiserverdb IF EXISTS;
DROP ROLE cdfapiserver IF EXISTS;
```
```
CREATE USER cdfidmuser login PASSWORD 'optic4DTC12_21'; 
GRANT cdfidmuser to dbadmin; 

CREATE DATABASE cdfidmdb WITH owner=cdfidmuser;
```
```
\c cdfidmdb; 
```
```
CREATE SCHEMA cdfidmschema AUTHORIZATION cdfidmuser; 
GRANT ALL ON SCHEMA cdfidmschema to cdfidmuser; 
ALTER USER cdfidmuser SET search_path TO cdfidmschema;
```
```
\q
```

### Configure access to the cluster
```
aws eks update-kubeconfig --name BSMOBM-QA --alias bsmobm-qa --profile bsmobm
```

### Download OMT installer packages/tools
```
mkdir -p ~/omt/2023.05
```
* Get OMT Package
```
unzip ~/omt/2023.05/OMT2305-182-15001-External-K8s.zip -d ~/omt/2023.05/
unzip ~/omt/2023.05/OMT_External_K8s_2023.05-182.zip -d ~/omt/2023.05/
```

### Setup the install config file
```
cat << EOT > ~/omt/omt-install-config.json
{
  "connection": {
    "externalHostname": "${EXT_ACCESS_FQDN}",
    "port": "443",
    "serverKey": "/home/ec2-user/omt/${EXT_ACCESS_FQDN}.key",
    "serverCrt": "/home/ec2-user/omt/${EXT_ACCESS_FQDN}.crt",
    "rootCrt": "/home/ec2-user/omt/${EXT_ACCESS_FQDN}.crt"
  },
  "licenseAgreement": {
    "eula": true,
    "callHome": false
  },
  "volumes": [
    {
      "type": "EFS",
      "name": "itom-logging-vol",
      "host": "${EFS_HOST}",
      "path": "/var/vols/itom/itom-logging-vol"
    },
    {
      "type": "EFS",
      "name": "itom-monitor-vol",
      "host": "${EFS_HOST}",
      "path": "/var/vols/itom/itom-monitor-vol"
    }
  ],
  "database": {
    "type": "extpostgres",
    "param": {
      "dbHost": "${RDS_HOSTNAME}",
      "dbPort": "5432",
      "dbName": "cdfidmdb",
      "dbUser": "cdfidmuser",
      "dbPassword": "optic4DTC12_21",
      "dbCert": "/home/ec2-user/omt/rds_ca_certs.pem"
    }
  }
}
EOT
```

## Deploy OMT
```
~/omt/2023.05/OMT_External_K8s_2023.05-182/install \
 -c ~/omt/omt-install-config.json \
 --k8s-provider aws \
 --external-access-host ${EXT_ACCESS_FQDN} \
 --external-access-port 5443 \
 --aws-certificate-arn "${CERT_ARN}" \
 --loadbalancer-info "aws-load-balancer-type=nlb;aws-load-balancer-internal=true" \
 --cluster-wide-ingress true \
 --nfs-server ${EFS_HOST} \
 --nfs-folder /var/vols/itom/core \
 --registry-url ${ECR_HOST} \
 --registry-username AWS \
 --registry-password ${ECR_PASS} \
 --cdf-home /opt/cdf \
 --capabilities "ClusterManagement=false,DeploymentManagement=true,LogCollection=false,Monitoring=true,MonitoringContent=true,NfsProvisioner=false,Tools=true,K8sBackup=false"
 ```

service.beta.kubernetes.io/aws-load-balancer-internal: "true"
service.beta.kubernetes.io/aws-load-balancer-subnets: ${AZ1_SN},${AZ2_SN},${AZ3_SN}
service.beta.kubernetes.io/aws-load-balancer-type: nlb

### Update NLB Target Groups
> OMT Management Portal :5443
```
TG_5443=arn:aws:elasticloadbalancing:us-west-2:222313454062:targetgroup/BSMOBM-DR-int-NLB-TG5443/d48181b386dd45ab
ALB_5443=$(kubectl get svc portal-ingress-controller-svc -n core -o='jsonpath={.status.loadBalancer.ingress[].hostname}') && echo $ALB_5443
nslookup $ALB_5443
```
TGT_5443="Id=10.120.153.68 Id=10.120.112.225"  
```
aws elbv2 register-targets --target-group-arn $TG_5443 --targets $TGT_5443 --profile bsmobm
```

> OBM UI :443
```
TG_443=arn:aws:elasticloadbalancing:us-west-2:222313454062:targetgroup/BSMOBM-DR-int-NLB-TG443/6f9b4c2921725531
ALB_443=$(kubectl get svc itom-ingress-controller-svc-internal -n obm -o='jsonpath={.status.loadBalancer.ingress[].hostname}') && echo $ALB_443
nslookup $ALB_443
```
TGT_443="Id=10.120.49.240 Id=10.120.192.185"  
```
aws elbv2 register-targets --target-group-arn $TG_443 --targets $TGT_443 --profile bsmobm
```

> DI Administration :18443
```
TG_30004=arn:aws:elasticloadbalancing:us-west-2:222313454062:targetgroup/BSMOBM-DR-int-NLB-TG30004/d3ad5b14a8735958
ALB_30004=$(kubectl get svc itom-di-administration-svc -n obm -o='jsonpath={.status.loadBalancer.ingress[].hostname}') && echo $ALB_30004
nslookup $ALB_30004
```
TGT_30004="Id=10.120.217.188 Id=10.120.8.201"  
```
aws elbv2 register-targets --target-group-arn $TG_30004 --targets $TGT_30004 --profile bsmobm
```

> DI Data Access :28443
```
TG_30003=arn:aws:elasticloadbalancing:us-west-2:222313454062:targetgroup/BSMOBM-DR-int-NLB-TG30003/504a2465ea9f0710
ALB_30003=$(kubectl get svc itom-di-data-access-svc -n obm -o='jsonpath={.status.loadBalancer.ingress[].hostname}') && echo $ALB_30003
nslookup $ALB_30003
```
TGT_30003="Id=10.120.89.142 Id=10.120.212.152"  
```
aws elbv2 register-targets --target-group-arn $TG_30003 --targets $TGT_30003 --profile bsmobm
```

> DI Receiver :5050
```
TG_30001=arn:aws:elasticloadbalancing:us-west-2:222313454062:targetgroup/BSMOBM-DR-int-NLB-TG30001/7aa1517f06541755
ALB_30001=$(kubectl get svc itom-di-receiver-svc -n obm -o='jsonpath={.status.loadBalancer.ingress[].hostname}') && echo $ALB_30001
nslookup $ALB_30001
```
TGT_30001="Id=10.120.200.54 Id=10.120.80.234"  
```
aws elbv2 register-targets --target-group-arn $TG_30001 --targets $TGT_30001 --profile bsmobm
```

> Pulsar Proxy :6651
```
TG_31051=arn:aws:elasticloadbalancing:us-west-2:222313454062:targetgroup/BSMOBM-DR-int-NLB-TG31051/ec8d6e67861747e9
ALB_31051=$(kubectl get svc itomdipulsar-proxy -n obm -o='jsonpath={.status.loadBalancer.ingress[].hostname}') && echo $ALB_31051
nslookup $ALB_31051
```
TGT_31051="Id=10.120.199.158 Id=10.120.76.102"  
```
aws elbv2 register-targets --target-group-arn $TG_31051 --targets $TGT_31051 --profile bsmobm
```

> OM Agent :383
```
TG_383=arn:aws:elasticloadbalancing:us-west-2:222313454062:targetgroup/BSMOBM-DR-int-NLB-TG383/8d41999001c0ccee
ALB_383=$(kubectl get svc itom-monitoring-service-data-broker-svc -n obm -o='jsonpath={.status.loadBalancer.ingress[].hostname}') && echo $ALB_383
nslookup $ALB_383
```
TGT_383=""  
```
aws elbv2 register-targets --target-group-arn $TG_383 --targets $TGT_383 --profile bsmobm
```

## Add EKSCTL to Control Node
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/bin/

###Get OIDC Provider, or Add it to the cluster
eksctl utils associate-iam-oidc-provider --cluster ${CLUSTER_NAME} --approve --profile bsmobm
oidc_id=$(aws eks describe-cluster --name ${CLUSTER_NAME} --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5) && echo $oidc_id

<!--
cat << EOT > aws-ebs-csi-driver-trust-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::222313454062:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/${oidc_id}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.us-west-2.amazonaws.com/id/${oidc_id}:aud": "sts.amazonaws.com",
          "oidc.eks.us-west-2.amazonaws.com/id/${oidc_id}:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }
  ]
}
EOT

aws iam create-role \
  --role-name ${CLUSTER_NAME}_EBS_CSI_DriverRole \
  --assume-role-policy-document file://"aws-ebs-csi-driver-trust-policy.json"
  
aws iam attach-role-policy \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --role-name ${CLUSTER_NAME}_EBS_CSI_DriverRole
-->

## Create CSI Driver for EBS Volumes

### Make sure the CSI Policy has the right AWS Account ID in it
CSIPOLICY=OBMCSIPOLICY-QA
eksctl create iamserviceaccount -v 5 \
 --name ebs-csi-controller-sa \
 --namespace kube-system \
 --cluster ${CLUSTER_NAME} \
 --role-name ${CLUSTER_NAME}_EBS_CSI_DriverRole \
 --attach-policy-arn arn:aws:iam::222313454062:policy/OBMCSIPOLICY-QA \
 --approve \
 --role-only \
 --override-existing-serviceaccounts
 --profile bsmobm


CSI_ROLE=$(kubectl get sa -n kube-system ebs-csi-controller-sa -ojson | jq -r '.metadata.annotations["eks.amazonaws.com/role-arn"]') && echo $CSI_ROLE
eksctl create addon --name aws-ebs-csi-driver --cluster BSMOBM-DR --service-account-role-arn $CSI_ROLE --force --profile bsmobm

## Deploy OpsBridge
### Download OpsBridge helm chart
```
mkdir -p ~/obm/2023.05.P2
#curl -kLs ... -o  ~/obm/2023.05.P2/opsbridge-suite-chart-2023.05.2.zip
unzip ~/obm/2023.05.P2/opsbridge-suite-chart-2023.05.2.zip -d ~/obm/2023.05.P2/
```

### Copy UDX Plugin to Vertica
VERT1=10.120.196.206
scp -i ~/.ssh/vdb_id ~/obm/2023.05.P2/opsbridge-suite-chart/tools/itom-di-pulsarudx-2.9.0-63.x86_64.rpm dbadmin@${VERT1}:/home/dbadmin/

> On Vertica1 Node
sudo su -
rpm -ihv /home/dbadmin/itom-di-pulsarudx-2.9.0-63.x86_64.rpm

export VERTICA_HOME=/vertica/data
export VERTICA_DBA=dbadmin
export VERTICA_RO_USER=vertica_rouser
export VERTICA_RW_USER=vertica_rwuser
export VERTICA_DB=itomdb

cd /usr/local/itom-di-pulsarudx/bin
./dbinit.sh genconfig

/usr/local/itom-di-pulsarudx/bin/dbinit.sh -s --tlscrt /home/dbadmin/certificates/verticadev1.crt --tlskey /home/dbadmin/certificates/verticadev1.key --tlsenforce true --tlscacrt /home/dbadmin/certificates/verticadev1-ca.crt  -tlsonly


### OpsBridge Application deployment
/opt/cdf/bin/cdfctl deployment create -t helm -d obmdev -n obm



### NOM Application deployment
/opt/cdf/bin/cdfctl deployment create -t helm -d nomdev -n obm


TG_9443=
ALB_9443=$(kubectl get svc itom-ingress-controller-svc-internal -n obm -o='jsonpath={.status.loadBalancer.ingress[].hostname}') && echo $ALB_9443
nslookup $ALB_9443
TGT_9443="Id=10.104.28.230 Id=10.104.28.217"

aws elbv2 register-targets --target-group-arn $TG_9443 --targets $TGT_9443 --profile bsmobm

##### END DR Environment #####


## Perform complete backup
### Velero Backup
> Create Velero Backup
```
VELERO_TTL=8760h
VELERO_BACKUP_NAME=obmqa-20241021
velero backup create -n core \
 --ttl ${VELERO_TTL} \
 --exclude-namespaces "default,kube-system,kube-public,kube-node-lease" \
 ${VELERO_BACKUP_NAME}
```

> Restore Velero Backup


> Delete Velero Backup


### EFS Backup
> Environment Variables
BACKUP_DAYS=30
BACKUP_VAULT=trtc-strong-encrypted-vault
BACKUP_ROLE=arn:aws:iam::222313454062:role/service-role/AWSBackupDefaultServiceRole
EFS_NAME="BSMOBMEFS-FS"
EFS_ARN=$(aws efs describe-file-systems --profile bsmobm --query "FileSystems[?Name=='${EFS_NAME}'].FileSystemArn" --output text) && echo $EFS_ARN
EFS_ID=$(aws efs describe-file-systems --profile bsmobm --query "FileSystems[?Name=='${EFS_NAME}'].FileSystemId" --output text) && echo $EFS_ID

> Create EFS Backup
```
aws backup start-backup-job \
 --backup-vault-name="${BACKUP_VAULT}" \
 --resource-arn="${EFS_ARN}" \
 --lifecycle="DeleteAfterDays=${BACKUP_DAYS}" \
 --iam-role-arn="${BACKUP_ROLE}" \
 --profile bsmobm
```

> Restore EFS Backup
* Get Recovery Point to restore
```
aws backup list-recovery-points-by-resource --resource-arn ${EFS_ARN} --profile bsmobm
```
```
aws backup list-recovery-points-by-resource --resource-arn ${EFS_ARN} --profile bsmobm | jq -r .RecoveryPoints[0].RecoveryPointArn
EFS_RP="arn:aws:backup:us-west-2:222313454062:recovery-point:5f1f3fd0-a5ac-47e2-bd01-858c13eca9f1"
```
```
aws backup start-restore-job \
 --recovery-point-arn "${EFS_RP}" \
 --iam-role-arn "${BACKUP_ROLE}" \
 --metadata "newFileSystem"="False","file-system-id"="${EFS_ID}","Encrypted"="False" \
 --profile bsmobm
```

> Delete EFS Backup
```
aws backup delete-recovery-point --profile bsmobm \
 --backup-vault-name="${BACKUP_VAULT}" \
 --recovery-point-arn "${EFS_RP}"
```

### RDS Backup
> Create RDS Backup
```
SNAPSHOT_NAME="obmqa-db-20241021"
aws rds create-db-snapshot --profile bsmobm \
 --db-snapshot-identifier="${SNAPSHOT_NAME}" \
 --db-instance-identifier="${RDS_DATABASE}" 
```

> Restore RDS Backuo
aws rds add-tags-to-resource --profile bsmobm \
 --resource-name ${RDS_DATABASE}
 --tags Key=Environment,Value=Development Key=CostGroup,Value=60002

> Delete RDS Backup
aws rds delete-db-snapshot --profile bsmobm \
 --db-snapshot-identifier="${SNAPSHOT_NAME}"



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
helm get values -n obm obmqa > ~/obm/24.2.P1/obm-values.yml
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

