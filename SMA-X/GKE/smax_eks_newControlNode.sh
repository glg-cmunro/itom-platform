### New Control Node setup
git clone https://github.com/GreenlightGroup/aws-smax
cd aws-smax/
sudo ansible-playbook --ask-vault-pass -e region=us-east-2 -e smax_version=2020.02 -e stack_name=smax-east-ekstest app-configure-control-node.yaml
sudo ansible-playbook --skip-tags download_images --ask-vault-pass -e region=us-east-2 -e smax_version=2020.02 -e stack_name=smax-east-ekstest app-deploy-smax.yaml

