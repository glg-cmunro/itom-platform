# Maintenance Activites
<details><summary>Maintenace Activities</summary>

## Stop/Start EC2 Instance
> Stop Instance
```
aws ec2 stop-instances --instance-ids i-0c359c2ea1fcae2f2 --profile bsmobm  #DR Vertica MC
```
> Start Instance
```
aws ec2 start-instances --instance-ids i-0c359c2ea1fcae2f2 --profile bsmobm  #DR Vertica MC
```
</details>

# AWS Infrastructure  
## DR Environment:
EXT_ACCESS_FQDN=obmdev.trtc.com
CLUSTER_NAME=BSMOBM-DEV

VPC_ID=vpc-92e486f6
AZ1_SN=subnet-0bf7394d375e27b1c
AZ2_SN=subnet-01696c4ee2c34c870
#AZ3_SN=--
DB1_SN=subnet-d12e9da7
DB2_SN=subnet-1822ba7c
RDS_SG=sg-0d1955adf7826ced8
EFS_SG=sg-065c61602049b9fab
EKS_SG=sg-0e47c12ddc0e449e7
WKR_SG=sg-0f92d21651ef86dd7

RDS_DATABASE=bsmobm-dev-db
EFS_HOST=fs-00ed80b78f68a7b40.efs.us-west-2.amazonaws.com
ECR_HOST=222313454062.dkr.ecr.us-west-2.amazonaws.com
ECR_PASS=$(aws ecr get-login-password --profile bsmobm)

CERT_ARN=$(aws acm list-certificates --profile bsmobm --query "CertificateSummaryList[?DomainName=='obmdev.trtc.com'].CertificateArn" --output text) && echo $CERT_ARN
RDS_HOSTNAME=$(aws rds describe-db-instances --profile bsmobm --db-instance-identifier ${RDS_DATABASE} | jq -r .DBInstances[].Endpoint.Address) && echo $RDS_HOSTNAME
RDS_ARN=$(aws rds describe-db-instances --profile bsmobm --db-instance-identifier ${RDS_DATABASE} | jq -r .DBInstances[].DBInstanceArn) && echo $RDS_ARN

## Create Security Groups
> Execute Ansible Playbook
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM-DR \
 -e sg_stack_name=BSMOBM-DR-SG \
 -e sg_template_name=aws-cf-sg-v3.0.1-noBastion.json \
 -e vpc_id=vpc-92e486f6 \
 -e vpc_cidr="10.120.0.0/16" \
 -e aws_region=us-west-2 \
 -e tag_env=Development \
 -e tag_app=BSMOBM-DR \
 -e tag_cust="DiscountTire" \
 -e tag_costcenter=60002 \
 -e tag_costgroup=BSMOBMDR \
/opt/glg/aws-dr/ansible/playbooks/aws-infra-cf-sg-v3.0.1.yml
```

## Create EFS Stack
> Execute Ansible Playbook
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM-DR \
 -e efs_stack_name=BSMOBM-DR-FS \
 -e efs_template_name=aws-cf-efs-v3.0.1-2zone.json \
 -e vpc_id=vpc-92e486f6 \
 -e aws_region=us-west-2 \
 -e efs_subnets=subnet-0bf7394d375e27b1c,subnet-01696c4ee2c34c870 \
 -e efs_security_group=sg-065c61602049b9fab \
/opt/glg/aws-dr/ansible/playbooks/aws-infra-cf-efs-v3.0.1.yml
```

## Create RDS Stack
> Execute Ansible Playbook
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=${CLUSTER_NAME} \
 -e rds_stack_name=${CLUSTER_NAME}-DB \
 -e vpc_id=${VPC_ID} \
 -e aws_region=us-west-2 \
 -e rds_db_subnet_1=${DB1_SN} \
 -e rds_db_subnet_2=${DB2_SN} \
 -e rds_security_group=${RDS_SG} \
 -e rds_key_pair_name=obmgr-dev \
 -e rds_db_version=13.15 \
 -e rds_db_param_group=obm-pgsql-13 \
/opt/glg/aws-dr/ansible/playbooks/aws-infra-cf-rds-v3.0.1.yml -e theState=absent
```

> ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
>  -e stack_name=BSMOBM-DR \
>  -e rds_stack_name=BSMOBM-DR-DB \
>  -e vpc_id=vpc-92e486f6 \
>  -e aws_region=us-west-2 \
>  -e rds_db_subnet_1=subnet-01696c4ee2c34c870 \
>  -e rds_db_subnet_2=subnet-0bf7394d375e27b1c \
>  -e rds_security_group=sg-0d1955adf7826ced8 \
>  -e rds_key_pair_name=obmgr-dev \
>  -e rds_db_param_group=bsmobm-postgres15 \
> /opt/glg/aws-dr/ansible/playbooks/aws-infra-cf-rds-v3.0.1.yml
```

## Create EKS Stack
> Execute Ansible Playbook
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM-DR \
 -e eks_stack_name=BSMOBM-DR-EKS \
 -e eks_version=1.26 \
 -e vpc_id=vpc-92e486f6 \
 -e aws_region=us-west-2 \
 -e eks_worker_subnets=subnet-0bf7394d375e27b1c,subnet-01696c4ee2c34c870 \
 -e eks_security_group=sg-0e47c12ddc0e449e7 \
 -e tag_env=Development \
 -e tag_app=BSMOBM-DR \
 -e tag_cust="DiscountTire" \
 -e tag_costcenter=60002 \
 -e tag_costgroup=BSMOBMDR \
/opt/glg/aws-dr/ansible/playbooks/aws-infra-cf-eks-v3.0.1.yml
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
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: itom-vol
spec:
  accessModes:
  - ReadWriteMany
  capacity:
    storage: 20Gi
  nfs:
    path: /var/vols/itom/core
    server: ${EFS_HOST}
  persistentVolumeReclaimPolicy: Retain
#  claimRef:
#    apiVersion: v1
#    kind: PersistentVolumeClaim
#    name: itom-vol-claim
#  namespace: core
  storageClassName: cdf-default
  volumeMode: Filesystem
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: itom-logging
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
  name: itom-monitor
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
#---
#apiVersion: v1
#kind: PersistentVolume
#metadata:
#  name: db-single-vol
#spec:
#  accessModes:
#  - ReadWriteMany
#  capacity:
#    storage: 20Gi
#  nfs:
#    path: /var/vols/itom/db-single-vol
#    server: ${EFS_HOST}
#  persistentVolumeReclaimPolicy: Retain
##  claimRef:
##    apiVersion: v1
##    kind: PersistentVolumeClaim
##    name: db-single-vol-claim
##  namespace: core
#  storageClassName: cdf-default
#  volumeMode: Filesystem
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
aws eks update-kubeconfig --name BSMOBM-DR --alias bsmobm-dr --profile bsmobm
```

### Download OMT installer packages/tools
```
mkdir -p ~/omt/2023.05
```
```
mkdir -p ~/omt/24.2.P2
```
* Get OMT Package
```
unzip ~/omt/2023.05/OMT2305-182-15001-External-K8s.zip -d ~/omt/2023.05/
unzip ~/omt/2023.05/OMT_External_K8s_2023.05-182.zip -d ~/omt/2023.05/
```
```
unzip ~/omt/24.2.P2/OMT2422-161-15001-External-K8s.zip -d ~/omt/24.2.P2/
unzip ~/omt/24.2.P2/OMT_External_K8s_24.2.2-161.zip -d ~/omt/24.2.P2/
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
    "rootCrt": "/home/ec2-user/omt/root_CA.crt"
  },
  "licenseAgreement": {
    "eula": true,
    "callHome": false
  },
  "volumes": [
    {
      "type": "EFS",
      "name": "itom-vol",
      "host": "${EFS_HOST}",
      "path": "/var/vols/itom/core"
    },
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
~/omt/24.2.P2/OMT_External_K8s_24.2.2-161/install \
 -c ~/omt/omt-install-config.json \
 --k8s-provider aws \
 --external-access-host ${EXT_ACCESS_FQDN} \
 --external-access-port 5443 \
 --aws-certificate-arn "${CERT_ARN}" \
 --loadbalancer-info "aws-load-balancer-type=nlb;aws-load-balancer-internal=true;aws-load-balancer-subnets=subnet-0bf7394d375e27b1c,subnet-01696c4ee2c34c870" \
 --nfs-server ${EFS_HOST} \
 --nfs-folder /var/vols/itom/core \
 --registry-url ${ECR_HOST} \
 --registry-username AWS \
 --registry-password ${ECR_PASS} \
 --cdf-home /opt/cdf \
 --capabilities "ClusterManagement=false,DeploymentManagement=true,LogCollection=false,Monitoring=true,MonitoringContent=true,NfsProvisioner=false,Tools=true,K8sBackup=false"
 ```
 --cluster-wide-ingress true \

service.beta.kubernetes.io/aws-load-balancer-internal: "true"
service.beta.kubernetes.io/aws-load-balancer-subnets: subnet-0bf7394d375e27b1c,subnet-01696c4ee2c34c870
service.beta.kubernetes.io/aws-load-balancer-type: nlb

### Update NLB Target Groups
> OMT Management Portal :5443
```
TG_5443=arn:aws:elasticloadbalancing:us-west-2:222313454062:targetgroup/BSMOBM-DR-int-NLB-TG5443/d48181b386dd45ab
ALB_5443=$(kubectl get svc portal-ingress-controller-svc -n core -o='jsonpath={.status.loadBalancer.ingress[].hostname}') && echo $ALB_5443
nslookup $ALB_5443
```
TGT_5443="Id=10.120.37.201 Id=10.120.191.144"  
TGT_5443_OLD="Id=10.104.28.216 Id=10.104.28.228"  
```
aws elbv2 register-targets --target-group-arn $TG_5443 --targets $TGT_5443 --profile bsmobm
aws elbv2 deregister-targets --target-group-arn $TG_5443 --targets $TGT_5443_OLD --profile bsmobm
```

> OBM UI :443
```
TG_443=arn:aws:elasticloadbalancing:us-west-2:222313454062:targetgroup/BSMOBM-DR-int-NLB-TG443/6f9b4c2921725531
ALB_443=$(kubectl get svc itom-ingress-controller-svc-internal -n obm -o='jsonpath={.status.loadBalancer.ingress[].hostname}') && echo $ALB_443
nslookup $ALB_443
```
TGT_443="Id=10.120.151.107 Id=10.120.98.168"  
TGT_443_OLD="Id=10.104.28.233 Id=10.104.28.215 Id=10.104.28.230 Id=10.104.28.217"  
```
aws elbv2 register-targets --target-group-arn $TG_443 --targets $TGT_443 --profile bsmobm
aws elbv2 deregister-targets --target-group-arn $TG_443 --targets $TGT_443_OLD --profile bsmobm
```

> DI Administration :18443
```
TG_30004=arn:aws:elasticloadbalancing:us-west-2:222313454062:targetgroup/BSMOBM-DR-int-NLB-TG30004/d3ad5b14a8735958
ALB_30004=$(kubectl get svc itom-di-administration-svc -n obm -o='jsonpath={.status.loadBalancer.ingress[].hostname}') && echo $ALB_30004
nslookup $ALB_30004
```
TGT_30004="Id=10.120.81.22 Id=10.120.248.138"  
TGT_30004_OLD="Id=10.104.24.100"  
```
aws elbv2 register-targets --target-group-arn $TG_30004 --targets $TGT_30004 --profile bsmobm
aws elbv2 deregister-targets --target-group-arn $TG_30004 --targets $TGT_30004_OLD --profile bsmobm
```

> DI Data Access :28443
```
TG_30003=arn:aws:elasticloadbalancing:us-west-2:222313454062:targetgroup/BSMOBM-DR-int-NLB-TG30003/504a2465ea9f0710
ALB_30003=$(kubectl get svc itom-di-data-access-svc -n obm -o='jsonpath={.status.loadBalancer.ingress[].hostname}') && echo $ALB_30003
nslookup $ALB_30003
```
TGT_30003="Id=10.120.24.107 Id=10.120.146.160"  
TGT_30003_OLD="Id=10.104.24.42 Id=10.104.28.229 Id=10.104.28.220 Id=10.104.24.182"  
```
aws elbv2 register-targets --target-group-arn $TG_30003 --targets $TGT_30003 --profile bsmobm
aws elbv2 deregister-targets --target-group-arn $TG_30003 --targets $TGT_30003_OLD --profile bsmobm
```

> DI Receiver :5050
```
TG_30001=arn:aws:elasticloadbalancing:us-west-2:222313454062:targetgroup/BSMOBM-DR-int-NLB-TG30001/7aa1517f06541755
ALB_30001=$(kubectl get svc itom-di-receiver-svc -n obm -o='jsonpath={.status.loadBalancer.ingress[].hostname}') && echo $ALB_30001
nslookup $ALB_30001
```
TGT_30001="Id=10.120.184.218 Id=10.120.33.156"  
TGT_30001_OLD="Id=10.104.28.228 Id=10.104.28.221 Id=10.104.24.242 Id=10.104.24.114"  
```
aws elbv2 register-targets --target-group-arn $TG_30001 --targets $TGT_30001 --profile bsmobm
aws elbv2 deregister-targets --target-group-arn $TG_30001 --targets $TGT_30001_OLD --profile bsmobm
```

> Pulsar Proxy :6651
```
TG_31051=arn:aws:elasticloadbalancing:us-west-2:222313454062:targetgroup/BSMOBM-DR-int-NLB-TG31051/ec8d6e67861747e9
ALB_31051=$(kubectl get svc itomdipulsar-proxy -n obm -o='jsonpath={.status.loadBalancer.ingress[].hostname}') && echo $ALB_31051
nslookup $ALB_31051
```
TGT_31051="Id=10.120.119.209 Id=10.120.217.18"  
TGT_31051_OLD="Id=10.104.28.232 Id=10.104.28.219 Id=10.104.24.254 Id=10.104.24.33"  
```
aws elbv2 register-targets --target-group-arn $TG_31051 --targets $TGT_31051 --profile bsmobm
aws elbv2 deregister-targets --target-group-arn $TG_31051 --targets $TGT_31051_OLD --profile bsmobm
```

> OM Agent :383
```
TG_383=arn:aws:elasticloadbalancing:us-west-2:222313454062:targetgroup/BSMOBM-DR-int-NLB-TG383/8d41999001c0ccee
ALB_383=$(kubectl get svc omi-bbc -n obm -o='jsonpath={.status.loadBalancer.ingress[].hostname}') && echo $ALB_383
nslookup $ALB_383
```
TGT_383="Id=10.120.202.203 Id=10.120.28.180"  
TGT_383_OLD="Id=10.104.28.234 Id=10.104.28.218"  
```
aws elbv2 register-targets --target-group-arn $TG_383 --targets $TGT_383 --profile bsmobm
aws elbv2 deregister-targets --target-group-arn $TG_383 --targets $TGT_383_OLD --profile bsmobm
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
mkdir -p ~/obm/24.2.P1_HF4
#curl -kLs ... -o  ~/obm/24.2.P1-H4/opsbridge-suite-chart-24.2.P1_HF4.zip
unzip ~/obm/24.2.P1_HF4/opsbridge-suite-chart-24.2.P1_HF4.zip -d ~/obm/24.2.P1_HF4/
```

### Copy UDX Plugin to Vertica
VERT1=10.120.196.206
scp -i ~/.ssh/vdb_id ~/obm/24.2.P1_HF4/opsbridge-suite-chart/tools/itom-di-pulsarudx-2.12.2-2.x86_64.rpm dbadmin@${VERT1}:/home/dbadmin/

> On Vertica1 Node
sudo su -
rpm -Uhv /home/dbadmin/itom-di-pulsarudx-2.12.2-2.x86_64.rpm

export VERTICA_HOME=/vertica/data
export VERTICA_DBA=dbadmin
export VERTICA_RO_USER=vertica_rouser
export VERTICA_RW_USER=vertica_rwuser
export VERTICA_DB=itomdb
export VERTICA_DBA_PASS=TRe6uMA2\$2022

cd /usr/local/itom-di-pulsarudx/bin
./dbinit.sh genconfig

/usr/local/itom-di-pulsarudx/bin/dbinit.sh -s --tlscrt /home/dbadmin/certificates/verticadev1.crt --tlskey /home/dbadmin/certificates/verticadev1.key --tlsenforce true --tlscacrt /home/dbadmin/certificates/verticadev1-ca.crt  --tlsonly


### OpsBridge Application deployment
/opt/cdf/bin/cdfctl deployment create -t helm -d obmdev -n obm



### NOM Application deployment
/opt/cdf/bin/cdfctl deployment create -t helm -d nomdev -n nom


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
VELERO_TTL=8765h
VELERO_BACKUP_NAME=obmdev-20241021
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
EFS_NAME="BSMOBM-DR-FS"
EFS_ARN=$(aws efs describe-file-systems --profile bsmobm --query "FileSystems[?Name=='${EFS_NAME}'].FileSystemArn" --output text) && echo $EFS_ARN
EFS_ID=$(aws efs describe-file-systems --profile bsmobm --query "FileSystems[?Name=='${EFS_NAME}'].FileSystemId" --output text) && echo $EFS_ID

> Create EFS Backup
```
aws backup start-backup-job --profile bsmobm \
 --backup-vault-name="${BACKUP_VAULT}" \
 --resource-arn="${EFS_ARN}" \
 --lifecycle="DeleteAfterDays=${BACKUP_DAYS}" \
 --iam-role-arn="${BACKUP_ROLE}"
```

> Restore EFS Backup
* Get Recovery Point to restore
```
aws backup list-recovery-points-by-resource --resource-arn ${EFS_ARN} --profile bsmobm
```
```
EFS_RP="arn:aws:backup:us-west-2:222313454062:recovery-point:daa17de3-e3b7-49c3-90ee-741e4eece12b"
```
```
aws backup start-restore-job \
 --recovery-point-arn "${EFS_RP}" \
 --iam-role-arn "${BACKUP_ROLE}" \
 --metadata "newFileSystem"="False","file-system-id"="${EFS_ID}","Encrypted"="False" \
 --profile bsmobm
```

> Delete EFS Backup


### RDS Backup
> Create RDS Backup
```
SNAPSHOT_NAME="obmdev-db-20241021"
aws rds create-db-snapshot --profile bsmobm \
 --db-snapshot-identifier="${SNAPSHOT_NAME}" \
 --db-instance-identifier="${RDS_DATABASE}"
```

> Restore RDS Backuo
RDS_DB
aws rds add-tags-to-resource --profile bsmobm \
 --resource-name ${RDS_ARN} \
 --tags Key=Environment,Value=Development Key=CostGroup,Value=60002 Key=Name,Value=BSMOBM-DR-DB

> Delete RDS Backup
aws rds delete-db-snapshot \
 --db-snapshot-identifier="${SNAPSHOT_NAME}" \
 --profile bsmobm
