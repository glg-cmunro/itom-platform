# GreenLight Group How To - Enable Prometheus Monitoring for SMAX cluster 2022.11
![GreenLight Group Logo](https://assets.website-files.com/5ebcb9396faf10d8f7644479/5ed6a066891af295a039860f_GLGLogolrg-p-500.png)

---

#### Setup Persistence Filestore
##### Create EFS directories for PVs
```
sudo mkdir -p /mnt/efs/var/vols/itom/vol1
sudo chown -R 1999:1999 /mnt/efs/var/vols/itom/vol1
```

`mkdir ~/prometheus`

##### Create PV
> To create PV you will need to get the EFS Server IP/FQDN and the Filestore Path (typically the path minus the local mount point '/mnt/efs')

`vi ~/prometheus/prometheus_pv.yaml`  
```
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
    path: /var/vols/itom/vol1
    server: fs-0647c26ba62d36752.efs.us-east-1.amazonaws.com
  persistentVolumeReclaimPolicy: Retain
  storageClassName: cdf-default
  volumeMode: Filesystem
```

`kubectl create -f ~/prometheus/prometheus_pv.yaml`  

##### Install Prometheus CRDs
> To install CRDs you will need to get the ECR Registry and the appropriate version of the CRDs chart  
> Get ECR Registry from the apphub helm chart: `helm get values -n core apphub -ojson | jq -r .global.docker.registry`  
```
helm install prom-crds -n core /opt/smax/2022.11/cdf/charts/itom-prometheus-crds-1.4.0-35.tgz --set global.persistence.logVolumeClaim=itom-logging-vol --set global.docker.registry=713745958112.dkr.ecr.us-east-1.amazonaws.com --set global.docker.orgName=hpeswitom --set global.securityContext.user=1999 --set global.securityContext.fsGroup=1999 --set logPersistent=true
```
---

Get current apphub chart from helm
`helm list -n core`
**NOTE: take down the chart version for use in the upgrade command**

`helm upgrade -n core apphub /opt/smax/2022.11/cdf/charts/apphub-1.22.0+20221100.230.tgz --reuse-values --set global.services.monitoring=true`

`helm upgrade apphub -n core /opt/smax/2022.11/cdf/charts/apphub-1.22.0+20221100.230.tgz --reuse-values --set global.prometheus.deployPrometheusConfig=true --set global.prometheus.deployGrafanaConfig=true`


##### Create Prometheus ingress
`vi ~/prometheus/prometheus_ingress.yaml`
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    ingress.kubernetes.io/backend-protocol: HTTP
    ingress.kubernetes.io/rewrite-target: /$2
    kubernetes.io/ingress.class: nginx
  generation: 1
  labels:
    app: prometheus
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/version: prometheus-prometheus
    helm.sh/chart: prometheus-5.5.5
    release: cdf-prometheus
  name: gitops-prometheus
  namespace: core
spec:
  rules:
  - host: testing.dev.gitops.com
    http:
      paths:
      - backend:
          service:
            name: prometheus-operated
            port:
              number: 9090
        path: /prometheus(/|$)(.*)
        pathType: ImplementationSpecific
```
`kubectl create -f ~/prometheus/prometheus_ingress.yaml`

`vi ~/prometheus/alertmanager_ingress.yaml`
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    ingress.kubernetes.io/backend-protocol: HTTP
    ingress.kubernetes.io/rewrite-target: /$2
    kubernetes.io/ingress.class: nginx
  generation: 1
  labels:
    app: alertmanager
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/version: prometheus-prometheus
    helm.sh/chart: prometheus-5.5.5
    release: cdf-prometheus
  name: gitops-alertmanager
  namespace: core
spec:
  rules:
  - host: testing.dev.gitops.com
    http:
      paths:
      - backend:
          service:
            name: alertmanager-operated
            port:
              number: 9093
        path: /alertmanager(/|$)(.*)
        pathType: ImplementationSpecific
```
`kubectl create -f ~/prometheus/alertmanager_ingress.yaml`




#### Setup Alertmanager chart/values for deployment  
##### Create values.yaml for Alertmanager  

`vi ~/prometheus/prometheus_values.yaml`  
```
prometheus:
  grafana:
    resources:
      limits:
        memory: 4000Mi
  prometheus:
    prometheusSpec:
      retentionSize: 1GB
      retention: 10d
      resources:
        limits:
          memory: 9000Mi
  alertmanager:
    config:
      global:
        resolve_timeout: 5m
        smtp_smarthost: prometheus_testing@greenlightgroup.com
        smtp_from: email-smtp.us-east-1.amazonaws.com:587
        smtp_auth_username: AKIAZSYWGF44GRD6A3DR
        smtp_auth_password: BNxG3FyA6B+Yr2j50IfoR7qfp2FOMI3GjWJELlnU3mI1
        smtp_auth_identity: AKIAZSYWGF44GRD6A3DR
      receivers:
      - name: "null"
      - name: "gitops-email"
        email_configs:
        - to: "chris@greenlightgroup.com,brian@greenlightgroup.com"
          send_resolved: true
          headers:
            subject: '{{template "gitops_email_subject" .}}'
          html: '{{template "gitops_email_body" .}}'
      - name: notify-critical
        email_configs:
        - send_resolved: true
          to: chris@greenlightgroup.com
          from: CRITICAL_NOTIFY_optic@greenlightgroup.com
          headers:
            subject: 'CRITICAL_NOTIFY: {{template "email.default.subject" . }}'
          html:
            '{{ template "email.default.html" . }}'
      #- name: notify-critical
      #  email_configs:
      #  - send_resolved: true
      #    to: chris@greenlightgroup.com
      #    from: CRITICAL_NOTIFY_optic@greenlightgroup.com
      #    headers:
      #      subject: 'CRITICAL_NOTIFY: {{template "gitops_email_subject" .}}'
      #    html:
      #      '{{template "gitops_email_body" .}}'
      - name: "signl4-webhook-oncall"
        webhook_configs:
        - url: https://connect.signl4.com/webhook/8ypkwkvxxb
          send_resolved: true
      - name: "signl4-webhook-engineers"
        webhook_configs:
        - url: https://connect.signl4.com/webhook/q59fzfs3fe
          send_resolved: true
      route:
        receiver: "gitops-email"
        group_by:
        - alertname
        routes:
        - receiver: "null"
          match_re:
           alertname: Watchdog|InfoInhibitor
        - receiver: "critical-notify"
          match:
            severity: critical
          continue: true
        - receiver: "signl4-webhook-oncall"
          group_by:
          - alertname
          continue: true
        - receiver: "gitops-email-receiver"
          group_by:
          - alertname
        group_wait: 30s
        group_interval: 5m
        repeat_interval: 12h
      templates:
      - /etc/alertmanager/config/*.tmpl
      - '/data/alertmanager-templates/*.tmpl'
```

`helm upgrade -n core apphub /opt/smax/2022.11/cdf/charts/apphub-1.22.0+20221100.230.tgz --reuse-values --set global.services.monitoring=true -f ~/prometheus/prometheus_values.yaml`


## Setup GITOpS Monitoring
##### Create gitops namespace
`kubectl create namespace gitops`

##### Create gitops PV and PVC
```
sudo mkdir -p /mnt/efs/var/vols/gitops/gitops-monitoring
sudo chown -R 1999:1999 /mnt/efs/var/vols/gitops
```

`vi ~/monitoring/gitops_pv-pvc.yaml`
```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: gitops-monitoring-vol
spec:
  accessModes:
  - ReadWriteMany
  capacity:
    storage: 10Gi
  nfs:
    path: /var/vols/itom/gitops/gitops-monitoring
    server: fs-0647c26ba62d36752.efs.us-east-1.amazonaws.com
  persistentVolumeReclaimPolicy: Retain
  storageClassName: gitops
  volumeMode: Filesystem

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gitops-monitoring-pvc
  namespace: gitops
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  selector:
    matchLabels:
      purpose: gitops-monitoring-vol
  storageClassName: gitops
  volumeMode: Filesystem
  volumeName: gitops-monitoring-vol
```
`kubectl create -f ~/monitoring/gitops_pv-pvc.yaml`
