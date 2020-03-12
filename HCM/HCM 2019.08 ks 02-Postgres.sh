#!/bin/bash
#
# AUTHOR : chris@greenlightgroup.com
# 
# System prep for PostgreSQL Database host used for HCM on ITOM Platform
# *** For use with systems built from SA Kickstart Template ***
#
#  System Size:
#    CPU: 8
#    RAM: 32 (32768MB)
#    HDD: 200
#

################################################################################
#####                           GLOBAL VARIABLES                           #####
################################################################################
IPADDR=$(ip address show scope global | grep 'inet' | head -n 1 | awk '{print $2}' | cut -d "/" -f 1)
ROOT_LVM_DEVICE=/dev/mapper/centos_glg--centos7-root

# Hostname resolution and IP Address assignment
#Fix /etc/hosts entry
if [ `grep $IPADDR /etc/hosts -c` -eq 0 ]; then
  echo Updating /etc/hosts with Host IP: $IPADDR
  sed -i "s/127.0.1.1/$IPADDR/g" /etc/hosts
  sed -i -e "1i$(head -$(grep -n $IPADDR /etc/hosts | awk -F: '{print $1}') /etc/hosts | tail -1)" -e "$(grep -n $IPADDR /etc/hosts | grep -v 1: | awk -F: '{print $1}')d" /etc/hosts
  sed -i "/::1/c\#::1\tlocalhost6 localhost6.localdomain6" /etc/hosts
else
  echo /etc/hosts already contains $IPADDR - NO ACTION
fi

################################################################################
#####                         DATABASE SETUP TASKS                         #####
################################################################################
### Configure Access and System Parameters
### Task: Add access from GLG Networks
cat >> /var/lib/pgsql/9.6/data/pg_hba.conf << EOF
#GLG Connections:
host    all             all             10.10.0.0/16            trust
host    all             all             10.100.0.0/16           trust
host    all             all             172.17.17.0/24          trust
EOF

### Task: Set Application parameters
sed -e "/max_connections/ s/^#*/#/g" -i /var/lib/pgsql/9.6/data/postgresql.conf
sed -e "/shared_buffers/ s/^#*/#/g" -i /var/lib/pgsql/9.6/data/postgresql.conf

cat <<EOT >> /var/lib/pgsql/9.6/data/postgresql.conf
## CDF Edits
max_connections = '1000'
listen_addresses = '*'
shared_buffers = '4GB'
work_mem = '256MB'                                          # min 64kB
maintenance_work_mem = '256MB'                              # min 1MB
effective_cache_size = '4GB'
track_counts = on
autovacuum = on
#timezone = 'UTC'
## CDF Edits
EOT
systemctl restart postgresql-9.6.service


cd /tmp #Just so there is no /root permission denied message
### SUITE Specific: HCM
### Task: CREATE Users/Databases
sudo -u postgres psql

CREATE USER cdfidmuser login PASSWORD 'Gr33nl1ght_'; 
GRANT cdfidmuser TO postgres; 
CREATE DATABASE cdfidmdb WITH owner=cdfidmuser;
\c cdfidmdb; 
ALTER SCHEMA public OWNER TO cdfidmuser;
ALTER SCHEMA public RENAME TO cdfidmschema;
REVOKE ALL ON SCHEMA cdfidmschema from public;
GRANT ALL ON SCHEMA cdfidmschema to cdfidmuser; 
ALTER USER cdfidmuser SET search_path TO cdfidmschema;
ALTER USER cdfidmuser with SUPERUSER;

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
