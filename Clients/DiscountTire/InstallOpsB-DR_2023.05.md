# Maintenance activites
## Stop/Start EC2 Instance
> Stop Instance
```
aws ec2 stop-instances --instance-ids i-0c359c2ea1fcae2f2 --profile bsmobm  #DR Vertica MC
```
> Start Instance
```
aws ec2 start-instances --instance-ids i-0c359c2ea1fcae2f2 --profile bsmobm  #DR Vertica MC
```

## DR Environment:

VPC_ID=vpc-92e486f6
AZ1_SN=subnet-0bf7394d375e27b1c
AZ2_SN=subnet-01696c4ee2c34c870
#AZ3_SN=--
DB1_SN=subnet-d12e9da7
DB2_SN=subnet-1822ba7c
EFS_SG=sg-065c61602049b9fab
EKS_SG=sg-0e47c12ddc0e449e7
WKR_SG=sg-0f92d21651ef86dd7
RDS_SG=sg-0d1955adf7826ced8

EFS_HOST=fs-00ed80b78f68a7b40.efs.us-west-2.amazonaws.com
RDS_HOST=bsmobm-qa2dr.cpcewzs5h0rk.us-west-2.rds.amazonaws.com
RDS_HOST=bsmobm-dr-db.cpcewzs5h0rk.us-west-2.rds.amazonaws.com
ECR_HOST=222313454062.dkr.ecr.us-west-2.amazonaws.com
ECR_PASS=$(aws ecr get-login-password --profile bsmobm)
CERT_ARN=arn:aws:acm:us-west-2:222313454062:certificate/8b8dd5d1-8c3f-49af-b4fb-1037b58f2e6d

## Create Security Groups
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

## Create EFS Stack
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM-DR \
 -e efs_stack_name=BSMOBM-DR-FS \
 -e efs_template_name=aws-cf-efs-v3.0.1-2zone.json \
 -e vpc_id=vpc-92e486f6 \
 -e aws_region=us-west-2 \
 -e efs_subnets=subnet-0bf7394d375e27b1c,subnet-01696c4ee2c34c870 \
 -e efs_security_group=sg-065c61602049b9fab \
/opt/glg/aws-dr/ansible/playbooks/aws-infra-cf-efs-v3.0.1.yml

## Create RDS Stack
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM-DR \
 -e rds_stack_name=BSMOBM-DR-DB \
 -e vpc_id=vpc-92e486f6 \
 -e aws_region=us-west-2 \
 -e rds_db_subnet_1=subnet-01696c4ee2c34c870 \
 -e rds_db_subnet_2=subnet-0bf7394d375e27b1c \
 -e rds_security_group=sg-0d1955adf7826ced8 \
 -e rds_key_pair_name=obmgr-dev \
 -e rds_db_param_group=bsmobm-postgres15 \
/opt/glg/aws-dr/ansible/playbooks/aws-infra-cf-rds-v3.0.1.yml

#Create EKS Stack
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

#Create EKS Nodes in separate Node Groups per AZ
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

#Create Vertica Management Console
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

#Create Certificate (self-signed)
openssl req -newkey rsa:4096 -nodes -config ~/omt/obmdev.trtc.com.conf -keyout ~/omt/obmdev.trtc.com.key -x509 -days 730 -out ~/omt/obmdev.trtc.com-ss.crt

#Create CERT ARN
aws acm import-certificate --certificate $(cat ~/omt/obmdev.trtc.com.crt | base64 -w0) --private-key $(cat ~/omt/obmdev.trtc.com.key | base64 -w0) --profile bsmobm

#Create OBM Load Balancer
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM-DR \
 -e nlb_stack_name=BSMOBM-DR-LB \
 -e vpc_id=vpc-92e486f6 \
 -e vpc_cidr="10.120.0.0/16" \
 -e region=us-west-2 \
 -e nlb_public_subnets=subnet-0bf7394d375e27b1c,subnet-01696c4ee2c34c870 \
 -e nlb_ssh_key_pair_name=obmgr-dev \
 -e nlb_cert_chain="{{lookup('file', '/opt/glg/obm/obmdev.trtc.com.ca.pem')}}" \
 -e nlb_certificate="{{lookup('file', '/opt/glg/obm/obmdev.trtc.com.crt')}}" \
 -e nlb_private_key="{{lookup('file', '/opt/glg/obm/obmdev.trtc.com.key.nopass')}}" \
 -e tag_env=Development \
 -e tag_app=BSMOBM-DR \
 -e tag_cust="DiscountTire" \
 -e tag_costcenter=60002 \
 -e tag_costgroup=BSMOBMDR \
/opt/glg/aws-dr/ansible/playbooks/aws-infra-cf-nlb-obm-v3.0.1.yml

#Install kubectl
curl https://s3.us-west-2.amazonaws.com/amazon-eks/1.28.11/2024-07-12/bin/linux/amd64/kubectl -o ~/kubectl
chmod a+x ~/kubectl
sudo mv ~/kubectl /usr/bin/kubectl


#Create NFS Directories
sudo mkdir -p /mnt/efs
sudo chown ec2-user:wheel /mnt/efs
sudo mount ${EFS_HOST}:/ /mnt/efs

mkdir -p /mnt/efs/var/vols/itom/core
mkdir -p /mnt/efs/var/vols/itom/itom-logging-vol
mkdir -p /mnt/efs/var/vols/itom/itom-monitor-vol
mkdir -p /mnt/efs/var/vols/itom/db-single-vol
mkdir -p /mnt/efs/var/vols/itom/ospb
mkdir -p /mnt/efs/var/vols/itom/ospb/vol1
mkdir -p /mnt/efs/var/vols/itom/ospb/vol2
mkdir -p /mnt/efs/var/vols/itom/ospb/vol3
mkdir -p /mnt/efs/var/vols/itom/ospb/vol4
mkdir -p /mnt/efs/var/vols/itom/ospb/vol5
mkdir -p /mnt/efs/var/vols/itom/ospb/vol6
mkdir -p /mnt/efs/var/vols/itom/ospb/vol7
mkdir -p /mnt/efs/var/vols/itom/nom
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
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: itom-logging-vol-claim
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
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: db-single-vol-claim
#  namespace: core
  storageClassName: cdf-default
  volumeMode: Filesystem
EOT
```

### Create OMT Database
```
export RDS_HOST=bsmobm-qa2dr.cpcewzs5h0rk.us-west-2.rds.amazonaws.com
psql -h ${RDS_HOST} -U dbadmin -d postgres
```
#### Delete if exists (Cleanup/Remove)
```
DROP DATABASE cdfidmdb;
DROP ROLE cdfidmuser;
DROP DATABASE cdfapiserverdb;
DROP ROLE cdfapiserver;
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

#Configure access to the cluster
aws eks update-kubeconfig --name BSMOBM-DR --alias bsmobm-dr --profile bsmobm

#Download OMT installer packages/tools
mkdir -p ~/omt/2023.05
unzip ~/omt/2023.05/OMT2305-182-15001-External-K8s.zip -d ~/omt/2023.05/
unzip ~/omt/2023.05/OMT_External_K8s_2023.05-182.zip -d ~/omt/2023.05/

#Setup the install config file
```
cat << EOT > ~/omt/omt-install-config.json
{
  "connection": {
    "externalHostname": "obmdev.trtc.com",
    "port": "443",
    "serverKey": "/home/ec2-user/omt/obmdev.trtc.com.key",
    "serverCrt": "/home/ec2-user/omt/obmdev.trtc.com.crt",
    "rootCrt": "/home/ec2-user/omt/obmdev.trtc.com.crt"
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
      "dbHost": "${RDS_HOST}",
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

#Deploy OMT
```
~/omt/2023.05/OMT_External_K8s_2023.05-182/install \
 -c ~/omt/omt-install-config.json \
 --k8s-provider aws \
 --external-access-host obmdev.trtc.com \
 --external-access-port 5443 \
 --aws-certificate-arn "arn:aws:acm:us-west-2:222313454062:certificate/8b8dd5d1-8c3f-49af-b4fb-1037b58f2e6d" \
 --cluster-wide-ingress true \
 --nfs-server ${EFS_HOST} \
 --nfs-folder /var/vols/itom/core \
 --registry-url ${ECR_HOST} \
 --registry-username AWS \
 --registry-password ${ECR_PASS} \
 --cdf-home /opt/cdf \
 --capabilities "ClusterManagement=false,DeploymentManagement=true,LogCollection=false,Monitoring=true,MonitoringContent=true,NfsProvisioner=false,Tools=true,K8sBackup=false"
 
 --loadbalancer-info "aws-load-balancer-type=nlb;aws-load-balancer-internal=false" \
 

#Download OpsBridge helm chart
##opsbridge-suite-chart-2023.05.2.zip

mkdir -p ~/obm/2023.05
#curl -kLs ... -o  ~/obm/2023.05/opsbridge-suite-chart-2023.05.2.zip
unzip ~/obm/2023.05/opsbridge-suite-chart-2023.05.2.zip -d ~/obm/2023.05/

#Copy UDX Plugin to Vertica
VERT1=10.120.196.206
scp -i ~/.ssh/vdb_id ~/obm/2023.05/opsbridge-suite-chart/tools/itom-di-pulsarudx-2.9.0-63.x86_64.rpm dbadmin@${VERT1}:/home/dbadmin/

##### END DR Environment #####
