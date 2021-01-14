#!/bin/bash
#
# AUTHOR : chris@greenlightgroup.com
# 
# System prep for NFS Server host used for HCM on ITOM Platform
# *** For use with systems built from SA Kickstart Template ***
#
#  System Size:
#    CPU: 8
#    RAM: 16 (16384MB)
#    HDD: 50, 200
#

################################################################################
#####                           GLOBAL VARIABLES                           #####
################################################################################
IPADDR=$(ip address show scope global | grep 'inet' | head -n 1 | awk '{print $2}' | cut -d "/" -f 1)

# Hostname resolution and IP Address assignment
# Fix /etc/hosts entry
if [ `grep $IPADDR /etc/hosts -c` -eq 0 ]; then
  HOSTIP=$(head -$(grep -n `hostname` /etc/hosts | awk -F: '{print $1}') /etc/hosts | tail -1 | awk '{print $1}')
  echo Current Host IP: $HOSTIP
  echo UPDATE: /etc/hosts - From $(grep -n $HOSTIP /etc/hosts)
  sed -i "s/$HOSTIP/$IPADDR/g" /etc/hosts
  if [ $(grep -n $IPADDR /etc/hosts | awk -F: '{print $1}') -ne 1 ]; then
    sed -i -e "1i$(head -$(grep -n $IPADDR /etc/hosts | awk -F: '{print $1}') /etc/hosts | tail -1)" -e "$(grep -n $IPADDR /etc/hosts | grep -v 1: | awk -F: '{print $1}')d" /etc/hosts
  fi
  echo UPDATE: /etc/hosts - To $(grep -n $IPADDR /etc/hosts)
  sed -i "/::1/c\#::1\tlocalhost6 localhost6.localdomain6" /etc/hosts
else
  echo NO ACTION: /etc/hosts already set with - $(grep -n $IPADDR /etc/hosts)
fi


#### ITSMA Specific NFS Setup
## Make the required extra directories for SMAX
mkdir -p /var/vols/itom/itsma/global-volume
mkdir -p /var/vols/itom/itsma/db-volume
mkdir -p /var/vols/itom/itsma/db-volume-1
mkdir -p /var/vols/itom/itsma/db-volume-2
mkdir -p /var/vols/itom/itsma/smartanalytics-volume
mkdir -p /var/vols/itom/itsma/rabbitmq-infra-rabbitmq-0
mkdir -p /var/vols/itom/itsma/rabbitmq-infra-rabbitmq-1
mkdir -p /var/vols/itom/itsma/rabbitmq-infra-rabbitmq-2
mkdir -p /var/vols/itom/itsma/itsma-smarta-sawarc-con-0
mkdir -p /var/vols/itom/itsma/itsma-smarta-sawarc-con-1
mkdir -p /var/vols/itom/itsma/itsma-smarta-sawarc-con-a-0
mkdir -p /var/vols/itom/itsma/itsma-smarta-sawarc-con-a-1
mkdir -p /var/vols/itom/itsma/itsma-smarta-sawarc-dah-0
mkdir -p /var/vols/itom/itsma/itsma-smarta-saw-con-0
mkdir -p /var/vols/itom/itsma/itsma-smarta-saw-con-1
mkdir -p /var/vols/itom/itsma/itsma-smarta-saw-con-2
mkdir -p /var/vols/itom/itsma/itsma-smarta-saw-con-3
mkdir -p /var/vols/itom/itsma/itsma-smarta-saw-con-4
mkdir -p /var/vols/itom/itsma/itsma-smarta-saw-con-5
mkdir -p /var/vols/itom/itsma/itsma-smarta-saw-con-a-0
mkdir -p /var/vols/itom/itsma/itsma-smarta-saw-con-a-1
mkdir -p /var/vols/itom/itsma/itsma-smarta-saw-con-a-2
mkdir -p /var/vols/itom/itsma/itsma-smarta-saw-con-a-3
mkdir -p /var/vols/itom/itsma/itsma-smarta-saw-con-a-4
mkdir -p /var/vols/itom/itsma/itsma-smarta-saw-con-a-5
mkdir -p /var/vols/itom/itsma/itsma-smarta-saw-dah-0
mkdir -p /var/vols/itom/itsma/itsma-smarta-saw-dah-1
mkdir -p /var/vols/itom/itsma/itsma-smarta-saw-dah-2
mkdir -p /var/vols/itom/itsma/itsma-smarta-sawmeta-con-0
mkdir -p /var/vols/itom/itsma/itsma-smarta-sawmeta-con-1
mkdir -p /var/vols/itom/itsma/itsma-smarta-sawmeta-con-a-0
mkdir -p /var/vols/itom/itsma/itsma-smarta-sawmeta-con-a-1
mkdir -p /var/vols/itom/itsma/itsma-smarta-sawmeta-dah-0
mkdir -p /var/vols/itom/itsma/itsma-smarta-stx-dah-0

## Set directory ownership to ITOM user
chown 1999:1999 /var/vols/itom/itsma/*

## Edit /etc/exports and reload
cat <<EOT >> /etc/exports
## Suite Specific Volumes - SMA-X 
/var/vols/itom/itsma/global-volume *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/db-volume *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/db-volume-1 *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/db-volume-2 *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/smartanalytics-volume *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/rabbitmq-infra-rabbitmq-0 *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/rabbitmq-infra-rabbitmq-1 *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/rabbitmq-infra-rabbitmq-2 *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/itsma-smarta-sawarc-con-0 *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/itsma-smarta-sawarc-con-1 *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/itsma-smarta-sawarc-con-a-0 *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/itsma-smarta-sawarc-con-a-1 *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/itsma-smarta-sawarc-dah-0 *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/itsma-smarta-saw-con-0 *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/itsma-smarta-saw-con-1 *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/itsma-smarta-saw-con-2 *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/itsma-smarta-saw-con-3 *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/itsma-smarta-saw-con-4 *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/itsma-smarta-saw-con-5 *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/itsma-smarta-saw-con-a-0 *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/itsma-smarta-saw-con-a-1 *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/itsma-smarta-saw-con-a-2 *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/itsma-smarta-saw-con-a-3 *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/itsma-smarta-saw-con-a-4 *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/itsma-smarta-saw-con-a-5 *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/itsma-smarta-saw-dah-0 *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/itsma-smarta-saw-dah-1 *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/itsma-smarta-saw-dah-2 *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/itsma-smarta-sawmeta-con-0 *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/itsma-smarta-sawmeta-con-1 *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/itsma-smarta-sawmeta-con-a-0 *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/itsma-smarta-sawmeta-con-a-1 *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/itsma-smarta-sawmeta-dah-0 *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/itsma/itsma-smarta-stx-dah-0 *(rw,sync,anonuid=1999,anongid=1999,all_squash)
## End Suite Specific Volumes - SMA-X
EOT

## Needed if using embedded PostgreSQL
#/var/vols/itom/itsma/db-single-vol *(rw,sync,anonuid=1999,anongid=1999,all_squash)

exportfs -ra
