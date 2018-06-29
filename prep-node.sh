#!/bin/bash

#Ensure Firewalld is set to disabled and stopped
systemctl disable firewalld
systemctl stop firewalld

# Hostname resolution and IP Address assignment
#Fix /etc/hosts entry from VMware adding hostname as 127.0.1.1
IPADDR=$(ip address show scope global | grep 'inet' | head -n 1 | awk '{print $2}' | cut -d "/" -f 1)
sed -i "s/127.0.1.1/$IPADDR/g" /etc/hosts
sed -i -e "1i$(head -$(grep -n $IPADDR /etc/hosts | awk -F: '{print $1}') /etc/hosts | tail -1)" -e "$(grep -n $IPADDR /etc/hosts | grep -v 1: | awk -F: '{print $1}')d" /etc/hosts

DOCKER_THINPOOL_DEVICE=/dev/sdb1
BS_DOCKER_THINPOOL_DEVICE=/dev/sdb2

#Create the Physical Volumes for Docker Thinpool
pvcreate $DOCKER_THINPOOL_DEVICE $BS_DOCKER_THINPOOL_DEVICE

#Create the Volume Groups for Docker Thinpool
vgcreate docker $DOCKER_THINPOOL_DEVICE
vgcreate bootstrap-docker $BS_DOCKER_THINPOOL_DEVICE

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
lvcreate --wipesignatures y -n thinpool bootstrap-docker -l 95%VG -y
lvcreate --wipesignatures y -n thinpoolmeta bootstrap-docker -l 1%VG -y
lvconvert -y --zero n -c 512K --thinpool bootstrap-docker/thinpool --poolmetadata bootstrap-docker/thinpoolmeta

cat <<EOT > /etc/lvm/profile/bootstrap-docker-thinpool.profile
activation {
  thin_pool_autoextend_threshold=80
  thin_pool_autoextend_percent=20
}
EOT

lvchange --metadataprofile bootstrap-docker-thinpool bootstrap-docker/thinpool 
lvs -o+seg_monitor
