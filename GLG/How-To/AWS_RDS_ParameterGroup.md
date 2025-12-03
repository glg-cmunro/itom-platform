#Create Parameter Group for each version of PostgreSQL

#PostgreSQL 14
aws rds create-db-parameter-group --db-parameter-group-name smax-postgres14 --db-parameter-group-family postgres14 --description "GreenLight DB Param Group - SMAX" --profile automation

aws rds describe-db-parameters --db-parameter-group-name smax-postgres14 --source user

#Set SMAX parameters
aws rds modify-db-parameter-group --db-parameter-group-name smax-postgres14 --parameters ParameterName=pg_stat_statements.max,ParameterValue=10000,ApplyMethod=pending-reboot --profile automation
aws rds modify-db-parameter-group --db-parameter-group-name smax-postgres14 --parameters ParameterName=pg_stat_statements.track,ParameterValue=ALL,ApplyMethod=immediate --profile automation
aws rds modify-db-parameter-group --db-parameter-group-name smax-postgres14 --parameters ParameterName=shared_preload_libraries,ParameterValue=pg_stat_statements,ApplyMethod=pending-reboot --profile automation


#PostgreSQL 15
aws rds create-db-parameter-group --db-parameter-group-name smax-postgres15 --db-parameter-group-family postgres15 --description "GreenLight DB Param Group - SMAX" --profile oncalluser

aws rds describe-db-parameters --db-parameter-group-name smax-postgres15 --source user

#Set SMAX parameters
aws rds modify-db-parameter-group --db-parameter-group-name smax-postgres15 --parameters ParameterName=pg_stat_statements.max,ParameterValue=10000,ApplyMethod=pending-reboot --profile oncalluser
aws rds modify-db-parameter-group --db-parameter-group-name smax-postgres15 --parameters ParameterName=pg_stat_statements.track,ParameterValue=ALL,ApplyMethod=immediate --profile oncalluser
aws rds modify-db-parameter-group --db-parameter-group-name smax-postgres15 --parameters ParameterName=shared_preload_libraries,ParameterValue=pg_stat_statements,ApplyMethod=pending-reboot --profile oncalluser


# AWS RDS PostgreSQL 16 - DB Parameter Group - AIOps  
```
aws rds create-db-parameter-group --db-parameter-group-name obm-pgsql-16 --db-parameter-group-family postgres16 --description "GreenLight DB Param Group - AIOps" --profile bsmobm

```

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
```
aws rds describe-db-parameters --db-parameter-group-name obm-pgsql-16 --source user --profile bsmobm

```