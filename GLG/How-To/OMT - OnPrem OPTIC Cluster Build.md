1. OnPrem OPTIC Cluster Architecture
    - K8s Master Node (1 or 3)
        - OS: Rocky Linux 9.5
    - K8s Worker Node (At least 3)
        - OS: Rocky Linux 9.5
    - PostgreSQL Server
        - OS: Rocky Linux 9.5
        - APP: postgresql-server:16
    - NFS Fileserver
        - OS: Rocky Linux 9.5
        - APP: NFS Utils


## All Systems - Environment Setup:  
---  
> Initial Profile setup  
```
mkdir .ssh

echo "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAwrEUj0nYnXpWard9YtAMnTKchnU14A6PjMPzkXMORsJIZf7H2HY/fOxLR/kp2uLiIseCFkIBmD6RYgyRCkU/93WYIKAdS8nU6kHxtMaj7gIjuaZBRfIFOZelZbOnOAxsZF1DQLT9ttgTFmYVnUxb1mjM1e4+HxchFjKIkHoNzbtHP0YxWlCPlAnam4BydyLrwLT8AzN98W+Ibmt5GN9tDQQBgCXIwok3jdV7J9axI5O9wUNcn4eWGmix0ukD+bH7i1SGWeQTx34Y9WSNqsXFZQKqQ9Zy4qsmq2BU0Ia32SndQX7aIwh8c1qt8yx79qEzWQLSi38r7qklHdddrr2OxQ==" > .ssh/authorized_keys2

chmod 0700 .ssh
chmod 0600 .ssh/authorized_keys

```

## PostgreSQL Server:  
> Install PostgreSQL 16 Server
```
sudo dnf -qy module disable postgresql:13
sudo dnf module enable postgresql:16
sudo dnf install -y postgresql-server
sudo postgresql-setup --initdb
sudo systemctl start postgresql
sudo systemctl enable postgresql

```

## NFS Server  
> Install NFS Utilities for Fileshare  
```
sudo dnf install -y nfs-utils
sudo firewall-cmd --permanent --add-service=nfs
sudo firewall-cmd --permanent --add-service=mountd
sudo firewall-cmd --permanent --add-service=rpc-bind
sudo firewall-cmd --reload

```
> Setup NFS Directories for OPTIC  
```
sudo mkdir -p /var/vols/itom/core
sudo mkdir -p /var/vols/itom/esm
sudo mkdir -p /var/vols/itom/cms
sudo mkdir -p /var/vols/itom/obm/vol1
sudo mkdir -p /var/vols/itom/obm/vol2
sudo mkdir -p /var/vols/itom/obm/vol3
sudo mkdir -p /var/vols/itom/obm/vol4
sudo mkdir -p /var/vols/itom/obm/vol5
sudo mkdir -p /var/vols/itom/obm/vol6
sudo mkdir -p /var/vols/itom/obm/vol7
sudo mkdir -p /var/vols/itom/nom/vol1
sudo mkdir -p /var/vols/itom/nom/vol2
sudo mkdir -p /var/vols/itom/nom/vol3
sudo mkdir -p /var/vols/itom/nom/vol4
sudo mkdir -p /var/vols/itom/oo

sudo chown -R 1999:1999 /var/vols

```
> Expose NFS Exports for Fileshare  
```
echo -e "/var/vols/itom *(rw,sync,anonuid=1999,anongid=1999,root_squash)" | sudo tee -a /etc/exports

sudo exportfs -ra

sudo systemctl start nfs-server
sudo systemctl enable nfs-server

```
