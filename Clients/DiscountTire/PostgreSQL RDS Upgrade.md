# Discount Tire - How To - AWS RDS PostgreSQL 16 Upgrade  

## AWS RDS PostgreSQL 16 - DB Parameter Group - AIOps  

### Verify the Parameter Group for the new DB version  
> AWS Command to describe the Database Parameter Group
  If the Parameter Group does not exist this will return an error  
```
aws rds describe-db-parameters --db-parameter-group-name obm-pgsql-16 --source user --profile bsmobm

```

### Verify / Create New DB Version Parameter Group  
> Perform these steps only if the Dababase Parameter Group does **NOT** exist  
1. Create the DB Parameter Group (Only if it did NOT exist)  
```
aws rds create-db-parameter-group --db-parameter-group-name obm-pgsql-16 --db-parameter-group-family postgres16 --description "OpenText DB Param Group - AIOps" --profile bsmobm

```
2. Add the tuning parameters to the Parameter Group (Only if it did NOT exist)  
```
aws rds modify-db-parameter-group --db-parameter-group-name obm-pgsql-16 --parameters ParameterName=autovacuum_analyze_scale_factor,ParameterValue=0.2,ApplyMethod=immediate --profile bsmobm
aws rds modify-db-parameter-group --db-parameter-group-name obm-pgsql-16 --parameters ParameterName=autovacuum_analyze_threshold,ParameterValue=5000,ApplyMethod=immediate --profile bsmobm
aws rds modify-db-parameter-group --db-parameter-group-name obm-pgsql-16 --parameters ParameterName=autovacuum_vacuum_threshold,ParameterValue=5000,ApplyMethod=immediate --profile bsmobm
aws rds modify-db-parameter-group --db-parameter-group-name obm-pgsql-16 --parameters ParameterName=commit_delay,ParameterValue=500,ApplyMethod=immediate --profile bsmobm
aws rds modify-db-parameter-group --db-parameter-group-name obm-pgsql-16 --parameters ParameterName=effective_cache_size,ParameterValue=18432,ApplyMethod=immediate --profile bsmobm
aws rds modify-db-parameter-group --db-parameter-group-name obm-pgsql-16 --parameters ParameterName=log_min_duration_statement,ParameterValue=3000,ApplyMethod=immediate --profile bsmobm
aws rds modify-db-parameter-group --db-parameter-group-name obm-pgsql-16 --parameters ParameterName=maintenance_work_mem,ParameterValue=1536,ApplyMethod=immediate --profile bsmobm
aws rds modify-db-parameter-group --db-parameter-group-name obm-pgsql-16 --parameters ParameterName=max_locks_per_transaction,ParameterValue=512,ApplyMethod=pending-reboot --profile bsmobm
aws rds modify-db-parameter-group --db-parameter-group-name obm-pgsql-16 --parameters ParameterName=max_parallel_maintenance_workers,ParameterValue=4,ApplyMethod=immediate --profile bsmobm
aws rds modify-db-parameter-group --db-parameter-group-name obm-pgsql-16 --parameters ParameterName=max_parallel_workers_per_gather,ParameterValue=4,ApplyMethod=immediate --profile bsmobm
aws rds modify-db-parameter-group --db-parameter-group-name obm-pgsql-16 --parameters ParameterName=min_wal_size,ParameterValue=4096,ApplyMethod=immediate --profile bsmobm
aws rds modify-db-parameter-group --db-parameter-group-name obm-pgsql-16 --parameters ParameterName=shared_buffers,ParameterValue=6144,ApplyMethod=pending-reboot --profile bsmobm
aws rds modify-db-parameter-group --db-parameter-group-name obm-pgsql-16 --parameters ParameterName=wal_buffers,ParameterValue=16,ApplyMethod=pending-reboot --profile bsmobm
aws rds modify-db-parameter-group --db-parameter-group-name obm-pgsql-16 --parameters ParameterName=work_mem,ParameterValue=51200,ApplyMethod=immediate --profile bsmobm

```

## Perform a system backup before performaing any actions  

### Cluster Configuration Backup using Velero
> Create Velero Backup  
```
# Set the desired number of hours to keep the Velero backup
VELERO_TTL=8765h # = 1year

```
```
# Environment Specific Variables
CLUSTER_NAME=$(kubectl get cm -n core cdf --no-headers -o custom-columns=NAME:.data.EXTERNAL_ACCESS_HOST | awk -F. '{print $1}')
BACKUP_DATE=$(date +%Y%m%d-%H%M)
VELERO_BACKUP_NAME=${CLUSTER_NAME}-${BACKUP_DATE}

velero backup create -n velero --ttl ${VELERO_TTL} ${VELERO_BACKUP_NAME}

```
> Verify Velero Backup  
```
velero backup get -n velero

```

### Shared Filesystem Storage Backup using AWS CLI  
> Create EFS Backup  
1. SET the requisite Environment Variables  
```
# Set the desired number of days to keep the EFS Backup
BACKUP_DAYS=90

```
```
# Environment Specific Settings
EFS_SERVER=$(kubectl get pv itom-vol --no-headers -o custom-columns=NAME:.spec.nfs.server) && echo EFS SERVER: ${EFS_SERVER}
EFS_ID=$(echo ${EFS_SERVER} | awk -F. '{print $1}') && echo EFS ID: ${EFS_ID}
EFS_NAME=$(aws efs describe-file-systems --profile bsmobm --query "FileSystems[?FileSystemId=='${EFS_ID}'].Name" --output text) && echo EFS NAME: ${EFS_NAME}
EFS_ARN=$(aws efs describe-file-systems --profile bsmobm --query "FileSystems[?Name=='${EFS_NAME}'].FileSystemArn" --output text) && echo EFS ARN: ${EFS_ARN}
EFS_OWNER=$(aws efs describe-file-systems --profile bsmobm --query "FileSystems[?Name=='${EFS_NAME}'].OwnerId" --output text) && echo EFS OWNER: ${EFS_OWNER}

BACKUP_VAULT=$(aws backup list-backup-jobs --profile bsmobm --query "BackupJobs[?ResourceArn=='${EFS_ARN}'].BackupVaultName" --out text) && echo BACKUP VAULT: ${BACKUP_VAULT}
BACKUP_ROLE=arn:aws:iam::${EFS_OWNER}:role/service-role/AWSBackupDefaultServiceRole && echo BACKUP ROLE: ${BACKUP_ROLE}

```
2. Start the EFS Backup Job  
```
aws backup start-backup-job --profile bsmobm --backup-vault-name="${BACKUP_VAULT}" --resource-arn="${EFS_ARN}" --lifecycle="DeleteAfterDays=${BACKUP_DAYS}" --iam-role-arn="${BACKUP_ROLE}" > ~/efsbackup.out && jq -r . ~/efsbackup.out

```
3. Check the state of the EFS Backup Job  
> Do not proceed until the Backup Job State = COMPLETED
```
EFS_BACKUP_ID=$(jq -r .BackupJobId ~/efsbackup.out) && echo EFS BACKUP ID: ${EFS_BACKUP_ID}
aws backup describe-backup-job --backup-job-id ${BACKUP_ID} --profile bsmobm > ~/efsbackup.out && jq -r . ~/efsbackup.out

```

### Postres RDS Database Backup using AWS CLI  
> Create RDS Backup
1. SET the requisite Environment Variables  
```
# Environment Specific Settingts
CLUSTER_NAME=$(kubectl get cm -n core cdf --no-headers -o custom-columns=NAME:.data.EXTERNAL_ACCESS_HOST | awk -F. '{print $1}') && echo CLUSTER NAME: ${CLUSTER_NAME}
RDS_DB_NAME=$(kubectl get cm -n core default-database-configmap --no-headers -o custom-columns=NAME:.data.DEFAULT_DB_HOST | awk -F. '{print $1}') && echo DATABASE NAME: ${RDS_DB_NAME}
BACKUP_DATE=$(date +%Y%m%d-%H%M) && echo BACKUP DATE: ${BACKUP_DATE}

SNAPSHOT_NAME=${CLUSTER_NAME}-${BACKUP_DATE} && echo SNAPSHOT NAME: ${SNAPSHOT_NAME}

```
2. Start the RDS DB Snapshot  
```
aws rds create-db-snapshot --profile bsmobm --db-snapshot-identifier="${SNAPSHOT_NAME}" --db-instance-identifier="${RDS_DB_NAME}" > ~/rdsbackup.out

```
3. Check the status of the RDS DB Snapshot  
```
aws rds describe-db-snapshots --profile bsmobm --db-snapshot-identifier=${SNAPSHOT_NAME}

```

Vertica Backup


## Check the Database for Upgrade Readiness  

### Connect to the database as dbadmin  
```
DB_HOST=$(kubectl get cm -n core  default-database-configmap -o json | jq -r .data.DEFAULT_DB_HOST)
DB_NAME=$(kubectl get cm -n core  default-database-configmap -o json | jq -r .data.DEFAULT_DB_NAME)

psql -h $DB_HOST -d $DB_NAME -U dbadmin

```

### Check the current state of the DB for Upgrade readiness  
Each SQL Query should return 0 to be upgrade ready

> There should be '0' transactions  
```
SELECT count(*) FROM pg_catalog.pg_prepared_xacts;

```

> There should be '0' regtype entries  
```
SELECT count(*) FROM pg_catalog.pg_class c, pg_catalog.pg_namespace n, pg_catalog.pg_attribute a
  WHERE c.oid = a.attrelid
      AND NOT a.attisdropped
      AND a.atttypid IN ('pg_catalog.regproc'::pg_catalog.regtype,
                         'pg_catalog.regprocedure'::pg_catalog.regtype,
                         'pg_catalog.regoper'::pg_catalog.regtype,
                         'pg_catalog.regoperator'::pg_catalog.regtype,
                         'pg_catalog.regconfig'::pg_catalog.regtype,
                         'pg_catalog.regdictionary'::pg_catalog.regtype)
      AND c.relnamespace = n.oid
      AND n.nspname NOT IN ('pg_catalog', 'information_schema');

```

> There should be '0' invalid databases  
```
SELECT datname FROM pg_database WHERE datconnlimit = - 2;

```

> There should be '0' replication slots in use  
```
SELECT * FROM pg_replication_slots WHERE slot_type NOT LIKE 'physical';

```


## Drop ALL Database connections before starting the upgrade  

### Stop all connections to the database (Shutdown OpsBridge, NOM)  
> Shutdown NOM  
```
cdfctl runlevel set -l DOWN -n nom

```
> Shutdown OBM  
```
cdfctl runlevel set -l DOWN -n obm

```
> Shutdown OMT (core)  
```
cdfctl runlevel set -l DOWN -n core

```

## Upgrade DB Instance  
```
RDS_DB_ID=$(kubectl get cm -n core default-database-configmap -o json |  jq -r .data.DEFAULT_DB_HOST | awk -F. '{print $1}') && echo RDS DB ID: ${RDS_DB_ID};
RDS_DB_VERSION='16.6';

aws rds modify-db-instance --profile bsmobm --db-instance-identifier ${RDS_DB_ID} --engine-version ${RDS_DB_VERSION} --allow-major-version-upgrade --db-parameter-group-name obm-pgsql-16 --apply-immediately

```
