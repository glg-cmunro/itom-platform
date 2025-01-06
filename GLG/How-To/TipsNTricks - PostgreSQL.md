# ![GreenLight Group Logo](https://assets.website-files.com/5ebcb9396faf10d8f7644479/5ed6a066891af295a039860f_GLGLogolrg-p-500.png)
# GreenLight Group - Tips N' Tricks - PostgreSQL commands

---

### PostgreSQL stats statements

SELECT
  schemaname, relname,
  last_vacuum, last_autovacuum,
  vacuum_count, autovacuum_count
FROM pg_stat_user_tables;


### Table Size by Database
SELECT
    table_name,
    pg_size_pretty(table_size) AS table_size,
    pg_size_pretty(indexes_size) AS indexes_size,
    pg_size_pretty(total_size) AS total_size
FROM (
    SELECT
        table_name,
        pg_table_size(table_name) AS table_size,
        pg_indexes_size(table_name) AS indexes_size,
        pg_total_relation_size(table_name) AS total_size
    FROM (
        SELECT ('"' || table_schema || '"."' || table_name || '"') AS table_name
        FROM information_schema.tables
    ) AS all_tables
    ORDER BY total_size DESC
) AS pretty_sizes;


SELECT pg_size_pretty( pg_database_size('dbname') );
SELECT pg_size_pretty( pg_database_size('oocentraldb') );


### PostgreSQL backup using pg_dump
Our biggest table contains raw image data in form of a bytea column.

When we did a simple COPY from psql on this table to stdout, it was quite fast (1 or 2 minutes), but it was very slow with the pg_dump. It took ~60 minutes.

So investigating this I stumbled across this discussion. It seems that the pg_dump compression is rather slow if data is already compressed as it is with image data in a bytea format. And it is better to compress outside of pg_dump (-Z0).

Additionally we found that we can make use of our multi-core cpu (-j 10 and pigz -p 10 to use 10 cores. you might select a different number of cores).

So now we are doing it like this:

```
pg_dump -Z0 -j 10 -Fd database_name -f dumpdir
tar -cf - dumpdir | pigz -p 10 > dumpdir.tar.gz
rm -r dumpdir
```
*_The time has dropped from ~70 minutes to ~5 minutes. Quite amazing._*

You can restore it like this:

```
mkdir -p dumpdir
pigz -p 10 -dc dumpdir.tar.gz | tar -C dumpdir --strip-components 1 -xf -
pg_restore -j 10 -Fd -O -d database_name dumpdir
```


### OPTIC Cluster - Operations Bridge SUITE
AppHub settings for OpsBridge:

Capabilities:
    Stakeholder Dashboards
    Automatic Event Correlation (aec)
    Operations Bridge Manager (omi)
    OPTIC Reporting
      Agent Metric Collector

Databases:
    Feature                     DB                  User
    OPTIC Provider              idm                 idm
    OPTIC Provider              apls                autopass
    Stakeholder Dashboards      bvd                 bvd
    Operations Bridge Manager   obm_event           obm_event
    Operations Bridge Manager   obm_mgmt            obm_mgmt
    Operations Bridge Manager   obm_rtsm            obm_rtsm
    OPTIC Reporting             monitoringadmin     monitoringadminuser
    OPTIC Reporting             credentialmanager   credentialmanageruser
    OPTIC Reporting             monitoringsnf       monitoringsnfuser

```
-- For OPTIC Reporting
CREATE USER monitoringadminuser with encrypted password '<PASSWORD HERE>';
GRANT monitoringadminuser TO postgres;
CREATE DATABASE monitoringadmin;
\c monitoringadmin;
GRANT ALL PRIVILEGES ON DATABASE monitoringadmin TO monitoringadminuser;
ALTER SCHEMA public RENAME TO monitoringadminschema;

CREATE USER credentialmanageruser with encrypted password '<PASSWORD HERE>';
GRANT credentialmanageruser TO postgres;
CREATE DATABASE credentialmanager;
\c credentialmanager;
GRANT ALL PRIVILEGES ON DATABASE credentialmanager TO credentialmanageruser;
ALTER SCHEMA public RENAME TO credentialmanagerdbschema;

CREATE USER monitoringsnfuser with encrypted password '<PASSWORD HERE>';
GRANT monitoringsnfuser TO postgres;
CREATE DATABASE monitoringsnf;
\c monitoringsnf;
GRANT ALL PRIVILEGES ON DATABASE monitoringsnf TO monitoringsnfuser;
```







### SMAX PG Indexes (2022.11)
To improve system performance and stability when you use this feature, you must perform the following tasks on the Service Management database instance before upgrading the suite.

#Login to the xservices_ems database for the cluster using psql
psql -h <SMAX_RDS_DB_HOST> -d xservices_ems -U dbadmin -W

#Create the Index functions
create extension if not exists pg_trgm with schema maas_admin;
SET SEARCH_PATH=maas_admin,"$user", public;
CREATE OR REPLACE FUNCTION generateSingleFieldTGRMIndex(p_entity_name varchar, logical_field varchar)
  RETURNS text  AS
$BODY$
DECLARE
  v_table_ddl   text;
  v_version     text;
BEGIN 
SELECT MAX(tenant_id) INTO v_version FROM "entity_descriptor" WHERE LENGTH(tenant_id)=3;
CASE 
  WHEN  p_entity_name='ServiceLevelTarget'  THEN
    SELECT 'CREATE INDEX IF NOT EXISTS slt_targets_trgm_'||id||'_entity_type ON slt_targets USING gin (entity_type gin_trgm_ops) WHERE (is_deleted = false)' into v_table_ddl
      FROM entity_descriptor where tenant_id=v_version and name=p_entity_name;
  ELSE
    SELECT 'CREATE INDEX IF NOT EXISTS entities_trgm_'||ed.id||'_'||em.physical_type_name||' ON entities USING gin ('||em.physical_type_name||' gin_trgm_ops) WHERE ((entity_type_id = '||ed.id||') AND (is_deleted = false))' into v_table_ddl
      FROM entityDescriptor_mapping em join entity_descriptor ed on (ed.name = em.entity_type and ed.tenant_id = em.tenant_id)
    WHERE em.entity_type = p_entity_name and em.logical_type_name = logical_field and em.tenant_id = v_version and ed.name = em.entity_type;
  END CASE;
  execute format(v_table_ddl);
  --RAISE NOTICE 'Value: %', v_table_ddl;
  RETURN v_table_ddl;
END;
$BODY$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION generateCompoundTRGMIndex(p_entity_name varchar, p_fields text[])
  RETURNS text AS
$BODY$
DECLARE
column_record record;
  v_table_ddl   text;
  v_index_name  text;
  v_version     text;
  v_expr        text;
  v_field       text ;
  v_where_condition text;
  v_table_name      text;
v_head        text := 'CREATE INDEX IF NOT EXISTS ';
BEGIN
  SELECT MAX(tenant_id) INTO v_version FROM "entity_descriptor" WHERE LENGTH(tenant_id)=3;
  FOR column_record IN
  SELECT ed.id as entity_type_id, ed.name as entity_name, em.logical_type_name as logical_name, em.physical_type_name as physical_type_name
  FROM entityDescriptor_mapping em join entity_descriptor ed on (ed.name = em.entity_type and ed.tenant_id = em.tenant_id)
  WHERE em.entity_type = p_entity_name and em.logical_type_name::text = any(p_fields) and em.tenant_id = v_version and ed.name = em.entity_type
  ORDER by array_positions(p_fields, em.logical_type_name::text)
  LOOP
    --RAISE NOTICE 'Value: %',column_record.logical_name;
      IF column_record.logical_name = p_fields[1]::text THEN
        v_index_name := 'entities_trgm_'||column_record.entity_type_id||'_'||column_record.physical_type_name;
v_expr := 'COALESCE('||column_record.physical_type_name||', ''''::character varying)::text';
      ELSE
        v_index_name := v_index_name||column_record.physical_type_name;
        IF column_record.logical_name = p_fields[array_length(p_fields,1)] THEN
          v_expr := '('||v_expr||' || e''\x06''::text) || '||'COALESCE('||column_record.physical_type_name||', ''''::character varying)::text';        
        ELSE
          v_expr := '(('||v_expr||' || e''\x06''::text) || '||'COALESCE('||column_record.physical_type_name||', ''''::character varying)::text)';
       END IF;
     END IF;
  END LOOP;
  v_table_name :=  'entities';
  v_where_condition := 'entity_type_id = '||column_record.entity_type_id||' AND is_deleted = false';
  v_table_ddl := v_head||v_index_name||' ON '||v_table_name||' USING gin (('||v_expr||') gin_trgm_ops) WHERE '||v_where_condition||';';

  execute format(v_table_ddl);
  RETURN v_table_ddl;
END;
$BODY$
LANGUAGE 'plpgsql';

#Create Indexes
SET SEARCH_PATH=maas_admin,"$user", public;
select generateSingleFieldTGRMIndex('Request', 'DisplayLabel');
select generateSingleFieldTGRMIndex('Request', 'ExternalProcessReference');
select generateSingleFieldTGRMIndex('Incident', 'DisplayLabel');
select generateSingleFieldTGRMIndex('Incident', 'ExternalProcessReference');
select generateSingleFieldTGRMIndex('Change', 'DisplayLabel');
select generateSingleFieldTGRMIndex('Change', 'ExternalProcessReference');
select generateSingleFieldTGRMIndex('Device', 'DisplayLabel');
select generateSingleFieldTGRMIndex('SystemElement', 'DisplayLabel');
select generateSingleFieldTGRMIndex('Person', 'Name');
select generateSingleFieldTGRMIndex('Person', 'FirstName');
select generateSingleFieldTGRMIndex('Person', 'LastName');
select generateSingleFieldTGRMIndex('Person', 'Email');
select generateSingleFieldTGRMIndex('Person', 'EmployeeNumber');
select generateSingleFieldTGRMIndex('PersonGroup', 'Name');
select generateSingleFieldTGRMIndex('Location', 'DisplayLabel');
select generateSingleFieldTGRMIndex('Location', 'Name');
select generateSingleFieldTGRMIndex('Location', 'Code');
select generateSingleFieldTGRMIndex('ITProcessRecordCategory', 'DisplayLabel');
select generateSingleFieldTGRMIndex('ITProcessRecordCategory', 'Level1Parent');
select generateSingleFieldTGRMIndex('ITProcessRecordCategory', 'Level2Parent');
select generateSingleFieldTGRMIndex('DashboardDefinition', 'Name');
select generateSingleFieldTGRMIndex('Task', 'DisplayLabelKey');
select generateSingleFieldTGRMIndex('Task', 'ParentEntityId');
select generateSingleFieldTGRMIndex('CostCenter', 'DisplayLabel');
select generateSingleFieldTGRMIndex('CostCenter', 'Code');
select generateSingleFieldTGRMIndex('Article', 'Title');
select generateSingleFieldTGRMIndex('Offering', 'DisplayLabel');
select generateSingleFieldTGRMIndex('AssetModel', 'DisplayLabel');
select generateSingleFieldTGRMIndex('ServiceLevelTarget', 'EntityType');
select generateCompoundTRGMIndex('Person', array['Name','LastName','FirstName','EmployeeNumber','Email']);
select generateCompoundTRGMIndex('ITProcessRecordCategory',array['DisplayLabel','Level1Parent','Level2Parent']);
select generateCompoundTRGMIndex('Location', array['Name','DisplayLabel','Code']);

#Verify Indexes
##This will show 32 Indexes, each should show ‘valid’;
SET SEARCH_PATH=maas_admin,"$user", public;
SELECT CASE WHEN pg_index.indisvalid='t' then 'VALID' else 'INVALID' END "IS VALID?", pg_indexes.indexname as "IndexName", pg_indexes.indexdef as "DEFINITION" from pg_indexes,pg_class,pg_index 
where pg_index.indexrelid = pg_class.oid and pg_class.relname=pg_indexes.indexname 
       and pg_indexes.tablename in ('entities', 'slt_targets') and pg_indexes.indexdef like '%gin_trgm_ops%' and pg_indexes.indexdef not like '%_tgrm_idx ON%' 
       order by pg_indexes.indexdef;

#Drop Index functions
SET SEARCH_PATH=maas_admin,"$user", public;
DROP FUNCTION generateSingleFieldTGRMIndex;
DROP FUNCTION generateCompoundTRGMIndex;
