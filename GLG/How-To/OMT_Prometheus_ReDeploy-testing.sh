cat << EOT > ~/gitops-alertmanager-config.tmp
global:
  smtp_smarthost: "email-smtp.us-east-1.amazonaws.com:587"
  smtp_from: prometheus_testing@greenlightgroup.com
  smtp_auth_username: <AWS_KEY>
  smtp_auth_identity: <AWS_KEY>
  smtp_auth_password: <AWS_SECRET>
  resolve_timeout: 5m
route:
  receiver: "gitops-email-receiver"
  group_by:
  - alertname
  routes:
  - receiver: "null"
    matchers:
    - alertname =~ "InfoInhibitor|Watchdog"
  - receiver: "signl4-webhook-oncall"
    group_by:
    - alertname
    continue: true
  - receiver: "gitops-email-receiver"
    group_by:
    - alertname
  group_interval: 5m
  group_wait: 30s
  repeat_interval: 12h
inhibit_rules:
- target_matchers:
  - severity =~ warning|info
  source_matchers:
  - severity = critical
  equal:
  - namespace
  - alertname
- target_matchers:
  - severity = info
  source_matchers:
  - severity = warning
  equal:
  - namespace
  - alertname
- target_matchers:
  - severity = info
  source_matchers:
  - alertname = InfoInhibitor
  equal:
  - namespace
receivers:
- name: "null"
- name: "gitops-email-receiver"
  email_configs:
  - to: "chris@greenlightgroup.com,brian@greenlightgroup.com"
    send_resolved: true
    headers:
      subject: '{{ template "gitops_email_subject" . }}'
    html: '{{ template "gitops_email_body" . }}'
- name: "signl4-webhook-oncall"
  webhook_configs:
  - url: https://connect.signl4.com/webhook/8ypkwkvxxb
    send_resolved: true
templates:
- /etc/alertmanager/config/*.tmpl
- /data/alertmanager/templates/*.tmpl
EOT

amconfigstring=$(cat ~/gitops-alertmanager-config.tmp | base64 -w0)
amconfiggzstring=$(cat ~/gitops-alertmanager-config.tmp | gzip - | base64 -w0)
rm -f ~/gitops-alert-manager-config.tmp

#Current AlertManager Config secret
amconfigsecret=$(kubectl get secret -n core alertmanager-itom-prometheus-alertmanager-generated -ojson | jq -r '.data."alertmanager.yaml.gz"')
#kubectl patch secret -n core alertmanager-itom-prometheus-alertmanager-generated -p '{"data":{"alertmanager.yaml.gz":"'"$amconfigsecret"'"}}'

kubectl patch secret -n core alertmanager-itom-prometheus-alertmanager -p '{"data":{"alertmanager.yaml":"'"$amconfigstring"'"}}'
kubectl patch secret -n core alertmanager-itom-prometheus-alertmanager-generated -p '{"data":{"alertmanager.yaml.gz":"'"$amconfiggzstring"'"}}'



######
# Patch Prometheus
######
kubectl patch prometheus -n core itom-prometheus-prometheus --type='json' -p='[{"op": "replace", "path": "/spec/externalUrl", "value": "https://smax-west.gitops.com:5443/prometheus"}]'


######
# Patch Alertmanager
######
kubectl patch alertmanager -n core itom-prometheus-alertmanager --type='json' -p='[{"op": "replace", "path": "/spec/externalUrl", "value": "https://smax-west.gitops.com:5443/alertmanager"}]'


kubectl patch alertmanager -n core itom-prometheus-alertmanager --type='json' -p='[{"op": "add", "path": "/spec/volumes/2", "value": {"name": "gitops-volume", "configMap": {"name": "gitops-alertmanager-email-template"}}}]'

spec.volumes[2].[{}]