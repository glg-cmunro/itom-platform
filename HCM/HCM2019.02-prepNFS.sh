#!/bin/bash
#
# AUTHOR : chris@greenlightgroup.com
# 
# System prep for NFS Server host used for HCM on ITOM Platform
#

IPADDR=$(ip address show scope global | grep 'inet' | head -n 1 | awk '{print $2}' | cut -d "/" -f 1)

NFS_DEVICE=/dev/sdb
NFS_PART=1
NFS_VG=nfs
NFS_LV=nfs_lv

################################################################################
#####                     SYSTEM SECURITY AND FIREWALL                     #####
################################################################################
# Ensure Firewalld is set to disabled and stopped
systemctl disable firewalld
systemctl stop firewalld

# Hostname resolution and IP Address assignment
#Fix /etc/hosts entry from VMware adding hostname as 127.0.1.1
sed -i "s/127.0.1.1/$IPADDR/g" /etc/hosts
sed -i -e "1i$(head -$(grep -n $IPADDR /etc/hosts | awk -F: '{print $1}') /etc/hosts | tail -1)" -e "$(grep -n $IPADDR /etc/hosts | grep -v 1: | awk -F: '{print $1}')d" /etc/hosts

## SYSCTL SETTINGS ##
#echo "vm.max_map_count=262144" >> /etc/sysctl.conf && sysctl -p && sysctl -w vm.max_map_count=262144
#echo "net.ipv4.ip_forward = 1" >> /usr/lib/sysctl.d/50-default.conf
#/sbin/sysctl --system

## USER SETUP ##
groupadd -g 1999 itom
useradd -g 1999 -u 1999 itom

################################################################################
#####                      SYSTEM DISK INFRASTRUCTURE                      #####
################################################################################
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

##Install required  software for NFS Server
yum install -y device-mapper-libs java-1.8.0-openjdk libgcrypt libseccomp libtool-ltdl net-tools nfs-utils rpcbind systemd-libs unzip conntrack-tools curl lvm2 showmount httpd-tools --nogpgcheck
#yum install -y device-mapper-libs java-1.8.0-openjdk libgcrypt libseccomp libtool-ltdl net-tools nfs-utils rpcbind systemd-libs unzip conntrack-tools curl lvm2 showmount --nogpgcheck
yum list device-mapper-libs java-1.8.0-openjdk libgcrypt libseccomp libtool-ltdl net-tools nfs-utils rpcbind systemd-libs unzip conntrack-tools curl lvm2 showmount httpd-tools
