# OS and System patches
sudo yum upgrade -y


# Upgrade python to python3.8
> Install required packages first  
`sudo yum install -y gcc openssl-devel bzip2-devel libffi-devel zlib-devel`

> Download Python 3.8 bits
```
mkdir ~/python
curl -sLk https://www.python.org/ftp/python/3.8.12/Python-3.8.12.tgz > ~/python/Python-3.8.12.tgz
cd ~/python
tar xzf Python-3.8.12.tgz
cd Python-3.8.12
sudo ./configure --enable-optimizations
sudo make altinstall
```
`pip3.8 install --upgrade --user pip`
`pip3.8 install --upgrade --user ansible`

sudo find /mnt/efs/var -name *.log* -mtime +90 -delete


```
pip3.8 install ansible
```