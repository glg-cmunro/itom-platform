### New Control Node setup
sudo yum install git python3 epel-release -y
sudo python3 -m pip install --upgrade pip
sudo python3 -m pip install ansible

#git config credential.helper store

git clone https://github.com/GreenlightGroup/aws-smax
cd aws-smax/
sudo ansible-playbook --ask-vault-pass -e region=us-east-2 -e smax_version=2020.02 -e stack_name=smax-east-ekstest app-configure-control-node.yaml
sudo ansible-playbook --skip-tags download_images --ask-vault-pass -e region=us-east-2 -e smax_version=2020.02 -e stack_name=smax-east-ekstest app-deploy-smax.yaml


#Load the ECR jdbc driver repo
ecrUserName=AWS
ecrUserPassword=$(aws ecr get-login-password)
ecrURL=658787151672.dkr.ecr.us-east-1.amazonaws.com

sudo docker login $ecrURL -u $ecrUserName -p $ecrUserPassword
docker pull $ecrURL/hpeswitom/jdbc-drivers-container:1.0

cd /opt/smax/2020.11/scripts
sudo ./build_jdbc.sh -o hpeswitom
sudo python3 create_aws_repositories.py -r us-east-1 -o hpeswitom -n jdbc-drivers-container
sudo ./uploadimages.sh -r $ecrURL -u $ecrUserName -p $ecrUserPassword -d jdbc_image -o hpeswitom


sudo /usr/local/bin/ansible-playbook --ask-vault-pass -e eks_version=1.18 -e region=us-east-1 -e smax_version=2020.11 -e stack_name=smax-east-1 app-configure-control-node.yaml
