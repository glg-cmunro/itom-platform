### Get Bits used for Install - Setup folder structure
sudo yum install docker unzip -y
sudo mkdir -p /opt/smax
sudo curl -k -g https://owncloud.greenlightgroup.com/index.php/s/0bflVNJVnP2pExf/download > /opt/smax/CDF1905-00131-15001-managedk8s.zip
sudo unzip /opt/smax/CDF1905-00131-15001-managedk8s.zip -d /opt/smax
sudo unzip /opt/smax/ITOM_Suite_Foundation_Deployer_2019.05.00131.zip -d /opt/smax
sudo mv /opt/smax/ITOM_Suite_Foundation_Deployer_2019.05.00131 /opt/smax/2019.05

sudo curl -k -g https://owncloud.greenlightgroup.com/index.php/s/yxSK4SjiF7UYtd8/download > /tmp/itom-cdf-deployer_1.1.0-00131b.tar
sudo docker login -u oauth2accesstoken -p `gcloud auth print-access-token` gcr.io
sudo docker load < /tmp/itom-cdf-deployer_1.1.0-00131b.tar
sudo docker tag gcr.io/itom-smax-nonprod/itom-cdf-deployer:1.1.0-00131 gcr.io/us102173-p-sis-bsys-6133/itom-cdf-deployer:1.1.0-00131
sudo docker push gcr.io/us102173-p-sis-bsys-6133/itom-cdf-deployer:1.1.0-00131

### CDF INSTALL
PSQL_DB_HOST=10.241.160.2
NFS_SERVER=10.12.81.138
NFS_PATH_CORE=/gcp6133_np_nfs01/var/vols/itom/core
REGISTRY_ORG=us102173-p-sis-bsys-6133
LB_EXT_IP=34.77.69.152
SUITE_VERSION=2019.05
EXT_ACCESS_FQDN=ccc.greenlightgroup.com

### SSH Session #1
#sudo /opt/smax/2019.05.00131/install --nfs-server "10.19.253.90"  --nfs-folder "/smaxdev_nfs/var/vols/itom/core"  --registry-url "gcr.io"  --registry-username "_json_key"  --registry-orgname "gke-smax"  --registry-password-file /opt/smax/2019.05.00131/key.json  --external-access-host "smaxdev-gke.gitops.com"  --cloud-provider gcp --loadbalancer-info "LOADBALANCERIP=34.82.232.8"
sudo /opt/smax/2019.05/install --nfs-server "$NFS_SERVER"  --nfs-folder "$NFS_PATH_CORE"  --registry-url "gcr.io"  --registry-username "_json_key"  --registry-orgname "$REGISTRY_ORG"  --registry-password-file /opt/smax/2019.05/key.json  --external-access-host "$EXT_ACCESS_FQDN"  --cloud-provider gcp --loadbalancer-info "LOADBALANCERIP=$LB_EXT_IP"

### SSH Session #2
CDF_OUTPUT_DIR=/mnt/nfs/var/vols/itom/core/yaml/yaml_template/output
sudo ls -la $CDF_OUTPUT_DIR

#sudo sed -i -e "s@extensions/v1beta1@apps/v1@g" $CDF_OUTPUT_DIR/itom-vault.yaml
sudo kubectl create --save-config -f $CDF_OUTPUT_DIR/itom-vault.yaml
sudo kubectl create --save-config -f $CDF_OUTPUT_DIR/itom-vault-svc.yaml

### Create Self-Signed Cert for CDF install
openssl req -x509 -newkey rsa:4096 -nodes -keyout Server.key -out Server.cer -days 3650 -subj "/C=US/ST=Texas/L=Sugar Land/O=Schlumberger/OU=IT/CN=ccc-dev.greenlightgroup.com"
### Copy files to the Control Node to execute the next step

# Create CDF FrontEnd Secret:
CERT_FILE_1=$(cat Server.cer)
CERT_FILE_2=$(cat InterCA.cer)
KEY_FILE=$(cat Server.key)

cert_pem=$(echo -e "${CERT_FILE_1}\n${CERT_FILE_2}" | base64 -w 0)
key_pem=$(echo -e "${KEY_FILE}"| base64 -w 0)
echo "
    apiVersion: v1
    kind: Secret
    metadata:
      name: itom-cdf-ingress-frontend-secret
      namespace: core
    data:
      tls.crt: "${cert_pem}"
      tls.key: "${key_pem}"
    " | sudo kubectl create --save-config -f - 2>/dev/null

#sudo sed -i -e "s@extensions/v1beta1@apps/v1@g" $CDF_OUTPUT_DIR/kube-vault.yaml
#### Need to add Selector for kube-vault under spec:
##  selector:
##    matchLabels:
##      run: kubernetes-vault
#sudo vi $CDF_OUTPUT_DIR/kube-vault.yaml
sudo kubectl apply -f $CDF_OUTPUT_DIR/kube-vault.yaml

#sudo sed -i -e "s@extensions/v1beta1@apps/v1@g" $CDF_OUTPUT_DIR/suite.yaml
sudo kubectl create --save-config -f $CDF_OUTPUT_DIR/suite.yaml

#sudo sed -i -e "s@extensions/v1beta1@apps/v1@g" $CDF_OUTPUT_DIR/suite-frontend.yaml
sudo kubectl create --save-config -f $CDF_OUTPUT_DIR/suite-frontend.yaml

sudo kubectl create --save-config -f $CDF_OUTPUT_DIR/suite-ingress.yaml

#sudo sed -i -e "s@extensions/v1beta1@apps/v1@g" $CDF_OUTPUT_DIR/itom-ingress-frontend.yaml
sudo kubectl create --save-config -f $CDF_OUTPUT_DIR/itom-ingress-frontend.yaml

sudo kubectl create --save-config -f $CDF_OUTPUT_DIR/itom-ingress-frontend-svc-gcp.yaml


### SUITE INSTALL
SUITE_OUTPUT_DIR=/mnt/nfs/var/vols/itom/core/yaml/yaml_template/output
sudo ls -la $SUITE_OUTPUT_DIR

sudo sed -i -e "s@extensions/v1beta1@apps/v1@" $SUITE_OUTPUT_DIR/itom-fluentd.yaml
sudo kubectl apply -f $SUITE_OUTPUT_DIR/itom-fluentd.yaml

#sudo kubectl apply -f $SUITE_OUTPUT_DIR/itom-logrotate-cfg.yaml
sudo sed -i -e "s@extensions/v1beta1@apps/v1@" $SUITE_OUTPUT_DIR/itom-logrotate.yaml
#### Need to add Selector for itom-logrotate under spec:
## selector:
##   matchLabels:
##     run: itom-logrotate
sudo vi $SUITE_OUTPUT_DIR/itom-logrotate.yaml
sudo kubectl create --save-config -f $SUITE_OUTPUT_DIR/itom-logrotate.yaml

sudo sed -i -e 'N;s/extensions\/v1beta1\(\nkind:\sDeployment\)/apps\/v1\1/;P;D' $SUITE_OUTPUT_DIR/mng-portal.yaml
#sudo vi $SUITE_OUTPUT_DIR/mng-portal.yaml
sudo kubectl apply -f $SUITE_OUTPUT_DIR/mng-portal.yaml

sudo kubectl apply -f $SUITE_OUTPUT_DIR/nginx-ingress-cfg.yaml
sudo sed -i -e 'N;s/extensions\/v1beta1\(\nkind:\sDeployment\)/apps\/v1\1/;P;D' $SUITE_OUTPUT_DIR/nginx-ingress.yaml
sudo kubectl apply -f $SUITE_OUTPUT_DIR/nginx-ingress.yaml
#sudo kubectl apply -f $SUITE_OUTPUT_DIR/nginx-ingress-svc-googlecloud.yaml

sudo sed -i -e 'N;s/extensions\/v1beta1\(\nkind:\sDeployment\)/apps\/v1\1/;P;D' $SUITE_OUTPUT_DIR/idm.yaml
sudo kubectl apply -f $SUITE_OUTPUT_DIR/idm.yaml
#sudo kubectl apply -f $SUITE_OUTPUT_DIR/idm-svc.yaml

sudo sed -i -e 'N;s/extensions\/v1beta1\(\nkind:\sDeployment\)/apps\/v1\1/;P;D' $SUITE_OUTPUT_DIR/itom-postgresql-single-svc.yaml
sudo kubectl apply -f $SUITE_OUTPUT_DIR/itom-postgresql-single-svc.yaml

sudo sed -i -e 'N;s/extensions\/v1beta1\(\nkind:\sDeployment\)/apps\/v1\1/;P;D' $SUITE_OUTPUT_DIR/suite-pg.yaml
sudo kubectl apply -f $SUITE_OUTPUT_DIR/suite-pg.yaml

sudo kubectl create --save-config -f $SUITE_OUTPUT_DIR/suite-ingress.yaml

sudo sed -i -e 'N;s/extensions\/v1beta1\(\nkind:\sDeployment\)/apps\/v1\1/;P;D' /mnt/nfs/var/vols/itom/core/suite-install/itsma/suite_config_template.yaml
sudo kubectl create --save-config -f /mnt/nfs/var/vols/itom/core/suite-install/itsma/suite_config_template.yaml

sudo kubectl apply -f $SUITE_OUTPUT_DIR/cdf-rolebinding.yaml
#sudo kubectl apply -f $SUITE_OUTPUT_DIR/idm-suite-svc.yaml

sudo sed -i -e 'N;s/extensions\/v1beta1\(\nkind:\sDeployment\)/apps\/v1\1/;P;D' $SUITE_OUTPUT_DIR/itom-pg-backup.yaml
#sudo vi $SUITE_OUTPUT_DIR/itom-pg-backup.yaml
sudo kubectl apply -f $SUITE_OUTPUT_DIR/itom-pg-backup.yaml


## LOAD BALANCER SETUP

## TCP Load Balancer
kubectl patch services itom-nginx-ingress-svc -p '{"spec":{"type":"LoadBalancer", "loadBalancerIP": "34.82.232.8"}}' -n $(kubectl get namespaces|grep itsma|head -n 1|awk '{print $1}')

### HTTP Load Balancer / Service / Ingress
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: suite-install-ingress
  namespace: itsma-xayzm
  labels:
    itsmaRelease: "2019.05"
    itsmaService: itom-ingress
  annotations:
    kubernetes.io/ingress.allow-http: "false"
    kubernetes.io/ingress.global-static-ip-name: "smaxdev-public-ip"
    ingress.kubernetes.io/secure-backends: "true"
  finalizers:
  - networking.gke.io/ingress-finalizer
  generation: 1
  resourceVersion: "22370417"
spec:
  rules:
  - host: smaxdev-gke.gitops.com
    http:
      paths:
      - path: /*
        backend:
          serviceName: itom-nginx-ingress-svc
          servicePort: 443
  tls:
  - hosts:
    - smaxdev-gke.gitops.com
    secretName: nginx-default-secret
  backend:
    serviceName: itom-nginx-ingress-svc
    servicePort: 443


sed 'N;s/extensions\/v1beta1\nkind:\sDeployment/apps\/v1\nkind: Deployment/;P;D' testFile.txt
sed 'N;s/extensions\/v1beta1\(\nkind:\sDeployment\)/apps\/v1\1/;P;D' testFile.txt



sudo tee -a ./Server.cer <<EOM
-----BEGIN CERTIFICATE-----
MIIGTjCCBTagAwIBAgIQCdL4zp75S4ShMVCLFEmWMTANBgkqhkiG9w0BAQsFADBP
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMSkwJwYDVQQDEyBE
aWdpQ2VydCBUTFMgUlNBIFNIQTI1NiAyMDIwIENBMTAeFw0yMDEyMTIwMDAwMDBa
Fw0yMjAxMTEyMzU5NTlaMGoxCzAJBgNVBAYTAlVTMQ0wCwYDVQQIEwRVdGFoMRQw
EgYDVQQHEwtXZXN0IEpvcmRhbjEfMB0GA1UEChMWR3JlZW5saWdodCBHcm91cCwg
TExDLjEVMBMGA1UEAwwMKi5naXRvcHMuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOC
AQ8AMIIBCgKCAQEA6xQf1NSya6JsROcLEETyK1pxW2b4XfRTJNqUU/5XqDSiPzON
SbQtDCnWYiMtHFXkEYyxtxe3l8qtPTs0GuEcLj1pu7ojzB9M2xlRnoJbS+5E4sMf
w6EvoF30p8RXpBLO2a5/VEngrCJrAQI/6AJ2PhBhx19Drrm+EtsBfDTicc+nI+C6
Ayf2GX8jALf9BkZnULT9MNCLjSYCTUWN0QY+Z4h96Fho0QYojAMzRZArZ010QH4x
zg3kBaKmqhMFTV+nYjndbeh3OsJ6Rh/W6SfHJl3687t1kFOodyAetLV02nHIuLvw
P5pkTQaFC0f40zrmVx1YzfZb1qyXSJCXBAf8IQIDAQABo4IDCTCCAwUwHwYDVR0j
BBgwFoAUt2ui6qiqhIx56rTaD5iyxZV2ufQwHQYDVR0OBBYEFCqRBnK4QvAp7fp0
gxomXrBkWrfmMCMGA1UdEQQcMBqCDCouZ2l0b3BzLmNvbYIKZ2l0b3BzLmNvbTAO
BgNVHQ8BAf8EBAMCBaAwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMIGL
BgNVHR8EgYMwgYAwPqA8oDqGOGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdp
Q2VydFRMU1JTQVNIQTI1NjIwMjBDQTEuY3JsMD6gPKA6hjhodHRwOi8vY3JsNC5k
aWdpY2VydC5jb20vRGlnaUNlcnRUTFNSU0FTSEEyNTYyMDIwQ0ExLmNybDBMBgNV
HSAERTBDMDcGCWCGSAGG/WwBATAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5k
aWdpY2VydC5jb20vQ1BTMAgGBmeBDAECAjB9BggrBgEFBQcBAQRxMG8wJAYIKwYB
BQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBHBggrBgEFBQcwAoY7aHR0
cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VExTUlNBU0hBMjU2MjAy
MENBMS5jcnQwDAYDVR0TAQH/BAIwADCCAQQGCisGAQQB1nkCBAIEgfUEgfIA8AB2
ACl5vvCeOTkh8FZzn2Old+W+V32cYAr4+U1dJlwlXceEAAABdlUc8egAAAQDAEcw
RQIhAJWMzbBRGa3d+05XwkMMMxrWLY7j+3YBfGTjqz4LBoq0AiBSzxxukIfp6M/3
fOnuAaePh+aqeOJnGl0cnWwwQFpJogB2ACJFRQdZVSRWlj+hL/H3bYbgIyZjrcBL
f13Gg1xu4g8CAAABdlUc8mYAAAQDAEcwRQIhAPtZs/gNLuW0pjY3c0qc3lyaIbQ+
Pekmx5PK/kI2B/xmAiBA4QiJCcSBW7PswxsvXIqNQT04FPCquzczDxGK35vZbjAN
BgkqhkiG9w0BAQsFAAOCAQEAe+GONHTyPj167s7mGN9T4/bIlAfvc8y7TEzDPWQx
DSPsOLbxhwxCMBsPdbbJKHogsO4LgvAy4WDhQkmbGjd9Tnh0kfg5pvXQNvd2Y55o
vpftMQnIkZRGPopnU5PJrNaE7LiPUVEiViFpzFbvu07Wgtuq1qKcHpSWafVv8FWE
SMrr0K1mJ2XQn46yhwuR6VSy4d/7i8cVRtLyvX+B4Cyhx2O2X6djXSiHY7mYNmlw
GBRc448k3yMjZlRnorTbeGxKqc/LepVh4a9PyFAYb2IMmOaquJ1AoHTRIQwNA4lO
IINPp5xckF7F7hrzZ8fMb2vcN3HOAn1Y2pXPTIimM3oDRQ==
-----END CERTIFICATE-----
EOM

sudo tee -a ./InterCA.cer <<EOM
-----BEGIN CERTIFICATE-----
MIIE6jCCA9KgAwIBAgIQCjUI1VwpKwF9+K1lwA/35DANBgkqhkiG9w0BAQsFADBh
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
d3cuZGlnaWNlcnQuY29tMSAwHgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBD
QTAeFw0yMDA5MjQwMDAwMDBaFw0zMDA5MjMyMzU5NTlaME8xCzAJBgNVBAYTAlVT
MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxKTAnBgNVBAMTIERpZ2lDZXJ0IFRMUyBS
U0EgU0hBMjU2IDIwMjAgQ0ExMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
AQEAwUuzZUdwvN1PWNvsnO3DZuUfMRNUrUpmRh8sCuxkB+Uu3Ny5CiDt3+PE0J6a
qXodgojlEVbbHp9YwlHnLDQNLtKS4VbL8Xlfs7uHyiUDe5pSQWYQYE9XE0nw6Ddn
g9/n00tnTCJRpt8OmRDtV1F0JuJ9x8piLhMbfyOIJVNvwTRYAIuE//i+p1hJInuW
raKImxW8oHzf6VGo1bDtN+I2tIJLYrVJmuzHZ9bjPvXj1hJeRPG/cUJ9WIQDgLGB
Afr5yjK7tI4nhyfFK3TUqNaX3sNk+crOU6JWvHgXjkkDKa77SU+kFbnO8lwZV21r
eacroicgE7XQPUDTITAHk+qZ9QIDAQABo4IBrjCCAaowHQYDVR0OBBYEFLdrouqo
qoSMeeq02g+YssWVdrn0MB8GA1UdIwQYMBaAFAPeUDVW0Uy7ZvCj4hsbw5eyPdFV
MA4GA1UdDwEB/wQEAwIBhjAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIw
EgYDVR0TAQH/BAgwBgEB/wIBADB2BggrBgEFBQcBAQRqMGgwJAYIKwYBBQUHMAGG
GGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBABggrBgEFBQcwAoY0aHR0cDovL2Nh
Y2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0R2xvYmFsUm9vdENBLmNydDB7BgNV
HR8EdDByMDegNaAzhjFodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRH
bG9iYWxSb290Q0EuY3JsMDegNaAzhjFodHRwOi8vY3JsNC5kaWdpY2VydC5jb20v
RGlnaUNlcnRHbG9iYWxSb290Q0EuY3JsMDAGA1UdIAQpMCcwBwYFZ4EMAQEwCAYG
Z4EMAQIBMAgGBmeBDAECAjAIBgZngQwBAgMwDQYJKoZIhvcNAQELBQADggEBAHer
t3onPa679n/gWlbJhKrKW3EX3SJH/E6f7tDBpATho+vFScH90cnfjK+URSxGKqNj
OSD5nkoklEHIqdninFQFBstcHL4AGw+oWv8Zu2XHFq8hVt1hBcnpj5h232sb0HIM
ULkwKXq/YFkQZhM6LawVEWwtIwwCPgU7/uWhnOKK24fXSuhe50gG66sSmvKvhMNb
g0qZgYOrAKHKCjxMoiWJKiKnpPMzTFuMLhoClw+dj20tlQj7T9rxkTgl4ZxuYRiH
as6xuwAwapu3r9rxxZf+ingkquqTgLozZXq8oXfpf2kUCwA/d5KxTVtzhwoT0JzI
8ks5T1KESaZMkE4f97Q=
-----END CERTIFICATE-----
EOM

sudo tee -a ./Server.key <<EOM
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDrFB/U1LJromxE
5wsQRPIrWnFbZvhd9FMk2pRT/leoNKI/M41JtC0MKdZiIy0cVeQRjLG3F7eXyq09
OzQa4RwuPWm7uiPMH0zbGVGegltL7kTiwx/DoS+gXfSnxFekEs7Zrn9USeCsImsB
Aj/oAnY+EGHHX0Ouub4S2wF8NOJxz6cj4LoDJ/YZfyMAt/0GRmdQtP0w0IuNJgJN
RY3RBj5niH3oWGjRBiiMAzNFkCtnTXRAfjHODeQFoqaqEwVNX6diOd1t6Hc6wnpG
H9bpJ8cmXfrzu3WQU6h3IB60tXTacci4u/A/mmRNBoULR/jTOuZXHVjN9lvWrJdI
kJcEB/whAgMBAAECggEBAL14bOeHv37NXOJ0LhCg4Wdb8D2xUsG3aUQtAJxqRZCH
S7YRAPHEzQIevnI+098gwz/53EssTIeFjffqPebkRWhni08Jiky9dZ6qW4ScoKUk
mFUE3Bc7VT22PLjzoYfWuO3unSX8nZ9f5krb21JOmasQXR7qg4zSnIZqClpn7ZO4
NRVWcJ5Nqh34iqxY1eLLPV6NHWeoZ9gL3V+vQSMp/RItkwhf2MppI0N1FaW8g0Nt
oaZaNiURqYRqzux3rE5cLJNjqrgoWQU8IqZpiTKWU08tryvCxpClW9H/rxNqowUt
Gpuj6G/qGfZtyH9DblCIGfv6ArA5h8cvava1ua8VztkCgYEA9etlLmPvibLfA6A8
H/eBIxA0yn8lAved2I9CGtwEj6r9jRAfMFJG2eSGxP0mTawXUYMcrdL7yj0h/n3C
f6moTTXUFdQrVfZKOf2VCOJfVE5+gwi9AN6UDeWqTJjDTQF867TUDYQrtSGcO3XT
nS88CG2HW/UF9u7Z9c0c5QHptB8CgYEA9Lb3zJ6Acxc8t+uAkrlyrB9Wws4F1dWm
6+nIoNxaHCs7niAaHr/a5RhoMkAlCp6acU+NDcTtSzd+p1fQQuxD9oq6Xo8hKjxG
CtL+wObT5X5fjw7C2jiMZM38PLJuGNf/DTlrAGcwQK/ezTpmRDkAw5/1Wmv9S6Hz
SRn5+rOKR78CgYEA9aB3wH06/Wt2yxVZ2IgLKS1/vR5/plYTCAIXAeLuf11HwYTv
0gDsGajjX5CGmKAh7l2p4IjSy66B7MJJ6d9YZj40ptTzr/m/K+r32BbbJsb8H/8z
YNHwSW0yyyzuLVUmI/vKrfFtAo8ekFlg0yghqz1TLOswWPM7KwMDME3X0vsCgYBH
jP/jKizwecjdFdSgEez/eqJJjyeRoEiQDekFb6hBODrUPxqkBwCfn4VHvA2Yj0sk
+leJwRyIs48qqrhP+PjeKy3W3A6cZMct/wdRq6wlG9Ag6fX7DDGwf7HSpXEffngq
i7FHiuRG5aVFaF/ibrBUgn6gk5aZ+J5Dr36x2LEDzQKBgAjcxGZ0CFbcZU+8Tvq4
n3EdN32pDWFIN75R5GGb4+AVbIeViVyxmskE45TKVd2RVn5Ed/oUW4jwkXkE/CB6
9DRdYbDfgz2MIu95fxeICJt4FFrOCLkjGIbWJm/rNm+MI1fwdV6Buqmv9mkiLNVn
D6lHct6cM6xk7j5RMQwCNWNE
-----END PRIVATE KEY-----
EOM
