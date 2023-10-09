
### GITOpS Notes on System Setup and Execution of aws-smax automation
![alt text](https://assets.website-files.com/5ebcb9396faf10d8f7644479/5ed6a066891af295a039860f_GLGLogolrg-p-500.png "GreenLight Logo")
#### System Prep
```
sudo yum install -y git unzip vim python38

sudo update-alternatives --config vi
alias vi="vim"

python3 -m pip install --upgrade pip

python3 -m pip install -U setuptools
python3 -m pip install ansible wheel kubernetes
python3 -m pip install boto boto3
 psycopg2-binary 

#python3 -m pip install openshift --ignore-installed PyYAML
```
### Packages to install
sudo yum install -y git python3
sudo python3 -m pip install --upgrade pip
python3 -m pip install -U setuptools
python3 -m pip install openshift --ignore-installed PyYAML
python3 -m pip install ansible kubernetes boto boto3 psycopg2-binary wheel

### Setup AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf ./aws
rm -f awscliv2.zip

#Enter AWS API KEY, SECRET, REGION, OUTPUT
aws configure
