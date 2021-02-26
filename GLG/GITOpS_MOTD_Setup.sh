### gitops

#Modify MOTD
echo -en '''\033[2;32;100m

################################################################################
#      ____________________       _____             _____ __  ______   _  __   #
#     / ____/  _/_  __/ __ \____ / ___/            / ___//  |/  /   | | |/ /   #
#    / / __ / /  / / / / / / __ \\\\__ \   ______    \__ \/ /|_/ / /| | |   /    #
#   / /_/ // /  / / / /_/ / /_/ /__/ /  /_____/   ___/ / /  / / ___ |/   |     #
#   \____/___/ /_/  \____/ .___/____/            /____/_/  /_/_/  |_/_/|_|     #
#                       /_/                                                    #
################################################################################

\033[0m''' | sudo tee -a /etc/motd

#Modify PROFILE
echo -en '''
## BEGIN: GITOpS Edit ##

NS=`sudo kubectl get ns | grep itsma | awk '{print $1}'`
CLUSTER_NAME=`sudo kubectl get cm -n core base-configmap -o json | jq -r .data.CLUSTER_NAME`

## END: GITOpS Edit ##
''' | sudo tee -a /etc/profile

#Append MOTD with cluster detail
echo '''
#!/bin/bash

echo "  Cluster: `sudo kubectl get cm -n core base-configmap -o json | jq -r .data.CLUSTER_NAME`"
echo "  Version: `sudo kubectl get cm -n core base-configmap -o json | jq -r .data.PLATFORM_VERSION`"
echo ""
''' | sudo tee -a /etc/profile.d/motd.sh


echo -n '''
## BEGIN: GITOpS Edit ##

PS1="[\\u@$CLUSTER_NAME \\W]\\$"

## END: GITOpS Edit ##
''' | sudo tee -a /etc/bashrc