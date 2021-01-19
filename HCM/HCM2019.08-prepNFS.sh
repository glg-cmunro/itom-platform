#!/bin/bash
#
# AUTHOR : chris@greenlightgroup.com
# 
# System prep for NFS Server host used for HCM on ITOM Platform
#
#  System Size:
#    CPU: 8
#    RAM: 16 (16384MB)
#    HDD: 50, 200
#

IPADDR=$(ip address show scope global | grep 'inet' | head -n 1 | awk '{print $2}' | cut -d "/" -f 1)
ROOT_LVM_DEVICE=/dev/mapper/centos_glg--centos7-root

NFS_DEVICE=/dev/sdb
NFS_PART=1
NFS_VG=nfs
NFS_LV=nfs_lv

################################################################################
#####                   INSTALLATION - REQUIRED PACKAGES                   #####
################################################################################
## Install required  software for NFS Server
yum install -y net-tools nfs-utils rpcbind unzip conntrack-tools curl lvm2 showmount --nogpgcheck
yum list net-tools nfs-utils rpcbind unzip conntrack-tools curl lvm2 showmount

# Hostname resolution and IP Address assignment
#Fix /etc/hosts entry from VMware adding hostname as 127.0.1.1
sed -i "s/127.0.1.1/$IPADDR/g" /etc/hosts
sed -i -e "1i$(head -$(grep -n $IPADDR /etc/hosts | awk -F: '{print $1}') /etc/hosts | tail -1)" -e "$(grep -n $IPADDR /etc/hosts | grep -v 1: | awk -F: '{print $1}')d" /etc/hosts
sed -i "/::1/c\::1\tlocalhost6 localhost6.localdomain6" /etc/hosts

## USER SETUP ##
#groupadd -g 1999 itom
#useradd -g 1999 -u 1999 itom

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

## /var/vols/itom filesystem setup ##
echo "n
p
1


w
"|fdisk $NFS_DEVICE

pvcreate $NFS_DEVICE$NFS_PART
vgcreate $NFS_VG $NFS_DEVICE$NFS_PART
lvcreate -l +100%FREE -n $NFS_LV $NFS_VG

changevg -a y $NFS_VG
mkfs -t xfs /dev/$NFS_VG/$NFS_LV

mkdir -p /var/vols/itom
mount /dev/$NFS_VG/$NFS_LV /var/vols/itom
echo "/dev/mapper/$NFS_VG-$NFS_LV /var/vols/itom                   xfs     defaults        0 0" >> /etc/fstab

#CDF Common volumes

#HCM Specific
mkdir -p /var/vols/itom/hcm/core
mkdir -p /var/vols/itom/hcm/hcm-vol-claim
mkdir -p /var/vols/itom/hcm/db-backup-vol
mkdir -p /var/vols/itom/hcm/itom-logging-vol
#SMA-X Specific
mkdir -p /var/vols/itom/itsma/core
mkdir -p /var/vols/itom/itsma/db-backup-vol
mkdir -p /var/vols/itom/itsma/itom-logging-vol
mkdir -p /var/vols/itom/itsma/global-volume
mkdir -p /var/vols/itom/itsma/smartanalytics-volume
mkdir -p /var/vols/itom/itsma/rabbitmq-infra-rabbitmq-0
mkdir -p /var/vols/itom/itsma/rabbitmq-infra-rabbitmq-1
mkdir -p /var/vols/itom/itsma/rabbitmq-infra-rabbitmq-2


#DCA Specific

chmod -R 755 /var/vols/itom/*
chown -R 1999:1999 /var/vols/itom/*

cat <<EOT > /etc/exports
/var/vols/itom/hcm/core *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/hcm/hcm-vol-claim *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/hcm/db-backup-vol *(rw,sync,anonuid=1999,anongid=1999,all_squash)
/var/vols/itom/hcm/itom-logging-vol *(rw,sync,anonuid=1999,anongid=1999,all_squash)
EOT
exportfs -ra

## SYSCTL SETTINGS ##
echo -e "\n# NFS workaround for Red Hat bug 1552203\nfs.leases-enable=0" >> /etc/sysctl.conf ; sysctl -p
sed -i 's/#RPCNFSDCOUNT=16/RPCNFSDCOUNT=16/g' /etc/sysconfig/nfs

################################################################################
#####                     SYSTEM SECURITY AND FIREWALL                     #####
################################################################################
## Ensure Firewalld is configured properly or set to disabled and stopped
#systemctl disable firewalld
#systemctl stop firewalld
firewall-cmd --zone=public --add-service=nfs --permanent
firewall-cmd --zone=public --add-service=nfs
systemctl reload firewalld

systemctl enable rpcbind
systemctl restart rpcbind
systemctl enable nfs-server
systemctl restart nfs-server
