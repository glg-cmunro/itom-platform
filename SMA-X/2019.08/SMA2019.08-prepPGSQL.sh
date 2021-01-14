#!/bin/bash
#
# AUTHOR : chris@greenlightgroup.com
# 
# System prep for NFS Server host used for HCM on ITOM Platform
#

################################################################################
#####                           GLOBAL VARIABLES                           #####
################################################################################
IPADDR=$(ip address show scope global | grep 'inet' | head -n 1 | awk '{print $2}' | cut -d "/" -f 1)
ROOT_LVM_DEVICE=/dev/mapper/centos_glg--centos7-root

# Hostname resolution and IP Address assignment
#Fix /etc/hosts entry from VMware adding hostname as 127.0.1.1
sed -i "s/127.0.1.1/$IPADDR/g" /etc/hosts
sed -i -e "1i$(head -$(grep -n $IPADDR /etc/hosts | awk -F: '{print $1}') /etc/hosts | tail -1)" -e "$(grep -n $IPADDR /etc/hosts | grep -v 1: | awk -F: '{print $1}')d" /etc/hosts

################################################################################
#####                   INSTALLATION - REQUIRED PACKAGES                   #####
################################################################################
## Install required  software for Database Server
yum install  https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-redhat96-9.6-3.noarch.rpm -y
yum install postgresql96 postgresql96-server postgresql96-contrib postgresql96-libs -y
su -u postgres /usr/pgsql-9.6/bin/postgresql96-setup initdb


################################################################################
#####                      SYSTEM DISK INFRASTRUCTURE                      #####
################################################################################
## Resize root disk if necessary
echo "d
2
n
p
2


t
2
8e
w
"|fdisk /dev/sda
partprobe
pvresize /dev/sda2
lvextend -l +100%FREE $ROOT_LVM_DEVICE
xfs_growfs $ROOT_LVM_DEVICE

##Initialize and enable the Postgres DB Server
#systemctl enable postgresql-9.6.service
#systemctl start postgresql-9.6.service

################################################################################
#####                     SYSTEM SECURITY AND FIREWALL                     #####
################################################################################
## Ensure Firewalld is configured properly or set to disabled and stopped
#systemctl disable firewalld
#systemctl stop firewalld
firewall-cmd --zone=public --add-port=5432/tcp --permanent
firewall-cmd --zone=public --add-port=5432/tcp
systemctl reload firewalld

### SUITE Specific: SMA
### Task: CREATE Users/Databases
sudo -u postgres psql
CREATE USER cdfidmuser login PASSWORD 'Gr33nl1ght_'; 
GRANT cdfidmuser TO postgres; 
CREATE DATABASE cdfidmdb WITH owner=cdfidmuser;
CREATE DATABASE cdfidmuser WITH owner=cdfidmuser;
CREATE DATABASE suitedb WITH owner=cdfidmuser;
\c cdfidmdb; 
ALTER SCHEMA public OWNER TO cdfidmuser;
ALTER SCHEMA public RENAME TO cdfidmschema;
REVOKE ALL ON SCHEMA cdfidmschema from public;
GRANT ALL ON SCHEMA cdfidmschema to cdfidmuser; 
ALTER USER cdfidmuser SET search_path TO cdfidmschema;

CREATE USER dbadmin login password 'Gr33nl1ght_' inherit;
#CREATE DATABASE idm with owner=dbadmin;
#CREATE DATABASE csa with owner=dbadmin;
#CREATE DATABASE oo with owner=dbadmin;
#CREATE DATABASE oodesigner with owner=dbadmin;
#CREATE DATABASE ucmdb with owner=dbadmin;
#CREATE DATABASE autopass with owner=dbadmin;
#CREATE DATABASE ara with owner=dbadmin;
\q

