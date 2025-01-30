### Create OMT Database
```
psql -h ${RDS_HOSTNAME} -U dbadmin -d postgres
```
#### Delete if exists (Cleanup/Remove)
```
DROP DATABASE IF EXISTS cdfidm;
DROP ROLE IF EXISTS cdfidm;
DROP DATABASE IF EXISTS cdfapiserverdb;
DROP ROLE IF EXISTS cdfapiserver;
```
```
CREATE USER cdfapiserver login PASSWORD 'Gr33nl1ght_'; 
GRANT cdfapiserver to dbadmin; 
CREATE DATABASE cdfapiserverdb WITH owner=cdfapiserver;
```
```
CREATE USER cdfidm login PASSWORD 'Gr33nl1ght_'; 
GRANT cdfidm to dbadmin; 
CREATE DATABASE cdfidm WITH owner=cdfidm;
```
```
\c cdfidm; 
```
```
CREATE SCHEMA cdfidmschema AUTHORIZATION cdfidm; 
GRANT ALL ON SCHEMA cdfidmschema to cdfidm; 
ALTER USER cdfidm SET search_path TO cdfidmschema;
```
```
\q
```