#!/usr/bin/bash
###
# Ansible Playbook Walkthrough - SMAX DR Backup

git clone https://github.com/GreenlightGroup/smax_cluster_migration
cd smax_cluster_migration/ansible/playbooks

sudo ansible-playbook -vvv \
 -e stack_name=smax-west \
 -e region=us-west-2 \
 -e smax_version=2020.05 \
 -e nfs_filestore_ip_address=smax-west-efs.gitops.com \
app-shutdown-backup.yaml
