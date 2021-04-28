This is a folder level README

System Requirements to execute these playbooks include:
1. Software Installation
  `dnf install git python3`
  `python3 -m pip install pip -upgrade`

```bash
#To build AWS infrastructure to support ITOM Platform run the playbook aws-create-all
/usr/bin/ansible-playbook \
 -e stack_name=smaxdev \
 -e eks_version=1.17 \
 -e region=us-east-2 \
aws-create-all.yaml
```