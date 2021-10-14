##### GET DB Connection Information #####
export NS=$(kubectl get ns | grep itsma | awk '{print $1}')
export IDM_POD=$(kubectl get pod -n $NS | grep idm | head -n 1 | awk '{print $1}')
export ITSMA_DBHOST=$(kubectl get cm -n $NS database-configmap -o yaml | grep idm_db_host | head -n 1 | awk '{print $2}')
export ITSMA_DBPORT=$(kubectl get cm -n $NS database-configmap -o yaml | grep idm_db_port | head -n 1 | awk 'gsub(/"/,"")' | awk '{print $2}')
export PGPASSWORD=$(kubectl exec -n $NS $IDM_POD -c idm -- get_secret itom_itsma_db_password_secret_key | awk -F= '{print $2}')

##### CONNECT TO DB #####
psql -d xservices_ems -h $ITSMA_DBHOST -U maas_admin

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
