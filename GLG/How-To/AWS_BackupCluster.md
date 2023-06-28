# GreenLight Group - How To - Backup EKS Cluster and ITOM resources 
![GreenLight Group Logo](https://assets.website-files.com/5ebcb9396faf10d8f7644479/5ed6a066891af295a039860f_GLGLogolrg-p-500.png)

---

> A complete backup should be taken before making any changes to the cluster 
> This process uses Ansible playbook automation to protect AWS resources including EKS Cluster, EFS, and RDS Databases

---

- Playbook: aws-smax-upgrade-backup-all.yaml
- Required inputs: Cluster FQDN, Backup Name, RDS Snapshot Name

---

##### Steps to perform Cluster Backup

1. SSH Login to **Control Node** for the Cluster to be backed up
2. Execute Ansible playbook

> To execute the playbook update the command below with the following values depending on your environment
> - full_name
> - backup_name
> - snap_string
> > If this backup is to be taken in Production include the following additional input
> > - prod=true
> The playbook uses an Ansible vault to retrieve AWS credentials and will require the use of a Vault Password

*Example Command for testing.dev.gitops.com*  
```
ansible-playbook /opt/glg/aws-smax/ansible/playbooks/aws-smax-upgrade-backup-all.yaml \
-e full_name=testing.dev.gitops.com \
-e backup_name=basesmaxdeploy \
-e snap_string=basesmaxdeploy \
--ask-vault-pass
```

*Example Command for smax-west.gitops.com*  
```
ansible-playbook /opt/glg/aws-smax/ansible/playbooks/aws-smax-upgrade-backup-all.yaml \
-e full_name=smax-west.gitops.com \
-e backup_name=postomt202205 \
-e snap_string=postomt202205 \
--ask-vault-pass \
-e prod=true
```