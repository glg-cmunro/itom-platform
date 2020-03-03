#!/bin/bash
#
# AUTHOR : chris@greenlightgroup.com
# 
# Clean and re-prep existing Postgres DB server for rebuild of ITOM Platform
#
cd /tmp

### SUITE Specitic: HCM
### Task: CREATE Users/Databases
sudo -u postgres psql
DROP DATABASE IF EXISTS idm;
DROP DATABASE IF EXISTS csa;
DROP DATABASE IF EXISTS oo;
DROP DATABASE IF EXISTS oodesigner;
DROP DATABASE IF EXISTS ucmdb;
DROP DATABASE IF EXISTS autopass;
DROP DATABASE IF EXISTS ara;
DROP USER IF EXISTS hcmadmin;

DROP DATABASE IF EXISTS cdfidmdb;
DROP DATABASE IF EXISTS cdfidmuser;
DROP DATABASE IF EXISTS suitedb;
ALTER USER cdfidmuser with SUPERUSER;
CREATE DATABASE cdfidmdb WITH owner=cdfidmuser;
CREATE DATABASE cdfidmuser WITH owner=cdfidmuser;
CREATE DATABASE suitedb WITH owner=cdfidmuser;

CREATE USER hcmadmin login password 'Gr33nl1ght_' inherit;
ALTER USER hcmadmin with SUPERUSER;
CREATE DATABASE idm with owner=hcmadmin;
CREATE DATABASE csa with owner=hcmadmin;
CREATE DATABASE oo with owner=hcmadmin;
CREATE DATABASE oodesigner with owner=hcmadmin;
CREATE DATABASE ucmdb with owner=hcmadmin;
CREATE DATABASE autopass with owner=hcmadmin;
CREATE DATABASE ara with owner=hcmadmin;
\q
