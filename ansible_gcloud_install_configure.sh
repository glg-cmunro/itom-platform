### Fresh new server - CentOS 8 - System Setup - 2021.05 ###

#Edit SUDOERS to allow wheel to sudo NOPASSWD

##Make sure TIME is set correctly on server there will be trust issues
##Update GPG Key to allow for install/update
#rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

#Install Basic System Tools and related SW
sudo dnf install -y vim git unzip nfs-utils tmux jq
sudo dnf install -y python3
#sudo dnf install -y epel-release docker
python3 -m pip install --upgrade pip
python3 -m pip install -U setuptools
python3 -m pip install openshift --ignore-installed PyYAML
python3 -m pip install ansible kubernetes boto3 psycopg2-binary wheel

#Install AWS CLI
curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o '/tmp/awscliv2.zip'
unzip -d /tmp /tmp/awscliv2.zip
sudo /tmp/aws/install

#Install kubectl
curl -o kubectl "https://amazon-eks.s3.us-west-2.amazonaws.com/1.20.4/2021-04-12/bin/linux/amd64/kubectl"
chmod a+x kubectl
sudo mv kubectl /usr/bin/















### INSTALL AND CONFIGURE ANSIBLE SYSTEM WITH GCLOUD SDK
#Install GIT
sudo dnf install git -y

#Install Ansible
sudo dnf install epel-release -y #Add the EPEL Release repo if needed
sudo dnf install ansible -y
sudo pip3 install awscli boto3

#Add AWS Credentials to root for ansible to use
sudo /usr/local/bin/aws configure


#GIT Clone AWS SMAX repo
git clone https://github.com/GreenlightGroup/aws-smax


#Add Google Cloud SDK repo for download
sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM

sudo dnf install google-cloud-sdk -y

gcloud init
git 