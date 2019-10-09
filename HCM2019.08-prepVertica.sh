#!/bin/bash
#
# AUTHOR : chris@greenlightgroup.com
# 
# System prep for Vertica DB host used for HCM on ITOM Platform
#

################################################################################
#####                           GLOBAL VARIABLES                           #####
################################################################################
IPADDR=$(ip address show scope global | grep 'inet' | head -n 1 | awk '{print $2}' | cut -d "/" -f 1)

VDB_DEVICE=/dev/sdb
VDB_PART=1
VDB_VG=vertica
VDB_LV=vertica_lv
VDB_MP=/opt/vertica

################################################################################
#####                     SYSTEM / SECURITY / FIREWALL                     #####
################################################################################
# Ensure Firewalld is set to disabled and stopped
systemctl disable firewalld
systemctl stop firewalld

# Hostname resolution and IP Address assignment
#Fix /etc/hosts entry from VMware adding hostname as 127.0.1.1
sed -i "s/127.0.1.1/$IPADDR/g" /etc/hosts
sed -i -e "1i$(head -$(grep -n $IPADDR /etc/hosts | awk -F: '{print $1}') /etc/hosts | tail -1)" -e "$(grep -n $IPADDR /etc/hosts | grep -v 1: | awk -F: '{print $1}')d" /etc/hosts

## Add 1GB of Swap Space using swapfile
dd if=/dev/zero of=/swapfile bs=1024 count=1048576
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

################################################################################
#####                      SYSTEM DISK INFRASTRUCTURE                      #####
################################################################################
## /var/vols/itom filesystem setup ##
echo "n
p
1


w
"|fdisk $VDB_DEVICE

pvcreate $VDB_DEVICE$VDB_PART
vgcreate $VDB_VG $VDB_DEVICE$VDB_PART
lvcreate -l +100%FREE -n $VDB_LV $VBD_VG

changevg -a y $VDB_VG
mkfs -t ext4 /dev/$VDB_VG/$VDB_LV

mkdir -p $VDB_MP
mount /dev/$VDB_VG/$VDB_LV $VDB_MP
echo "/dev/mapper/$VDB_VG-$VDB_LV $VDB_MP xfs defaults 0 0" >> /etc/fstab

##Install required  software for Vertica DB Server
yum install -y dialog
