## Create Vertica Management Console
> Execute Ansible Playbook
```
ansible-playbook --vault-password-file=/opt/glg/.ans_pass \
 -e stack_name=BSMOBM-DR \
 -e vertica_stack_name=BSMOBM-DR-VDB-MC-243 \
 -e vpc_id=vpc-92e486f6 \
 -e vpc_cidr="10.120.0.0/16" \
 -e aws_region=us-west-2 \
 -e vertica_instance_type=c5.large \
 -e vertica_public_subnet=subnet-0bf7394d375e27b1c \
 -e vertica_key_pair_name=obmgr-dev \
 -e vertica_s3=s3://dt-obmeks-qa/vertica-dev \
 -e vertica_secret=arn:aws:secretsmanager:us-west-2:222313454062:secret:obmvert-mcdbadmin-dev-waD5OF \
 -e tag_env=Development \
 -e tag_app=BSMOBM-DR \
 -e tag_cust="DiscountTire" \
 -e tag_costcenter=60002 \
 -e tag_costgroup=BSMOBMDR \
/opt/glg/aws-dr/ansible/playbooks/aws-infra-cf-vertica-mc-v24.3.yml
```



## Add inbound port to Security Group
aws ec2 authorize-security-group-ingress \
    --group-id sg-0dc73e0cfee64c9b5 \
    --protocol tcp \
    --port 5433 \
    --cidr 10.0.0.0/16 \
    --profile bsmobm

aws ec2 authorize-security-group-ingress \
    --group-id sg-0dc73e0cfee64c9b5 \
    --protocol tcp \
    --port 5433 \
    --cidr 10.41.0.0/16 \
    --profile bsmobm

aws ec2 authorize-security-group-ingress \
    --group-id sg-0dc73e0cfee64c9b5 \
    --protocol tcp \
    --port 5433 \
    --cidr 10.101.0.0/16 \
    --profile bsmobm

aws ec2 authorize-security-group-ingress \
    --group-id sg-0dc73e0cfee64c9b5 \
    --protocol tcp \
    --port 5433 \
    --cidr 10.110.0.0/16 \
    --profile bsmobm
