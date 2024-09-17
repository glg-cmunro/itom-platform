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
