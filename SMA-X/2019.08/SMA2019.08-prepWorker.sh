#!/bin/bash
#
# AUTHOR : chris@greenlightgroup.com
# 
# System prep for CDF Worker host used for HCM on ITOM Platform
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
DOCKER_THINPOOL_PART=1
BS_DOCKER_THINPOOL_PART=2

#Turn off and disable swap
swapoff -a

# Hostname resolution and IP Address assignment
#Fix /etc/hosts entry from VMware adding hostname as 127.0.1.1
sed -i "s/127.0.1.1/$IPADDR/g" /etc/hosts
sed -i -e "1i$(head -$(grep -n $IPADDR /etc/hosts | awk -F: '{print $1}') /etc/hosts | tail -1)" -e "$(grep -n $IPADDR /etc/hosts | grep -v 1: | awk -F: '{print $1}')d" /etc/hosts

## USER SETUP ##
groupadd -g 1999 itsma
useradd -g 1999 -u 1999 itsma

################################################################################
#####                      SYSTEM DISK INFRASTRUCTURE                      #####
################################################################################
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

+90G
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
#echo "net.ipv4.tcp_tw_reuse=1" >> /usr/lib/sysctl.d/90-CDF.conf
echo "net.core.wmem_max=4194304" >> /usr/lib/sysctl.d/90-CDF.conf
echo "net.core.rmem_max=4194304" >> /usr/lib/sysctl.d/90-CDF.conf
echo "net.ipv4.tcp_wmem=4096 87380 4194304" >> /usr/lib/sysctl.d/90-CDF.conf
echo "net.ipv4.tcp_rmem=4096 87380 4194304" >> /usr/lib/sysctl.d/90-CDF.conf
echo "net.ipv4.ip_local_port_range = 1024 65535" >> /usr/lib/sysctl.d/90-CDF.conf

modprobe br_netfilter
echo "net.bridge.bridge-nf-call-iptables=1" >> /usr/lib/sysctl.d/92-Worker.conf
echo "net.bridge.bridge-nf-call-ip6tables=1" >> /usr/lib/sysctl.d/92-Worker.conf

echo "net.ipv4.ip_forward=1" >> /usr/lib/sysctl.d/92-Worker.conf
echo "net.ipv4.tcp_tw_recycle=0" >> /usr/lib/sysctl.d/92-Worker.conf
echo "kernel.sem=50100 128256000 50100 2560" >> /usr/lib/sysctl.d/92-Worker.conf
echo "vm.max_map_count=262144" >> /usr/lib/sysctl.d/92-Worker.conf

sysctl -p
/sbin/sysctl --system

echo "* hard nofile 1000000" >> /etc/security/limits.conf
echo "* soft nofile 1000000" >> /etc/security/limits.conf
echo "root hard nofile 1000000" >> /etc/security/limits.conf
echo "root soft nofile 1000000" >> /etc/security/limits.conf
echo "itsma hard nofile 1000000" >> /etc/security/limits.conf
echo "itsma soft nofile 1000000" >> /etc/security/limits.conf
echo "* soft nproc 1000000" >> /etc/security/limits.conf
echo "* hard nproc 1000000" >> /etc/security/limits.conf


################################################################################
#####                   INSTALLATION - REQUIRED PACKAGES                   #####
################################################################################
## Only the first master needs httpd-tools
yum install -y java-1.8.0-openjdk libgcrypt libseccomp libtool-ltdl net-tools nfs-utils rpcbind systemd-libs unzip conntrack curl lvm2 showmount --nogpgcheck
#yum install -y device-mapper-libs java-1.8.0-openjdk libgcrypt libseccomp libtool-ltdl net-tools nfs-utils rpcbind systemd-libs unzip conntrack-tools curl lvm2 showmount --nogpgcheck
yum list device-mapper-libs java-1.8.0-openjdk libgcrypt libseccomp libtool-ltdl.x86_64 net-tools nfs-utils rpcbind systemd-libs unzip conntrack-tools curl lvm2 showmount


################################################################################
#####                     SYSTEM SECURITY AND FIREWALL                     #####
################################################################################
## Ensure Firewalld is configured properly or set to disabled and stopped
#firewall-cmd --add-masquerade --permanent
#firewall-cmd --reload
systemctl disable firewalld
systemctl stop firewalld
