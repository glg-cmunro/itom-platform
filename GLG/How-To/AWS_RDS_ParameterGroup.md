#Create Parameter Group for each version of PostgreSQL

#PostgreSQL 14
aws rds create-db-parameter-group --db-parameter-group-name smax-postgres14 --db-parameter-group-family postgres14 --description "GreenLight DB Param Group - SMAX" --profile automation

aws rds describe-db-parameters --db-parameter-group-name smax-postgres14 --source user

#Set SMAX parameters
aws rds modify-db-parameter-group --db-parameter-group-name smax-postgres14 --parameters ParameterName=pg_stat_statements.max,ParameterValue=10000,ApplyMethod=pending-reboot --profile automation
aws rds modify-db-parameter-group --db-parameter-group-name smax-postgres14 --parameters ParameterName=pg_stat_statements.track,ParameterValue=ALL,ApplyMethod=immediate --profile automation
aws rds modify-db-parameter-group --db-parameter-group-name smax-postgres14 --parameters ParameterName=shared_preload_libraries,ParameterValue=pg_stat_statements,ApplyMethod=pending-reboot --profile automation
