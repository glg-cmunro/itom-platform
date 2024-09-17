# Step by Step - Deploy AUDIT 'feature' on SMAX Cluster 2022.11 in AWS EKS
![GreenLight Group Logo](https://assets.website-files.com/5ebcb9396faf10d8f7644479/5ed6a066891af295a039860f_GLGLogolrg-p-500.png)

---

```
export PGHOST=`kubectl get cm -n core default-database-configmap -ojson | jq -r .data.DEFAULT_DB_HOST`
psql -d xservices_ems -U dbadmin -W
```

create extension if not exists pg_trgm with schema maas_admin;

## Create sql function for Compound Indexes
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


## Create the Indexes
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

## Verify Indexes were created
SET SEARCH_PATH=maas_admin,"$user", public;
SELECT CASE WHEN pg_index.indisvalid='t' then 'VALID' else 'INVALID' END "IS VALID?", pg_indexes.indexname as "IndexName", pg_indexes.indexdef as "DEFINITION" from pg_indexes,pg_class,pg_index 
where pg_index.indexrelid = pg_class.oid and pg_class.relname=pg_indexes.indexname 
       and pg_indexes.tablename in ('entities', 'slt_targets') and pg_indexes.indexdef like '%gin_trgm_ops%' and pg_indexes.indexdef not like '%_tgrm_idx ON%' 
       order by pg_indexes.indexdef;

## Delete functions when done
SET SEARCH_PATH=maas_admin,"$user", public;
DROP FUNCTION generateSingleFieldTGRMIndex;
DROP FUNCTION generateCompoundTRGMIndex;

## Exit / Quit DB Connection
\q
