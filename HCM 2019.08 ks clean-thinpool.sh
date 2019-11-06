#!/bin/bash

################################################################################
#####                           GLOBAL VARIABLES                           #####
################################################################################
TP_PV=/dev/sdc1
TP_VG=docker
TP_LV_DOCKER=thinpool
TP_LV_BOOTSTRAP=bootstrap_docker

#Remove existing Volume Groups for Docker Thinpool
vgremove $TP_VG -y

#Create the Volume Groups for Docker Thinpool
vgcreate $TP_VG $TP_PV


#Create the Docker Thinpool and setup the lvm profile
lvcreate --wipesignatures y -n $TP_LV_DOCKER $TP_VG -l 84%VG -y
lvcreate --wipesignatures y -n docker_meta $TP_VG -l 1%VG -y
lvconvert -y --zero n -c 512K --thinpool $TP_VG/$TP_LV_DOCKER --poolmetadata $TP_VG/docker_meta

cat <<EOT > /etc/lvm/profile/$TP_VG-$TP_LV_DOCKER.profile
activation {
  thin_pool_autoextend_threshold=80
  thin_pool_autoextend_percent=20
}
EOT

lvchange --metadataprofile $TP_VG-$TP_LV_DOCKER $TP_VG/$TP_LV_DOCKER 
lvs -o+seg_monitor 

#Create the Bootstrap_Docker Thinpool and setup the lvm profile
lvcreate --wipesignatures y -n $TP_LV_BOOTSTRAP $TP_VG -l 14%VG -y
lvcreate --wipesignatures y -n bootstrap_meta $TP_VG -l 1%VG -y
lvconvert -y --zero n -c 512K --thinpool $TP_VG/$TP_LV_BOOTSTRAP --poolmetadata $TP_VG/bootstrap_meta

cat <<EOT > /etc/lvm/profile/$TP_VG-$TP_LV_BOOTSTRAP.profile
activation {
  thin_pool_autoextend_threshold=80
  thin_pool_autoextend_percent=20
}
EOT

lvchange --metadataprofile $TP_VG-$TP_LV_BOOTSTRAP $TP_VG/$TP_LV_BOOTSTRAP 
lvs -o+seg_monitor
