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

### PostgreSQL DB Server  
<details><summary>PostgreSQL DB Server</summary>  

*_PostgreSQL Variables used throughout this document_*  
| Variable | GreenLight Value | Description                               |
| ---      | ---              | ---                                       |
| PGDIR    | /pgdata          | Mountpoint used for PostgreSQL DB files   |
| PGDATA   | ${PGDIR}/16/data | PostgreSQL DB Data directory              |
| PGUSER   | postgres         | OS System User / PostgreSQL process owner |

1. Install PostgreSQL 16 Server  
   #### Download/Install PostgreSQL packages  
   ```
   sudo dnf -qy module disable postgresql:13
   sudo dnf module enable postgresql:16
   sudo dnf install -y postgresql-server
   sudo postgresql-setup --initdb
   sudo systemctl start postgresql
   sudo systemctl enable postgresql
   
   ```

2. Configure PostgreSQL DB Access from cluster hosts
   #### Configure pg_hba.conf  
   > **_Perform these operations as root or as ${PGUSER}_**
   ```
   if [ ! -v PGDATA ]; then
     if [ ! -v PGDIR ]; then
       PGDIR=/pgdata; echo Setting PGDIR: ${PGDIR};
     fi
     PGDATA=${PGDIR}/16/data; echo Setting PGDATA: ${PGDATA};
   fi
   
   cat << EOT >> ${PGDATA}/pg_hba.conf
   
   ## OpenText OPTIC Connections:
   host    all             all             10.10.10.0/24           trust
   host    all             all             17.16.0.0/20            trust
   host    all             all             172.17.17.0/24          trust
   EOT
   
   tail -10 ${PGDATA}/pg_hba.conf
   
   ```  
3. Configure PostgreSQL DB parameters for performance
   #### Configure postgresql.conf  
   > **_Perform these operations as root or as ${PGUSER}_**
   ```
   if [ ! -v PGDIR ]; then PGDIR=/pgdata; echo Setting PGDIR:  ${PGDIR}; fi
   if [ ! -v PGDATA ]; then PGDATA=${PGDIR}/16/data; echo Setting PGDATA: ${PGDATA}; fi
   
   sed -e "/max_connections/ s/^#*/#/g" -i ${PGDATA}/postgresql.conf
   sed -e "/shared_buffers/ s/^#*/#/g" -i ${PGDATA}/postgresql.conf
   
   cat << EOT >> ${PGDATA}/postgresql.conf
   
   ## BEGIN ## OpenText OPTIC Edits
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
   ## END ## OpenText OPTIC Edits
   EOT
   
   tail -30 ${PGDATA}/postgresql.conf
   
   ```  

4. Restart PostgreSQL to complete the changes  
   #### Restart PostgreSQL service
   ```
   sudo systemctl restart postgresql
   systemctl status postgresql
   
   ```  

5. Create OMT Databases  
   #### Create required databases
   ```
   if [ ! -v PGUSER ]; then PGUSER=postgres; echo Setting PGUSER:  ${PGUSER}; fi

   psql -U ${PGUSER} -d postgres

   ```  
   ```
   \getenv dbadmin PGUSER
   \echo 'Setting dbadmin to:' :dbadmin

   ```  
   #### Delete if exists (Cleanup/Remove)
   ```
   DROP DATABASE IF EXISTS omtidm;
   DROP ROLE IF EXISTS omtidm;
   DROP DATABASE IF EXISTS omtapiserver;
   DROP ROLE IF EXISTS omtapiserver;
   
   ```  
   ```
   CREATE USER omtidm login PASSWORD 'Gr33nl1ght_';
   GRANT omtidm to ${PGUSER};
   
   CREATE DATABASE omtidm WITH owner=omtidm;
   
   ```  
   ```
   \c omtidm;

   ```  
   ```
   CREATE SCHEMA omtidmschema AUTHORIZATION omtidm; 
   GRANT ALL ON SCHEMA omtidmschema to omtidm; 
   ALTER USER omtidm SET search_path TO omtidmschema;
   
   ```  
   ```
   \q
   
   ```
</details>

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
