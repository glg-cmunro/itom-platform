
# Step by Step - Deploy NOM on OpsBridge Cluster 2022.11 onprem
![GreenLight Group Logo](https://assets.website-files.com/5ebcb9396faf10d8f7644479/5ed6a066891af295a039860f_GLGLogolrg-p-500.png)

---

OpenText doc steps: [Install NOM]
1. Download the NOM Helm chart (embedded)
2. Download and Upload images for Audit service (EKS)
3. Configure EFS for Audit service
4. Prepare persistent volumes for Audit service
5. Launch RDS for Audit service
6. Create new deployment for Audig service
7. Configure load balancer for Audit service
8. Create application load balancer for Audit service
9. Configure values.yaml for Audit service (EKS)
10. Deploy Audit on AWS (EKS)


### Pre-Requisites:
1. Add Additional Worker(s) to the cluster
> On worker to be added
```
sudo dnf install -y conntrack nfs-utils container-selinux bash-completion socat

sudo modprobe br_netfilter
echo "br_netfilter" | sudo tee /etc/modules-load.d/br_netfilter.conf

echo -n '''
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
kernel.sem=50100 128256000 50100 2560
''' | sudo tee /etc/sysctl.d/10-optic.conf

sudo sysctl -p /etc/sysctl.d/10-optic.conf

sudo swapoff -a
sudo sed -e "/swap/ s/^#*/#/g" -i /etc/fstab
```

### Run cdfctl node add
```
sudo /opt/cdf/bin/cdfctl node add --node lxot-optic-wrk4.afcucorp.test --node-type worker --node-user=jmunro.admin
sudo /opt/cdf/bin/cdfctl node add --node lxot-optic-wrk5.afcucorp.test --node-type worker --node-user=jmunro.admin

#If firewall is enabled and is the only warning you can run with the skip warnings turned on
sudo /opt/cdf/bin/cdfctl node add --node lxot-optic-wrk5.afcucorp.test --node-type worker --node-user=jmunro.admin --skip-warning=true
sudo /opt/cdf/bin/cdfctl node add --node lxot-optic-wrk5.afcucorp.test --node-type worker --node-user=jmunro.admin --skip-warning=true
```

################################################################################
#####                   INSTALLATION - REQUIRED PACKAGES                   #####
################################################################################
### PostgreSQL Install
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo dnf -qy module disable postgresql
sudo dnf install -y postgresql14-server



## Setup PostgreSQL DB
sudo systemctl edit postgresql-14.service
##Add the following contents 'vi style' - without the comments
#[Service]
#Environment=PGDATA=/pgdata/14/data

sudo systemctl daemon-reload

sudo /usr/pgsql-14/bin/postgresql-14-setup initdb

> AFCU SIT  
```
cat >> /var/lib/pgsql/14/data/pg_hba.conf << EOF
#OpenText OPTIC Connections:
host    all             all             10.30.224.0/23            trust
host    all             all             17.16.0.0/20           trust
host    all             all             172.17.17.0/24          trust
EOF

sed -e "/max_connections/ s/^#*/#/g" -i /var/lib/pgsql/14/data/postgresql.conf
sed -e "/shared_buffers/ s/^#*/#/g" -i /var/lib/pgsql/14/data/postgresql.conf

cat <<EOT >> /var/lib/pgsql/14/data/postgresql.conf
## OPTIC Edits - NOM 2022.11
listen_addresses = '*'
max_connections = 450
shared_buffers = 6GB
effective_cache_size = 18GB
maintenance_work_mem = 1536MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 4
effective_io_concurrency = 2
work_mem = 15728kB
min_wal_size = 1GB
max_wal_size = 4GB
max_worker_processes = 8
max_parallel_workers_per_gather = 4
max_parallel_workers = 8
max_parallel_maintenance_workers = 4

track_counts = on
autovacuum = on
#timezone = 'UTC'
## OPTIC Edits - NOM 2022.11
EOT
```

> AFCU PROD  
```
cat >> /pgdata/14/data/pg_hba.conf << EOF
#OpenText OPTIC Connections:
host    all             all             10.6.9.0/23            trust
host    all             all             17.16.0.0/20           trust
host    all             all             172.17.17.0/24          trust
EOF

sed -e "/max_connections/ s/^#*/#/g" -i /pgdata/14/data/postgresql.conf
sed -e "/shared_buffers/ s/^#*/#/g" -i /pgdata/14/data/postgresql.conf

cat <<EOT >> /pgdata/14/data/postgresql.conf
## OPTIC Edits - NOM 2022.11
listen_addresses = '*'
max_connections = 450
shared_buffers = 6GB
effective_cache_size = 18GB
maintenance_work_mem = 1536MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 4
effective_io_concurrency = 2
work_mem = 15728kB
min_wal_size = 1GB
max_wal_size = 4GB
max_worker_processes = 8
max_parallel_workers_per_gather = 4
max_parallel_workers = 8
max_parallel_maintenance_workers = 4

track_counts = on
autovacuum = on
#timezone = 'UTC'
## OPTIC Edits - NOM 2022.11
EOT
```

systemctl restart postgresql-14.service


### Download the NOM Helm chart (embedded)

```
mkdir -p /opt/glg/nom/2022.11
#Upload nom-helm-chart to /opt/glg/nom/2022.11
curl -kLs https://owncloud.gitops.com/index.php/s/Eal9Gy7Aq3wvOwh/download -o /opt/glg/nom/2022.11/nom-helm-charts-1.8.0-20221100.353.tgz
tar -zxvf /opt/glg/nom/2022.11/nom-helm-charts-1.8.0-20221100.353.tgz -C /opt/glg/nom/2022.11/
```


### Create PostgreSQL Databases
> On Control Plane Master  
```
/opt/glg/nom/2022.11/nom-helm-charts/scripts/DBSQLGenerator.sh
```
> - Do you want to deploy containerized NNMi and/or NA? - false
> - Do you want to use OPTIC Reporting and/or Performance Troubleshooter and Incident Troubleshooting capabilities? - true
> - Do you have an existing OPTIC Reporting instance to connect to? - true
> - Do you want to use default database and user names, and a common password for all database users? - true
> - #Enter Password for all databases
> - #Confirm Password
> - Enter the ADMIN username used to connect to the PostgreSQL database : postgres


> Environment: SIT
```
psql -h lxot-optic-pg.afcucorp.test -U postgres -f CreateSQL.sql
```

> Environment: PROD
```
psql -h lxo-optic-pg.afcucorp.local -U postgres -f CreateSQL.sql
```


### Create Storage Folders / PVs
> On NFS Server  
```
sudo mkdir /var/vols/itom/nom
sudo chown 1999:1999 /var/vols/itom/nom

for i in {1..4}; do
    sudo mkdir "/var/vols/itom/nom/vol$i"
    sudo chown 1999:1999 "/var/vols/itom/nom/vol$i"
    sudo chmod g+w+s "/var/vols/itom/nom/vol$i"
done
```

```
echo -e "#OpenText NOM" | sudo tee -a /etc/exports
for i in {1..4}; do
    echo -e "/var/vols/itom/nom/vol$i *(rw,sync,anonuid=1999,anongid=1999,root_squash)" | sudo tee -a /etc/exports
done
```

```
sudo exportfs -ra
```

> On Control Plane Master    
> - Environment: SIT  
```
NFS_FQDN=lxot-optic-nfs.afcucorp.test
```

> - Environment: PROD
```
NFS_FQDN=lxo-optic-nfs.afcucorp.local
```

```
cat << EOT > /opt/glg/nom/2022.11/nom_pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: vol1
spec:
  accessModes:
  - ReadWriteMany
  capacity:
    storage: 60Gi
  nfs:
    path: /var/vols/itom/nom/vol1
    server: $NFS_FQDN
  persistentVolumeReclaimPolicy: Recycle
  volumeMode: Filesystem
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: vol2
spec:
  accessModes:
  - ReadWriteMany
  capacity:
    storage: 60Gi
  nfs:
    path: /var/vols/itom/nom/vol2
    server: $NFS_FQDN
  persistentVolumeReclaimPolicy: Recycle
  volumeMode: Filesystem
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: vol3
spec:
  accessModes:
  - ReadWriteMany
  capacity:
    storage: 5Gi
  nfs:
    path: /var/vols/itom/nom/vol3
    server: $NFS_FQDN
  persistentVolumeReclaimPolicy: Recycle
  volumeMode: Filesystem
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: vol4
spec:
  accessModes:
  - ReadWriteMany
  capacity:
    storage: 5Gi
  nfs:
    path: /var/vols/itom/nom/vol4
    server: $NFS_FQDN
  persistentVolumeReclaimPolicy: Recycle
  volumeMode: Filesystem
---
EOT

sudo kubectl create -f /opt/glg/nom/2022.11/nom_pv.yaml
```


### Obtain RE / RID Certs / Secrets
> On Control Plane Master  
```
idmPod=$(sudo kubectl get pods -n opsb-helm | grep itom-idm | awk '{print $1}' | head -n 1)
sudo kubectl -n opsb-helm cp $idmPod:/var/run/secrets/boostport.com/trustedCAs/RE_ca.crt /opt/glg/nom/ProvRE.crt
sudo kubectl -n opsb-helm cp $idmPod:/var/run/secrets/boostport.com/trustedCAs/RID_ca.crt /opt/glg/nom/ProvRID.crt

transportAdminPW=$(sudo kubectl -n opsb-helm get secret opsbridge-suite-secret --template={{.data.idm_transport_admin_password}} | base64 -d)
integrationAdminPW=$(sudo kubectl -n opsb-helm get secret opsbridge-suite-secret --template={{.data.idm_integration_admin_password}} | base64 -d)
```


### Create NOM administrator user and group in IdM
> Create integration user to communicate with the OPTIC Data Lake providing application.
> 
> Log into IdM admin page of the OPTIC Data Lake provider, for example Operations Bridge, as the admin user:
> Add the following in the browser: https://<externalAccessHost>:<externalAccess port of Operations Bridge>/idm-admin
> For example: https://myhostname.mydomain:443/idm-admin
> On IdM go to ORGANIZATION LIST.
> Click the organization name, for example OPSBRIDGE.
> Create a new password policy and assign it to the user.
> By default, the password is valid for 90 days. For the new password policy, disable the expiration check and update the password complexity based on your existing system user password.
> 
> Click Users. The user management page lists all users in the organization. 
> Click  2018.02/attachments/23201412/23201419.png  to add a user. In the Name field, enter nomadmin. Enter a display name and then enter the NOM password. Use the Type drop down to select the type of user as REGULAR or SYSTEM.
> Under User Attributes, click + to add a new attribute and give inputs for:
> Attribute Name: Type name as the Attribute Name.
> Value: Type the name of the user account. Example: nomadmin
> Click SAVE.
> Go to Groups, and click  2018.02/attachments/23201412/23201419.png .
> On the Group Settings page,  add a name, display name, and description in the respective fields.
> In the Associated Roles list, select the superAdmin, di_admin, and bvd_admin role.
> Under Users, in the  Associated User list and select nomadmin (the user that you just created).
> Click Save. 

### Download NOM images
```
sudo $CDF_HOME/tools/generate-download/generate_download_bundle.sh --chart /opt/glg/nom/2022.11/nom-helm-charts/charts/nom-1.8.0+20221100.353.tgz -d /opt/glg/nom/2022.11/
unzip /opt/glg/nom/2022.11/offline-download.zip -d /opt/glg/nom/2022.11/
rm -f /opt/glg/nom/2022.11/offline-download.zip

/opt/glg/nom/2022.11/offline-download/downloadimages.sh -u dockerhubglg -d /opt/glg/nom/2022.11/images -o hpeswitom
/opt/glg/nom/2022.11/offline-download/uploadimages.sh -d /opt/glg/nom/2022.11/images -o hpeswitom
```

## Deploy NOM
### Create NOM namespace

> - Environment: SIT
```
/opt/cdf/bin/cdfctl deployment create -t helm -d nom -n nom-sit
```

> - Environment: PROD
```
sudo $CDF_HOME/bin/cdfctl deployment create -t helm -d nom -n nom-prd
```

### Upload NOM chart to Apphub
> Login to Apphub portal
https://lxot-opticcntrl.afcucorp.test:5443/apphub
