#! /bin/bash
################################################################################
### ON Huntsman SMAX Workers
## DOCKER THINPOOL SETUP ##
## Workers - all
THINPOOL_DEVICE=/dev/sdd
DOCKER_THINPOOL_PART=1
DOCKER_VOL_GROUP=appthinpoolvg
THINPOOL_LV=Thinpoollv
THINPOOL_META_LV=thinpoolmetalv

##If you are unable to clear thinpool due to in-use device
## Disable Docker and Kubernetes services and Reboot host
#sudo systemctl disable docker kubelet kube-proxy;
#sudo init 6

##Clear out existing thinpool
sudo lvremove -y /dev/$DOCKER_VOL_GROUP/$DOCKER_THINPOOL_LV
sudo vgremove $DOCKER_VOL_GROUP -y
sudo pvremove $THINPOOL_DEVICE$DOCKER_THINPOOL_PART

#Create the Physical Volumes for Docker Thinpool
sudo pvcreate $THINPOOL_DEVICE$DOCKER_THINPOOL_PART

#Create the Volume Groups for Docker Thinpool
sudo vgcreate $DOCKER_VOL_GROUP $THINPOOL_DEVICE$DOCKER_THINPOOL_PART

#Create the Docker Thinpool and setup the lvm profile
sudo lvcreate --wipesignatures y -n $THINPOOL_LV $DOCKER_VOL_GROUP -l 95%VG -y
sudo lvcreate --wipesignatures y -n $THINPOOL_META_LV $DOCKER_VOL_GROUP -l 1%VG -y
sudo lvconvert -y --zero n -c 512K --thinpool $DOCKER_VOL_GROUP/$THINPOOL_LV --poolmetadata $DOCKER_VOL_GROUP/$THINPOOL_META_LV

sudo cat <<EOT > /etc/lvm/profile/docker-thinpool.profile
activation {
  thin_pool_autoextend_threshold=80
  thin_pool_autoextend_percent=20
}
EOT

sudo lvchange --metadataprofile docker-thinpool $DOCKER_VOL_GROUP/$THINPOOL_LV 
sudo lvs -o+seg_monitor 

#### NOTE: Docker config needs to have the right thinpool info
####       if updates needed, edit this file
#sudo vi /opt/Kubernetes/cfg/docker

sudo tar -cvf /tmp/docker.tar /opt/Kubernetes/data/docker
sudo rm -rf /opt/Kubernetes/data/docker

## Re-Start and Re-Enable Docker and Kubernetes services
sudo systemctl daemon-reload
#sudo systemctl start docker.service
sudo /opt/Kubernetes/bin/kube-restart.sh -y
sudo systemctl enable docker kubelet kube-proxy;
