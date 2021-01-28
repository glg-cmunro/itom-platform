#!/bin/bash
# Purpose:  Configure volume(s) on disk as thinpool devices for docker

#Setup the thinpool device variables
THIN_PV=/dev/xvdd1
THIN_VG=dockervg
THIN_LV=thinpoollv

#Remove existing Volume Groups for Docker Thinpool
sudo vgremove $THIN_VG -y
sudo pvremove $THIN_PV

#Create the Physical Volumes for Docker Thinpool
sudo pvcreate $THIN_PV

#Create the Volume Groups for Docker Thinpool
sudo vgcreate $THIN_VG $THIN_PV

#Create the Docker Thinpool and setup the lvm profile
sudo lvcreate --wipesignatures y -n $THIN_LV $THIN_VG -l 95%VG -y
sudo lvcreate --wipesignatures y -n $THIN_LV-meta $THIN_VG -l 1%VG -y
sudo lvconvert -y --zero n -c 512K --thinpool $THIN_VG/$THIN_LV --poolmetadata $THIN_VG/$THIN_LV-meta


echo "activation {
  thin_pool_autoextend_threshold=80
  thin_pool_autoextend_percent=20
}
" | sudo tee /etc/lvm/profile/$THIN_VG-$THIN_LV.profile

sudo lvchange --metadataprofile $THIN_VG-$THIN_LV $THIN_VG/$THIN_LV 
sudo lvs -o+seg_monitor 




'''
### If trouble removing follow these steps
### Error: "Logical volume docker/thinpool is used by another device"
sudo dmsetup info -c | grep $THIN_VG

## If any BLOCK DEVICES are listed run ls looking for the dm-# holding the DEVICE
B_MAJ=253
B_MIN=5
sudo ls -la /sys/dev/block/$B_MAJ\:$B_MIN/holders


sudo dmsetup remove /dev/dm-24
sudo dmsetup remove /dev/dm-30
sudo dmsetup remove /dev/dm-40
sudo dmsetup remove /dev/dm-42
sudo dmsetup remove /dev/dm-50
sudo dmsetup remove /dev/dm-53
sudo dmsetup remove /dev/dm-55
sudo dmsetup remove /dev/dm-9

'''
