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


## Perform complete backup

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

### EFS Backup
> Environment Variables
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

### RDS Backup
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

### Vertica DB Backup
> Create Vertica Backup
```
 . /opt/vertica/share/vbr/configs/parameters.sh
 /opt/vertica/bin/vbr.py --task backup --config-file /opt/vertica/share/vbr/configs/conf_parameter.ini

```

 /opt/vertica/bin/vbr.py --task listbackup --config-file /opt/vertica/share/vbr/configs/conf_parameter.ini


> Restore Velero Backup



> Restore EFS Backup
* Get Recovery Point to restore
```
EFS_NAME="BSMOBM-DR-FS"
EFS_ARN=$(aws efs describe-file-systems --profile bsmobm --query "FileSystems[?Name=='${EFS_NAME}'].FileSystemArn" --output text) && echo $EFS_ARN
EFS_ID=$(aws efs describe-file-systems --profile bsmobm --query "FileSystems[?Name=='${EFS_NAME}'].FileSystemId" --output text) && echo $EFS_ID
BACKUP_ROLE=arn:aws:iam::222313454062:role/service-role/AWSBackupDefaultServiceRole

aws backup list-recovery-points-by-resource --resource-arn ${EFS_ARN} --profile bsmobm
```
> Set the EFS Recovery Point to the value you want to restore  
> - EFS_RP="arn:aws:backup:us-west-2:222313454062:recovery-point:daa17de3-e3b7-49c3-90ee-741e4eece12b"

```
aws backup start-restore-job \
 --recovery-point-arn "${EFS_RP}" \
 --iam-role-arn "${BACKUP_ROLE}" \
 --metadata "newFileSystem"="False","file-system-id"="${EFS_ID}","Encrypted"="False" \
 --profile bsmobm
```

> Restore RDS Backuo
```
RDS_DATABASE=$(kubectl get cm -n core default-database-configmap -o json |  jq -r .data.DEFAULT_DB_HOST | awk -F. '{print $1}')
RDS_ARN=$(aws rds describe-db-instances --db-instance-identifier ${RDS_DB_NAME} --query "DBInstances[].DBInstanceArn" --output text  --profile bsmobm)

aws rds modify-db-instance --profile bsmobm \
 --db-instance-identifier bsmobmrds-db \
 --db-parameter-group-name obm-pgsql-13

aws rds add-tags-to-resource --profile bsmobm \
 --resource-name ${RDS_DATABASE} \
 --tags Key=Environment,Value=Development Key=CostGroup,Value=60002 Key=Name,Value=BSMOBM-DR-DB



> Delete Velero Backup

> Delete EFS Backup

> Delete RDS Backup
```
SNAPSHOT_NAME="obmdev-db-20241203"
aws rds delete-db-snapshot \
 --db-snapshot-identifier="${SNAPSHOT_NAME}" \
 --profile bsmobm

```
