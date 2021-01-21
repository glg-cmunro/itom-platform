#!/bin/bash
export VAULT_TOKEN=`kubectl get cm -n core kube-vault-configmap -o json | /opt/kubernetes/bin/jq -r .data.'"kube-vault.token"'`
echo Set Current Token: "$VAULT_TOKEN"
export MASTER_IP=`hostname -i`
#export VAULT_TOKEN=`etcdctl --endpoint=https://$MASTER_IP:4001 --ca-file /opt/kubernetes/ssl/ca.crt --cert-file /opt/kubernetes/ssl/server.crt --key-file /opt/kubernetes/ssl/server.key get /registry/vault/root-token`
export VAULT_TOKEN=`etcdctl --endpoints=[https://$MASTER_IP:4001] --cacert=/opt/kubernetes/ssl/ca.crt --cert=/opt/kubernetes/ssl/server.crt --key=/opt/kubernetes/ssl/server.key get /registry/vault/root-token`
echo Set Root Token: "$VAULT_TOKEN"
kubectl delete configmap kube-vault-configmap -n core
kubectl create configmap kube-vault-configmap -n core --from-literal=kube-vault.token=`vault token-create -tls-skip-verify -role=kubernetes-vault -format=json | /opt/kubernetes/bin/jq -r .auth.client_token`
