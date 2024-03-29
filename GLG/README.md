![GreenLight Group Logo](https://assets.website-files.com/5ebcb9396faf10d8f7644479/5ed6a066891af295a039860f_GLGLogolrg-p-500.png)

System Requirements to execute these playbooks include:
1. Software Installation
 - `dnf install git python3`
 - `python3 -m pip install pip -upgrade`
 - `python3 -m pip install ansible`
 - `python3 -m pip install botocore boto3`

```bash
#To build AWS infrastructure to support ITOM Platform run the playbook aws-create-all
/usr/bin/ansible-playbook \
 -e stack_name=smaxdev \
 -e eks_version=1.17 \
 -e region=us-east-2 \
aws-create-all.yaml
```
- [ ] [Issue #1](https://github.com/glg-cmunro/itom-platform/issues/1#issue-1001883552)
- [X] Configure Users and Groups (Docker)
- [ ] Configure AWS CLI Profile



![GITOpS Logo](https://assets.website-files.com/5ebcb9396faf10d8f7644479/5ed5437092c32b4b714ab581_GLG_GITOPS_logo.png)
