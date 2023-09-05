# GreenLight Group - How To - Upgrade EKS Cluster fpr ITOM Platform 
![GreenLight Group Logo](https://assets.website-files.com/5ebcb9396faf10d8f7644479/5ed6a066891af295a039860f_GLGLogolrg-p-500.png)

---

> A complete backup should be taken before making any changes to the cluster 
> This process uses Ansible playbook automation to protect AWS resources including EKS Cluster, EFS, and RDS Databases

---

### Backup Cluster and SUITE before making any changes
> [AWS Backup Cluster](./AWS_BackupCluster.md)

---

## Steps to perform Cluster Upgrade

### Update Cluster vars file
> Edit the vars file to set the new version of EKS and save it before running the ansible playbooks  
```
vi /opt/glg/aws-smax/ansible/vars/testing.dev.gitops.com
```

### Update EKS Cluster
```
#For testing
ansible-playbook /opt/glg/aws-smax/ansible/playbooks/aws-infra-cf-eks.yaml -e full_name=testing.dev.gitops.com

#For smax-west
ansible-playbook /opt/glg/aws-smax/ansible/playbooks/aws-infra-cf-eks.yaml -e full_name=smax-west.gitops.com -e prod=true
```

### Update EKS Worker NodeGroup
```
#For testing
ansible-playbook /opt/glg/aws-smax/ansible/playbooks/aws-infra-cf-eks-nodes.yaml -e full_name=testing.dev.gitops.com

#For smax-west
ansible-playbook /opt/glg/aws-smax/ansible/playbooks/aws-infra-cf-eks-nodes.yaml -e full_name=smax-west.gitops.com -e prod=true
```

#TODO:
#Cordon old workers and perform a rolling restart of everything to avoid downtime

### Remove old EKS Worker NodeGroup
```
#For testing
ansible-playbook /opt/glg/aws-smax/ansible/playbooks/aws-infra-cf-eks-nodes.yaml -e full_name=testing.dev.gitops.com -e eks_version=1.23 -e theState=absent

#For smax-west
ansible-playbook /opt/glg/aws-smax/ansible/playbooks/aws-infra-cf-eks-nodes.yaml -e full_name=smax-west.gitops.com -e prod=true
```

### IF rabbitmq is not ready
```
kubectl scale statefulset infra-rabbitmq -n $NS --replicas=0
```

```
sudo mv /mnt/efs/var/vols/itom/itsma/rabbitmq-infra-rabbitmq-0/data/xservices/rabbitmq/*/mnesia /tmp/rabbitmq-0
sudo mv /mnt/efs/var/vols/itom/itsma/rabbitmq-infra-rabbitmq-1/data/xservices/rabbitmq/*/mnesia /tmp/rabbitmq-1
sudo mv /mnt/efs/var/vols/itom/itsma/rabbitmq-infra-rabbitmq-2/data/xservices/rabbitmq/*/mnesia /tmp/rabbitmq-2
```

```
kubectl scale statefulset infra-rabbitmq -n $NS --replicas=3
```

Check the Status of the upgrade
```
aws eks describe-update --region use-east-1 --name testing --update-id 9d732ef4-2df6-41b6-aa39-bdaa186c0493
```

1. SSH Login to the **Control Node** for the Cluster to be backed up
2. Execute Ansible playbook

> To execute the playbook update the command below with the following values depending on your environment
> - full_name (FQDN of the cluster)
> - backup_name (Name used in Velero to identify the backup. **This must be unique**)
> - snap_string (Name used in AWS RDS to identify the backup/snapshot. **This must be unique**)
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

##### Steps to verify backup is complete

1. Verify Velero backup
```
velero get backup -n velero
```
Check for your backup and look for the STATUS 'Completed'  
![Velero Backups](./images/AWS_BackupCluster-veleroBackup.png)

2. Verify EFS backup
3. Verify RDS backup
