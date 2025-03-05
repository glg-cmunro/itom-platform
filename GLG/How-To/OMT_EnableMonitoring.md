##Enable Monitoring:

### Environment Variables (Update accordingly)

NFS_HOST=$(kubectl get pv itom-vol -o json | jq -r .spec.nfs.server) && echo ${NFS_HOST}
REPOSITORY=$(kubectl get deploy -n core itom-idm -o json | jq -r .spec.template.spec.containers[0].image | awk -F/ '{print $1}') && echo ${REPOSITORY}

#Create Prometheus persistent volume
```
PROM_DIR=/mnt/efs/var/vols/itom/prometheus
sudo mkdir -p ${PROM_DIR}
sudo chown -R 1999:1999 ${PROM_DIR}
sudo chmod -R g+ws ${PROM_DIR}
sudo chmod -R o+xr ${PROM_DIR}

```

#Create Prometheus PV
```
cat << EOT | kubectl apply -f - 
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: itom-vol1
spec:
  accessModes:
  - ReadWriteMany
  capacity:
    storage: 5Gi
  nfs:
    path: /var/vols/itom/prometheus
    server: ${NFS_HOST}
  persistentVolumeReclaimPolicy: Retain
  storageClassName: cdf-default
  volumeMode: Filesystem
EOT

```

##If you cannot source the file, add the correct permissions
#sudo chmod -R g+rx /opt/cdf/properties/images
#sudo chmod -R g+rx /opt/cdf/charts/*
```
source $CDF_HOME/properties/images/charts.properties
helm install prom-crds -n core /opt/cdf/charts/${CHART_ITOM_PROMETHEUS_CRDS} --set global.docker.registry=${REPOSITORY} --set global.docker.orgName=hpeswitom --set global.securityContext.user=1999 --set global.securityContext.fsGroup=1999

```
```
helm upgrade apphub -n core /opt/cdf/charts/${CHART_ITOM_APPHUB} --install --reuse-values --set global.services.monitoring=true

```

#### Add GITOpS monitoring ScrapeConfig  
```
cat << EOT | kubectl apply -f -
---
apiVersion: monitoring.coreos.com/v1alpha1
kind: ScrapeConfig
metadata:
  name: static-config
  namespace: gitops
  labels:
    prometheus: system-monitoring-prometheus
spec:
  staticConfigs:
    - labels:
        job: gitops-monitoring
      targets:
        - custom-monitoring-svc:80
EOT

```

cat << EOT | kubectl apply -f -
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  annotations:
    meta.helm.sh/release-namespace: gitops
  labels:
    app: gitops-monitoring
    prometheus_config: "1"
  name: gitops-monitoring
  namespace: gitops
spec:
  endpoints:
  - path: /metrics
    port: http-web
    scheme: https
    tlsConfig:
      caFile: /var/run/secrets/boostport.com/issue_ca.crt
      insecureSkipVerify: false
      serverName: custom-monitoring-svc
  - path: /metrics
    port: reloader-web
    scheme: http
  namespaceSelector:
    matchNames:
    - gitops
  selector:
    matchLabels:
      app: custom-monitoring
      release: apphub
      self-monitor: "true"
EOT






cat << EOT | kubectl apply -f -
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  labels:
    app: alertmanager
    app.kubernetes.io/managed-by: GITOpS
  annotations:
    ingress.kubernetes.io/backend-protocol: HTTP
    ingress.kubernetes.io/rewrite-target: /\$2
    kubernetes.io/ingress.class: nginx
  name: gitops-alertmanager
  namespace: core
spec:
  rules:
  - http:
      paths:
      - backend:
          service:
            name: alertmanager-operated
            port:
              number: 9093
        path: /alertmanager(/|$)(.*)
        pathType: ImplementationSpecific
  tls:
  - hosts:
    - qa.dev.gitops.com
    secretName: nginx-default-secret

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    ingress.kubernetes.io/backend-protocol: HTTP
    ingress.kubernetes.io/force-ssl-redirect: "true"
    ingress.kubernetes.io/rewrite-target: /\$2
    kubernetes.io/ingress.class: nginx
  labels:
    app: prometheus
    app.kubernetes.io/managed-by: GITOpS
  name: gitops-prometheus
  namespace: core
spec:
  rules:
  - http:
      paths:
      - backend:
          service:
            name: prometheus-operated
            port:
              number: 9090
        path: /prometheus(/|$)(.*)
        pathType: ImplementationSpecific
  tls:
  - hosts:
    - qa.dev.gitops.com
    secretName: nginx-default-secret
EOT
