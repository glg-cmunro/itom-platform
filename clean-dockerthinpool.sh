#!/bin/bash

#Clean thinpool on Removal of CDF
lvremove -y /dev/docker/thinpoolmeta
lvremove -y docker
lvremove -y bootstrap-docker
vgremove -y docker
vgremove -y bootstrap-docker
pvremove /dev/sdb2
pvremove /dev/sdb1
