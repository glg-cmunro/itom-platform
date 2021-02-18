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