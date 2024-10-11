
### GITOpS Notes on System Setup and Execution for GITOpS automation
![alt text](https://assets.website-files.com/5ebcb9396faf10d8f7644479/5ed6a066891af295a039860f_GLGLogolrg-p-500.png "GreenLight Logo")
#### System Prep

---

### Packages to install
> OS Packages to install
> - git - For access to GreenLight Group github repositories
> - python - Python 3.8 or newer.  Required for Ansible
> - jq - JSON Query a useful tool for parsing JSON output

```
sudo yum install -y git unzip vim python38 jq

sudo update-alternatives --config vi
alias vi="vim"

python3 -m pip install --upgrade pip

python3 -m pip install -U setuptools
python3 -m pip install ansible wheel kubernetes
python3 -m pip install boto boto3
 psycopg2-binary 

#python3 -m pip install openshift --ignore-installed PyYAML
```

### Setup AWS CLI
```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
#rm -rf ./aws
rm -f awscliv2.zip
```

#Enter AWS API KEY, SECRET, REGION, OUTPUT
aws configure

### Setup Kubernetes
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo chmod a+x kubectl
#sudo chown centos:wheel kubectl
sudo mv kubectl /usr/bin/kubectl

### Install Terraform
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo dnf install -y terraform
