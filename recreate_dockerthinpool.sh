#!/bin/bash
# Purpose:  Create Partitions on disk and configure as thinpool devices for docker and bootstrap-docker


#Setup the thinpool device variables
THINPOOL_DEVICE=/dev/sdb
DOCKER_THINPOOL_PART=1
BS_DOCKER_THINPOOL_PART=2

#Remove existing Volume Groups for Docker Thinpool
vgremove docker -y
vgremove bootstrap_docker -y

pvremove $THINPOOL_DEVICE$DOCKER_THINPOOL_PART $THINPOOL_DEVICE$BS_DOCKER_THINPOOL_PART


#Create the Physical Volumes for Docker Thinpool
pvcreate $THINPOOL_DEVICE$DOCKER_THINPOOL_PART $THINPOOL_DEVICE$BS_DOCKER_THINPOOL_PART

#Create the Volume Groups for Docker Thinpool
vgcreate docker $THINPOOL_DEVICE$DOCKER_THINPOOL_PART
vgcreate bs_docker $THINPOOL_DEVICE$BS_DOCKER_THINPOOL_PART

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

#Create the Bootstrap_Docker Thinpool and setup the lvm profile
lvcreate --wipesignatures y -n thinpool bs_docker -l 95%VG -y
lvcreate --wipesignatures y -n thinpoolmeta bs_docker -l 1%VG -y
lvconvert -y --zero n -c 512K --thinpool bs_docker/thinpool --poolmetadata bs_docker/thinpoolmeta

cat <<EOT > /etc/lvm/profile/bs_docker-thinpool.profile
activation {
  thin_pool_autoextend_threshold=80
  thin_pool_autoextend_percent=20
}
EOT

lvchange --metadataprofile bs_docker-thinpool bs_docker/thinpool 
lvs -o+seg_monitor
