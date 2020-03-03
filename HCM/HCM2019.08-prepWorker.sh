#!/bin/bash
#
# AUTHOR : chris@greenlightgroup.com
# 
# System prep for CDF Worker host used for HCM on ITOM Platform
#
#  System Size:
#    CPU: 8
#    RAM: 32 (32768MB)
#    HDD: 60, 110, 100
#

################################################################################
#####                           GLOBAL VARIABLES                           #####
################################################################################
IPADDR=$(ip address show scope global | grep 'inet' | head -n 1 | awk '{print $2}' | cut -d "/" -f 1)
ROOT_LVM_DEVICE=/dev/mapper/centos_glg--centos7-root

KUBE_DEVICE=/dev/sdb
KUBE_PART=1
KUBE_MP=/opt/kubernetes
KUBE_VG=kube
KUBE_LV=kube_lv

THINPOOL_DEVICE=/dev/sdc
THINPOOL_SIZE=100
DOCKER_THINPOOL_PART=1
DOCKER_THINPOOL_SIZE=$(expr $THINPOOL_SIZE \* 85 \/ 100)
BS_DOCKER_THINPOOL_PART=2

# Hostname resolution and IP Address assignment
#Fix /etc/hosts entry from VMware adding hostname as 127.0.1.1
sed -i "s/127.0.1.1/$IPADDR/g" /etc/hosts
sed -i -e "1i$(head -$(grep -n $IPADDR /etc/hosts | awk -F: '{print $1}') /etc/hosts | tail -1)" -e "$(grep -n $IPADDR /etc/hosts | grep -v 1: | awk -F: '{print $1}')d" /etc/hosts
sed -i "/::1/c\#::1\tlocalhost6 localhost6.localdomain6" /etc/hosts

#Turn off and disable swap
swapoff -a
sed -e "/swap/ s/^#*/#/g" -i /etc/fstab

## USER SETUP ##
groupadd -g 1999 itom
useradd -g 1999 -u 1999 itom

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

## /opt/kubernetes setup ##
#Format Disk: KUBE_DEVICE
echo "n
p
1


w
"|fdisk $KUBE_DEVICE

pvcreate $KUBE_DEVICE$KUBE_PART
vgcreate $KUBE_VG $KUBE_DEVICE$KUBE_PART
lvcreate -l +100%FREE -n $KUBE_LV $KUBE_VG

changevg -a y $KUBE_VG
mkfs -t xfs /dev/$KUBE_VG/$KUBE_LV

mkdir $KUBE_MP
mount /dev/$KUBE_VG/$KUBE_LV $KUBE_MP
echo "/dev/mapper/$KUBE_VG-$KUBE_LV $KUBE_MP xfs defaults 0 0" >> /etc/fstab

## DOCKER THINPOOL SETUP ##
#Format Disk: THINPOOL_DEVICE
echo "n
p
1

+$DOCKER_THINPOOL_SIZE G
t
8e
n
p
2


t
2
8e
w
"|fdisk $THINPOOL_DEVICE

#Create the Physical Volumes for Docker Thinpool
pvcreate $THINPOOL_DEVICE$DOCKER_THINPOOL_PART $THINPOOL_DEVICE$BS_DOCKER_THINPOOL_PART

#Create the Volume Groups for Docker Thinpool
vgcreate docker $THINPOOL_DEVICE$DOCKER_THINPOOL_PART
vgcreate bootstrap_docker $THINPOOL_DEVICE$BS_DOCKER_THINPOOL_PART

#Create the Docker Thinpool and setup the lvm profile
lvcreate --wipesignatures y -n thinpool docker -l 95%VG -y
lvcreate --wipesignatures y -n thinpoolmeta docker -l 1%VG -y
lvconvert -y --zero n -c 512K --thinpool docker/thinpool --poolmetadata docker/thinpoolmeta

cat <<EOT > /etc/lvm/profile/docker-thinpool.profile
activation {
  thin_pool_autoextend_threshold=80
  thin_pool_autoextend_percent=20
}
EOT

lvchange --metadataprofile docker-thinpool docker/thinpool 
lvs -o+seg_monitor 

#Create the Bootstrap-Docker Thinpool and setup the lvm profile
lvcreate --wipesignatures y -n thinpool bootstrap_docker -l 95%VG -y
lvcreate --wipesignatures y -n thinpoolmeta bootstrap_docker -l 1%VG -y
lvconvert -y --zero n -c 512K --thinpool bootstrap_docker/thinpool --poolmetadata bootstrap_docker/thinpoolmeta

cat <<EOT > /etc/lvm/profile/bootstrap_docker-thinpool.profile
activation {
  thin_pool_autoextend_threshold=80
  thin_pool_autoextend_percent=20
}
EOT

lvchange --metadataprofile bootstrap_docker-thinpool bootstrap_docker/thinpool 
lvs -o+seg_monitor

## SYSCTL SETTINGS ##
echo "br_netfilter" > /etc/modules-load.d/br_netfilter.conf
modprobe br_netfilter
echo "net.bridge.bridge-nf-call-iptables=1" >> /usr/lib/sysctl.d/92-Worker.conf
echo "net.bridge.bridge-nf-call-ip6tables=1" >> /usr/lib/sysctl.d/92-Worker.conf
echo "net.ipv4.ip_forward=1" >> /usr/lib/sysctl.d/92-Worker.conf
echo "net.ipv4.tcp_tw_recycle=0" >> /usr/lib/sysctl.d/92-Worker.conf
echo "kernel.sem=50100 128256000 50100 2560" >> /usr/lib/sysctl.d/92-Worker.conf
echo "vm.max_map_count=262144" >> /usr/lib/sysctl.d/92-Worker.conf && sysctl -p && sysctl -w vm.max_map_count=262144
/sbin/sysctl --system

################################################################################
#####                   INSTALLATION - REQUIRED PACKAGES                   #####
################################################################################
## Only the first master needs httpd-tools
yum install -y java-1.8.0-openjdk libgcrypt libseccomp libtool-ltdl net-tools nfs-utils rpcbind systemd-libs unzip conntrack curl lvm2 showmount socat --nogpgcheck
#yum install -y device-mapper-libs java-1.8.0-openjdk libgcrypt libseccomp libtool-ltdl net-tools nfs-utils rpcbind systemd-libs unzip conntrack-tools curl lvm2 showmount --nogpgcheck
yum list device-mapper-libs java-1.8.0-openjdk libgcrypt libseccomp libtool-ltdl.x86_64 net-tools nfs-utils rpcbind systemd-libs unzip conntrack-tools curl lvm2 showmount socat


################################################################################
#####                     SYSTEM SECURITY AND FIREWALL                     #####
################################################################################
# Ensure Firewalld is set to disabled and stopped
systemctl disable firewalld
systemctl stop firewalld
