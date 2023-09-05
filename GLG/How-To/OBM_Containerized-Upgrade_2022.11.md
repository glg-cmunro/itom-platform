# Step by Step - Deploy ITOM Cluster capability - OO Containerized - 2022.11
![GreenLight Group Logo](https://assets.website-files.com/5ebcb9396faf10d8f7644479/5ed6a066891af295a039860f_GLGLogolrg-p-500.png)

---

## Deployment Steps
> - Backup Cluster before making ANY changes
> - Download and Extract OO helm charts
> - Create OO Deployment in OMT
> - Prepare NFS/EFS directories for OO PVs
>   - Prepare PV / PVC for OO
> - Create Databases for OO
> - 
 
## Install OO Containerized - 2022.11

### Backup Cluster and SUITE before making any changes

### Update kube-registry cert and helm values after running renewCert
> IF renewCert was executed then we MUST update the helm chart cert or uploadimages.sh will fail
```
openssl genrsa -out registry.key 4096
openssl req -new -key registry.key -subj "/CN=kube-registry.${CDF_NAMESPACE}" -out registry.csr
cat > extfile.conf <<ENDOFFILE
[extensions]
subjectAltName=DNS:kube-registry.${CDF_NAMESPACE},DNS:localhost,DNS:kube-registry
basicConstraints=CA:FALSE
keyUsage=digitalSignature,keyAgreement,keyEncipherment
extendedKeyUsage=serverAuth,clientAuth
ENDOFFILE
```
```
openssl x509 -req -sha256 -in registry.csr -CAkey $CDF_HOME/ssl/ca.key -CA $CDF_HOME/ssl/ca.crt -CAcreateserial -out registry.crt -days 365 -extensions extensions -extfile extfile.conf
```
```
helm upgrade kube-registry $CDF_HOME/charts/itom-kube-registry-1.*.tgz  -ncore --reuse-values --set tls.cert=$(base64 -w0 registry.crt) --set tls.key=$(base64 -w0 registry.key)
```

### Download and extract OO Charts  
```
sudo mkdir -p /opt/glg/2022.11/OMT
sudo chown -R jmunro:domain\ users /opt/glg
```

> OMT 2022.05 w/ embedded Kubernetes
```
curl -kLs  -o OMT2205-204-15001-External-K8s.zip
```
> OMT 2022.11 w/ embedded Kubernetes  
```
curl -kLs https://owncloud.gitops.com/index.php/s/Pl3K9AmIcV7nW76/download -o /opt/glg/2022.11/OMT/OMT2211-216-15001-Embedded-K8s.zip
```



### Upgrade OMT 2022.05
1.
#Control Node:
sudo /opt/glg/2022.11/OMT/OMT_Embedded_K8s_2022.05-204/upgrade.sh -i -y -t /tmp

2.
#Workers (ALL):
sudo /opt/glg/2022.11/OMT/OMT_Embedded_K8s_2022.05-204/upgrade.sh -i -y -t /tmp

3.
#Control Node:
sudo /opt/glg/2022.11/OMT/OMT_Embedded_K8s_2022.05-204/upgrade.sh -u

4.
#ALL Nodes concurrently
sudo /opt/glg/2022.11/OMT/OMT_Embedded_K8s_2022.05-204/upgrade.sh -c


### Upgrade OMT 2022.11
5.
#Control Node
sudo /opt/glg/2022.11/OMT/OMT_Embedded_K8s_2022.11-216/upgrade.sh -i -y -t /tmp

6.
#Workers (ALL)
sudo /opt/glg/2022.11/OMT/OMT_Embedded_K8s_2022.11-216/upgrade.sh -i -y -t /tmp

7.
#Control Node:
sudo /opt/glg/2022.11/OMT/OMT_Embedded_K8s_2022.11-216/upgrade.sh -u

8.
#ALL Nodes concurrently
sudo /opt/glg/2022.11/OMT/OMT_Embedded_K8s_2022.11-216/upgrade.sh -c


### Upgrade Vertica
1. Take a full backup of Vertica

2. Shutdown Databaase
> -F is used to drop connections and shutdown
```
sudo su - dbadmin
admintools -t stop_db -d itomdb -p <PASSWORD> -F
```

3. Upgrade Vertica via RPM Package
```
sudo rpm -Uvh /opt/glg/vertica-11.1.1-5.x86_64.RHEL6.rpm
```
```
sudo /opt/vertica/sbin/update_vertica --rpm /opt/glg/vertica-11.1.1-5.x86_64.RHEL6.rpm --dba-user dbadmin
```

### Upgrade UDx pulsar plugin
/opt/vertica/bin/vsql -U dbadmin -w AFCUp@\$\$w0rd2020 -d itomdb -f /usr/local/itom-di-pulsarudx/sql/uninstall.sql
/opt/vertica/bin/admintools -t stop_db -d itomdb -p AFCUp@\$\$w0rd2020 -F
/opt/vertica/bin/admintools -t start_db -d itomdb -p AFCUp@\$\$w0rd2020 -F
sudo rpm -Uvh itom-di-pulsarudx-2.8.0-87.x86_64.rpm

ls -l /usr/local/itom-di-pulsarudx/conf
sudo /usr/local/itom-di-pulsarudx/bin/dbinit.sh genconfig
sudo /usr/local/itom-di-pulsarudx/bin/dbinit.sh -w AFCUp@\$\$w0rd2020 -v
AFCUp@$$w0rd2020