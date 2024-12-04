
## Maintenance Activites

<details><summary>Start / Stop EC2 Instance(s)</summary>

### Stop EC2 Instance
> Stop Instance
```
aws ec2 stop-instances --instance-ids i-0c359c2ea1fcae2f2 --profile bsmobm  #DR Vertica MC
```
### Start EC2 Instance
> Start Instance
```
aws ec2 start-instances --instance-ids i-0c359c2ea1fcae2f2 --profile bsmobm  #DR Vertica MC
```
</details>


## Complete K8s Cluster Backup

<details><summary>Velero Backup</summary>

### Create K8s cluster backup using Velero
> Create Velero Backup
```
VELERO_TTL=8765h
VELERO_BACKUP_NAME=obmdev-20241203
velero backup create -n core \
 --ttl ${VELERO_TTL} \
 ${VELERO_BACKUP_NAME}

```

</details>
<details><summary>Persistent Filestore Backup</summary>

### Create Persistent Filestore backup - AWS EFS
- Environment specific settings
```
BACKUP_DAYS=90
BACKUP_VAULT=trtc-strong-encrypted-vault
BACKUP_ROLE=arn:aws:iam::222313454062:role/service-role/AWSBackupDefaultServiceRole
EFS_NAME="BSMOBM-DR-FS"
EFS_ARN=$(aws efs describe-file-systems --profile bsmobm --query "FileSystems[?Name=='${EFS_NAME}'].FileSystemArn" --output text) && echo $EFS_ARN
EFS_ID=$(aws efs describe-file-systems --profile bsmobm --query "FileSystems[?Name=='${EFS_NAME}'].FileSystemId" --output text) && echo $EFS_ID

```

> Create EFS Backup
```
aws backup start-backup-job --profile bsmobm \
 --backup-vault-name="${BACKUP_VAULT}" \
 --resource-arn="${EFS_ARN}" \
 --lifecycle="DeleteAfterDays=${BACKUP_DAYS}" \
 --iam-role-arn="${BACKUP_ROLE}"

```

</details>
<details><summary>Database Backup</summary>

### Create Database backup - AWS RDS
> Create RDS Backup
```
SNAPSHOT_NAME="obmdev-db-20241203"
RDS_DB_NAME=$(kubectl get cm -n core default-database-configmap -o json |  jq -r .data.DEFAULT_DB_HOST | awk -F. '{print $1}')

aws rds create-db-snapshot --profile bsmobm \
 --db-snapshot-identifier="${SNAPSHOT_NAME}" \
 --db-instance-identifier="${RDS_DB_NAME}"

```

</details>
<details><summary>Vertica Backup</summary>

### Create Vertica DB backup

> Create Vertica Backup  
*_On a Vertica DB Host as dbadmin_*  
```
 . /opt/vertica/share/vbr/configs/parameters.sh; 
 /opt/vertica/bin/vbr.py --task backup --config-file /opt/vertica/share/vbr/configs/conf_parameter.ini

```

 /opt/vertica/bin/vbr.py --task listbackup --config-file /opt/vertica/share/vbr/configs/conf_parameter.ini

</details>

## Perform Complete Restore  
---

> Shutdown ALL application components before starting the restore
- shutdown NOM
```
cdfctl runlevel set -l DOWN -n nom

```
- shutdown OpsBridge
```
cdfctl runlevel set -l DOWN -n obm

```
- shutdown OMT
```
cdfctl runlevel set -l DOWN -n core

```

<details><summary>Persistent Filestore Restore</summary>

### Restpre Persistent Filestore from backup - AWS EFS
- Environment specific settings  
```
EFS_NAME="BSMOBM-DR-FS"
EFS_ARN=$(aws efs describe-file-systems --profile bsmobm --query "FileSystems[?Name=='${EFS_NAME}'].FileSystemArn" --output text) && echo $EFS_ARN
EFS_ID=$(aws efs describe-file-systems --profile bsmobm --query "FileSystems[?Name=='${EFS_NAME}'].FileSystemId" --output text) && echo $EFS_ID
BACKUP_ROLE=arn:aws:iam::222313454062:role/service-role/AWSBackupDefaultServiceRole

```

- Get Recovery Points available for the restore
```
aws backup list-recovery-points-by-resource --resource-arn ${EFS_ARN} --profile bsmobm

```

- Set the EFS Recovery Point to the value you want to restore  
> - EFS_RP="arn:aws:backup:us-west-2:222313454062:recovery-point:daa17de3-e3b7-49c3-90ee-741e4eece12b"

```
aws backup start-restore-job \
 --recovery-point-arn "${EFS_RP}" \
 --iam-role-arn "${BACKUP_ROLE}" \
 --metadata "newFileSystem"="False","file-system-id"="${EFS_ID}","Encrypted"="False" \
 --profile bsmobm

```

- replace current files with restored
```
mv /mnt/efs/var /mnt/efs/var.deleteme
mv /mnt/efs/var/aws-backup-*/var /mnt/efs/

```

</details>

<details><summary>Database Restore</summary>

### Restore RDS Backuo
- rename Database
```
RDS_DB_NAME=$(kubectl get cm -n core default-database-configmap -o json |  jq -r .data.DEFAULT_DB_HOST | awk -F. '{print $1}')
RDS_ARN=$(aws rds describe-db-instances --db-instance-identifier ${RDS_DB_NAME} --query "DBInstances[].DBInstanceArn" --output text  --profile bsmobm)

aws rds modify-db-instance --profile bsmobm \
 --db-instance-identifier ${RDS_DB_NAME} \
 --new-db-instance-identifier ${RDS_DB_NAME}-bak \
 --apply-immediately

```

- restore DB from snapshot
> You will need to retrieve some settings from the existing DB before you can restore a snapshot
> These can be found in the cloud formation template that was used to create the DB initially  
>  - RDS Security Group IDs
>  - RDS Subnet Group Name
>  - RDS DB Parameter Group
```
RDS_DB_NAME=bsmobm-qa2dr
RDS_DB_SN_GROUP=bsmobm-dr-db-rdssubnetgroup-kfv4t98rrb4l
RDS_DB_SEC_GROUPS=sg-0d1955adf7826ced8
SNAPSHOT_RESTORE_NAME="obmdev-db-20241203"

aws rds restore-db-instance-from-db-snapshot --profile bsmobm \
  --db-instance-identifier ${RDS_DB_NAME} \
  --db-snapshot-identifier ${SNAPSHOT_RESTORE_NAME} \
  --db-subnet-group-name ${RDS_DB_SN_GROUP} \
  --db-parameter-group-name obm-pgsql-13 \
  --vpc-security-group-ids ${RDS_DB_SEC_GROUPS}

```

</details>

<details><summary>K8s Cluster Restore</summary>

> Restore Velero Backup
- Get the name of the velero backup to be restored
```
velero backup get -n core

```

- Create a restore using the specified backup
```
VELERO_BACKUP_NAME=obmdev-20241203

velero restore create -n core --exclude-namespaces "default,kube-system,kube-public,kube-node-lease" --from-backup ${VELERO_BACKUP_NAME}

```

</details>



> Delete Velero Backup

> Delete EFS Backup

> Delete RDS Backup
```
SNAPSHOT_NAME="obmdev-db-20241203"
aws rds delete-db-snapshot \
 --db-snapshot-identifier="${SNAPSHOT_NAME}" \
 --profile bsmobm

```
