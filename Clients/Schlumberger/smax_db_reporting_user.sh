##### GET DB Connection Information #####
export NS=$(kubectl get ns | grep itsma | awk '{print $1}')
export IDM_POD=$(kubectl get pod -n $NS | grep idm | head -n 1 | awk '{print $1}')
export PGPASSWORD=$(kubectl exec -n $NS $IDM_POD -c idm -- get_secret itom_itsma_db_password_secret_key | awk -F= '{print $2}')
export PGHOST=$(kubectl get cm -n $NS database-configmap -o yaml | grep idm_db_host | head -n 1 | awk '{print $2}')
export PGUSER='maas_admin'
export PGDATABASE='xservices_ems'

##### CONNECT TO DB #####
## IMPORTANT!! You must connect as the user maas_admin for access to the views within the schema
#psql -d $PGDATABASE -h $PGHOST -U $PGUSER
psql

##### VIEW PRIVELEGES ASSIGNED #####
SELECT table_catalog, table_schema, table_name, privilege_type
FROM   information_schema.table_privileges
WHERE  grantee = 'gcpdbro';

##### CREATE DB READ ONLY USER #####
CREATE USER gcpdbro WITH PASSWORD '';

##### GRANT Read Only Access to Reporting VIEWS #####
GRANT CONNECT ON DATABASE xservices_ems TO gcpdbro;
GRANT USAGE ON SCHEMA view_355598545 TO gcpdbro;
GRANT SELECT ON ALL TABLES IN SCHEMA view_355598545 TO gcpdbro;
ALTER DEFAULT PRIVILEGES FOR ROLE maas_admin IN SCHEMA view_355598545 GRANT SELECT ON TABLES TO gcpdbro;
