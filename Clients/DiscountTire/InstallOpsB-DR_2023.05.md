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

#Create Security Groups
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

#Create EFS Stack
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM-DR \
 -e efs_stack_name=BSMOBM-DR-FS \
 -e efs_template_name=aws-cf-efs-v3.0.1-2zone.json \
 -e vpc_id=vpc-92e486f6 \
 -e aws_region=us-west-2 \
 -e efs_subnets=subnet-0bf7394d375e27b1c,subnet-01696c4ee2c34c870 \
 -e efs_security_group=sg-065c61602049b9fab \
/opt/glg/aws-dr/ansible/playbooks/aws-infra-cf-efs-v3.0.1.yml

#Create RDS Stack
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM-DR \
 -e rds_stack_name=BSMOBM-DR-DB \
 -e vpc_id=vpc-92e486f6 \
 -e region=us-west-2 \
 -e rds_db_subnet_1=subnet-01696c4ee2c34c870 \
 -e rds_db_subnet_2=subnet-0bf7394d375e27b1c \
 -e rds_security_group=sg-0d1955adf7826ced8 \
 -e rds_key_pair_name=obmgr-dev \
 -e rds_db_param_group=bsmobm-postgres15 \
/opt/glg/aws-dr/ansible/playbooks/aws-infra-cf-rds-v3.0.1.yaml

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

#Configure access to the cluster
aws eks update-kubeconfig --name BSMOBM-DR --alias bsmobm-dr --profile bsmobm

#Download OMT installer packages/tools
mkdir -p ~/omt/2023.05


##### END DR Environment #####
