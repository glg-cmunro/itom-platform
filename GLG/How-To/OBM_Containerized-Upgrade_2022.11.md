# Step by Step - ITOM Application Upgrade - OpsBridge SUITE Containerized - 2022.11
![GreenLight Group Logo](https://assets.website-files.com/5ebcb9396faf10d8f7644479/5ed6a066891af295a039860f_GLGLogolrg-p-500.png)

---

## Deployment Steps
> - 
> - 
> - 
> - 
>   - 
> - 
> - 
 

### Update kube-registry cert and helm values after running renewCert
> IF renewCert was executed then we MUST update the helm chart cert or uploadimages.sh will fail
```
openssl genrsa -out registry.key 4096
openssl req -new -key registry.key -subj "/CN=kube-registry.core" -out registry.csr
cat > extfile.conf <<ENDOFFILE
[extensions]
subjectAltName=DNS:kube-registry.core,DNS:localhost,DNS:kube-registry
basicConstraints=CA:FALSE
keyUsage=digitalSignature,keyAgreement,keyEncipherment
extendedKeyUsage=serverAuth,clientAuth
ENDOFFILE
```
```
openssl x509 -req -sha256 -in registry.csr -CAkey $CDF_HOME/ssl/ca.key -CA $CDF_HOME/ssl/ca.crt -CAcreateserial -out registry.crt -days 365 -extensions extensions -extfile extfile.conf
```
```
helm upgrade kube-registry $CDF_HOME/charts/itom-kube-registry-1.5.0-81.tgz  -ncore --reuse-values --set tls.cert=$(base64 -w0 registry.crt) --set tls.key=$(base64 -w0 registry.key)
```


### Deploy OpsBridge 2021.11 Patch 2
```
sudo unzip /opt/glg/obm/2021.11.P2/opsbridge-suite-chart-2021.11.2.zip -d /opt/glg/obm/2021.11.P2/
sudo rm /opt/glg/obm/2021.11.P2/opsbridge-suite-chart-2021.11.2.zip
```

#### Download Images - OBM 2021.11.P2
```
sudo $CDF_HOME/tools/generate-download/generate_download_bundle.sh --chart /opt/glg/obm/2021.11.P2/opsbridge-suite-chart/charts/opsbridge-suite-2.2.5+20211105.39.tgz -d /opt/glg/obm/2021.11.P2/
sudo unzip /opt/glg/obm/2021.11.P2/offline-download.zip -d /opt/glg/obm/2021.11.P2/
sudo rm /opt/glg/obm/2021.11.P2/offline-download.zip
sudo /opt/glg/obm/2021.11.P2/offline-download/downloadimages.sh -o hpeswitom -u dockerhubglg -d /opt/var/cdf/offline/2021.11.P2/images
sudo /opt/glg/obm/2021.11.P2/offline-download/uploadimages.sh -d /opt/var/cdf/offline/2021.11.P2/images -u registry-admin
```

#### Download Images - OBM 2021.11.P3
```
sudo $CDF_HOME/tools/generate-download/generate_download_bundle.sh --chart /opt/glg/obm/2021.11.P3/opsbridge-suite-chart/charts/opsbridge-suite-2.2.5+20211105.39.tgz -d /opt/glg/obm/2021.11.P3/
sudo unzip /opt/glg/obm/2021.11.P3/offline-download.zip -d /opt/glg/obm/2021.11.P3/
sudo rm /opt/glg/obm/2021.11.P3/offline-download.zip
sudo /opt/glg/obm/2021.11.P3/offline-download/downloadimages.sh -o hpeswitom -u dockerhubglg -d /opt/var/cdf/offline/2021.11.P3/images
sudo /opt/glg/obm/2021.11.P3/offline-download/uploadimages.sh -d /opt/var/cdf/offline/2021.11.P3/images -u registry-admin
```

### Backup values and certs
```
NS=opsb-helm

rm -f /tmp/backup_extcerts.yaml

CERTS="$(sudo kubectl -n "$NS" get cm opsb-ca-certificate -o jsonpath='{.data}')"
if [ -n "$CERTS" ]; then
  echo "caCertificates:" >>/tmp/backup_extcerts.yaml
  mapfile -t KEYS < <(echo "$CERTS" | sudo $CDF_HOME/bin/jq -r '. | keys[]')
  for key in "${KEYS[@]}"; do
    echo "  ${key}: |" >>/tmp/backup_extcerts.yaml
    echo "$CERTS" | sudo $CDF_HOME/bin/jq -r ".[\"$key\"]" | sed '/^$/d; s/^/    /; $a\' >>/tmp/backup_extcerts.yaml
  done
fi

CERTS="$(sudo kubectl -n "$NS" get cm api-client-ca-certificates -o jsonpath='{.data}')"
MD5S=()
if [ -n "$CERTS" ]; then
  echo "authorizedClientCAs:" >>/tmp/backup_extcerts.yaml
  mapfile -t KEYS < <(echo "$CERTS" | sudo $CDF_HOME/bin/jq -r '. | keys[]')
  for key in "${KEYS[@]}"; do
    cert="$(echo "$CERTS" | sudo $CDF_HOME/bin/jq -r ".[\"$key\"]")"
    md5="$(openssl x509 -noout -modulus -in <(echo "$cert") | openssl md5 | cut -d "=" -f 2 | xargs)"
    if grep -Fqx "${md5}" <(printf '%s\n' "${MD5S[@]}") &>/dev/null; then
      echo "Skipping duplicate certificate with subject: $(openssl x509 -noout -subject -in <(echo "$cert"))"
      continue
    fi
    MD5S+=("$md5")
    echo "  ${key}: |" >>/tmp/backup_extcerts.yaml
    echo "$cert" | sed '/^$/d; s/^/    /; $a\' >>/tmp/backup_extcerts.yaml
  done
fi

MANUAL_CERTS="$(sudo kubectl -n "$NS" get secret receiver-secret -o jsonpath='{.data}')"
if [ -n "$MANUAL_CERTS" ]; then
  if [ -z "$CERTS" ]; then
    echo "authorizedClientCAs:" >>/tmp/backup_extcerts.yaml
  fi
  mapfile -t KEYS < <(echo "$MANUAL_CERTS" | sudo $CDF_HOME/bin/jq -r '. | keys[]')
  for key in "${KEYS[@]}"; do
    cert="$(echo "$MANUAL_CERTS" | sudo $CDF_HOME/bin/jq -r ".[\"$key\"]" | base64 -d)"
    if ! md5="$(openssl x509 -noout -modulus -in <(echo "$cert") | openssl md5 | cut -d "=" -f 2 | xargs)"; then
      echo "Invalid certificate in receiver's secret's key $key"
      continue
    fi
    if grep -Fqx "${md5}" <(printf '%s\n' "${MD5S[@]}") &>/dev/null; then
      echo "Skipping duplicate certificate with subject: $(openssl x509 -noout -subject -in <(echo "$cert"))"
      continue
    fi
    MD5S+=("$md5")
    echo "  ${key}: |" >>/tmp/backup_extcerts.yaml
    echo "$cert" | sed '/^$/d; s/^/    /; $a\' >>/tmp/backup_extcerts.yaml
  done
fi
```

### Execute helm upgrade
sudo helm upgrade -n opsb-helm opsb-helm /opt/glg/obm/2021.11.P2/opsbridge-suite-chart/charts/opsbridge-suite-2.2.5+20211105.39.tgz -f /tmp/backup_values.yaml -f /tmp/backup_extcerts.yaml


### Download and extract OMT binaries 
```
sudo mkdir -p /opt/glg/obm/2022.05
sudo mkdir -p /opt/glg/obm/2022.11
sudo chown -R jmunro.admin:networkmgmtadmins /opt/glg/obm
```

> OMT 2022.05 w/ embedded Kubernetes
```
curl -kLs https://owncloud.gitops.com/index.php/s/A4RlhIKYlNTGwr7/download -o /opt/glg/obm/2022.05/OMT2205-204-15001-Embedded-K8s.zip
```
```
unzip /opt/glg/obm/2022.05/OMT2205-204-15001-Embedded-K8s.zip -d /opt/glg/obm/2022.05/
rm /opt/glg/obm/2022.05/OMT2205-204-15001-Embedded-K8s.zip
```

> OMT 2022.11 w/ embedded Kubernetes  
```
curl -kLs https://owncloud.gitops.com/index.php/s/Pl3K9AmIcV7nW76/download -o /opt/glg/obm/2022.11/OMT2211-216-15001-Embedded-K8s.zip
```
```
unzip /opt/glg/obm/2022.11/OMT2211-216-15001-Embedded-K8s.zip -d /opt/glg/obm/2022.11/
rm /opt/glg/obm/2022.11/OMT2211-216-15001-Embedded-K8s.zip
```

> OMT 2022.11 w/ embedded Kubernetes  
```
curl -kLs https://owncloud.gitops.com/index.php/s/Pl3K9AmIcV7nW76/download -o /opt/kubernetes/2022.11/OMT2211-216-15001-Embedded-K8s.zip
```
```
unzip /opt/kubernetes/2022.11/OMT2211-216-15001-Embedded-K8s.zip -d /opt/kubernetes/2022.11/
rm /opt/kubernetes/2022.11/OMT2211-216-15001-Embedded-K8s.zip
unzip /opt/kubernetes/2022.11/OMT_Embedded_K8s_2022.11-216.zip -d /opt/kubernetes/2022.11/
rm /opt/kubernetes/2022.11/OMT_Embedded_K8s_2022.11-216.zip
rm /opt/kubernetes/2022.11/OMT_Embedded_K8s_2022.11-216.zip.sig
```

> OpsBridge SUITE chart 2022.11  
```
curl -kLs https://owncloud.greenlightgroup.com/index.php/s/0qGBMElJxytrAGV/download -o /opt/glg/obm/2022.11/opsbridge-suite-chart-2022.11.0.zip
```
```
unzip /opt/glg/obm/2022.11/opsbridge-suite-chart-2022.11.0.zip -d /opt/glg/obm/2022.11/
```

> OpsBridge SUITE chart 2022.11.P3  
```
curl -kLs https://owncloud.greenlightgroup.com/index.php/s/3Ulehy7jeWIcuQB/download -o /opt/glg/obm/2022.11.P3/opsbridge-suite-chart-2022.11.3.zip
```
```
unzip /opt/glg/obm/2022.11.P3/opsbridge-suite-chart-2022.11.3.zip -d /opt/glg/obm/2022.11.P3/
rm /opt/glg/obm/2022.11.P3/opsbridge-suite-chart-2022.11.3.zip
```

> OpsBridge SUITE chart 2022.11  
```

```
```
unzip /opt/kubernetes/2022.11/OMT2211-216-15001-Embedded-K8s.zip -d /opt/kubernetes/2022.11/
rm /opt/kubernetes/2022.11/OMT2211-216-15001-Embedded-K8s.zip

```

#### Download container images
```
sudo $CDF_HOME/tools/generate-download/generate_download_bundle.sh --chart /opt/glg/obm/2022.11/opsbridge-suite-chart/charts/opsbridge-suite-2.4.0+20221100.457.tgz -d /opt/glg/obm/2022.11/
sudo unzip /opt/glg/obm/2022.11/offline-download.zip -d /opt/glg/obm/2022.11/
sudo rm /opt/glg/obm/2022.11/offline-download.zip
sudo /opt/glg/obm/2022.11/offline-download/downloadimages.sh -o hpeswitom -u dockerhubglg -d /opt/var/cdf/offline/obm/2022.11/images
sudo /opt/glg/obm/2022.11/offline-download/uploadimages.sh -d /opt/var/cdf/offline/obm/2022.11/images/ -u registry-admin
```

```
sudo $CDF_HOME/tools/generate-download/generate_download_bundle.sh --chart /opt/glg/obm/2022.11.P3/opsbridge-suite-chart/charts/opsbridge-suite-2.4.3+20221103.100.tgz -d /opt/glg/obm/2022.11.P3/
sudo unzip /opt/glg/obm/2022.11.P3/offline-download.zip -d /opt/glg/obm/2022.11.P3/
sudo rm /opt/glg/obm/2022.11.P3/offline-download.zip
sudo /opt/glg/obm/2022.11.P3/offline-download/downloadimages.sh -o hpeswitom -u dockerhubglg -d /opt/var/cdf/offline/obm/2022.11.P3/images
sudo /opt/glg/2022.11.P3/offline-download/uploadimages.sh -d /opt/var/cdf/offline/obm/2022.11.P3/images -u registry-admin
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
#sudo /opt/glg/2022.11/OMT/OMT_Embedded_K8s_2022.11-216/upgrade.sh -i -y -t /tmp
sudo /opt/kubernetes/2022.11/OMT_Embedded_K8s_2022.11-216/upgrade.sh -i -y -t /tmp

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
export DBCRED='AFCUp@$$w0rd2020'
export VERTICA_DBA_PASS='AFCUp@$$w0rd2020'
admintools -t stop_db -d itomdb -p $DBCRED -F
```

3. Upgrade Vertica via RPM Package
```
curl -kL https://owncloud.gitops.com/index.php/s/21sk1MWKRuFPYPJ/download -o /opt/glg/vertica-11.1.1-5.x86_64.RHEL6.rpm
sudo rpm -Uvh /opt/glg/vertica-11.1.1-5.x86_64.RHEL6.rpm
```
```
sudo /opt/vertica/sbin/update_vertica --rpm /opt/glg/vertica-11.1.1-5.x86_64.RHEL6.rpm --dba-user dbadmin
```

### Uninstall old UDx pulsar plugin
sudo /opt/vertica/bin/vsql -U dbadmin -w $DBCRED -d itomdb -f /usr/local/itom-di-pulsarudx/sql/uninstall.sql
/opt/vertica/bin/admintools -t stop_db -d itomdb -p $DBCRED -F
/opt/vertica/bin/admintools -t start_db -d itomdb -p $DBCRED -F

### Upgrade UDx pulsar plugin
sudo rpm -Uvh itom-di-pulsarudx-2.8.0-87.x86_64.rpm
sudo rpm -Uvh itom-di-pulsarudx-2.8.1-2.x86_64.rpm

ls -l /usr/local/itom-di-pulsarudx/conf
sudo /usr/local/itom-di-pulsarudx/bin/dbinit.sh genconfig
sudo /usr/local/itom-di-pulsarudx/bin/dbinit.sh -w $DBCRED -v


### Upgrade Helm chart for Storage Provisioner
sudo helm get values -n core lpv > hvalues-lpv.yaml
sudo helm upgrade lpv /opt/cdf/charts/itom-kubernetes-local-storage-provisioner-2.3.3-230.tgz -n core

### Update PVs
> storageclassname  
sudo kubectl edit pv opsbvol5
sudo kubectl edit pv opsbvol6


### Create ArtemisPV
vi artemispv.yaml

apiVersion: v1
kind: PersistentVolume
metadata:
  name: opsbvol7
spec:
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 10Gi
  nfs:
    path: /var/vols/itom/opsbvol7
    server: lxot-optic-nfs.afcucorp.test
  persistentVolumeReclaimPolicy: Retain
  volumeMode: Filesystem

#On the NFS server
---
sudo mkdir -p /var/vols/itom/opsbvol7
sudo chown -R 1999:1999 /var/vols/itom/opsbvol7
sudo vi /etc/exports
sudo exportfs -ra
sudo exportfs
---

sudo kubectl create -f artemispv.yaml















### Install PostgreSQL 14 - RHEL 8
```
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo dnf -qy module disable postgresql
sudo dnf install -y postgresql14-server
sudo /usr/pgsql-14/bin/postgresql-14-setup initdb
sudo systemctl enable postgresql-14
sudo systemctl start postgresql-14
```

### Secure PostgreSQL 14
