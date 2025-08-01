> kubectl describe nodes | grep cpu
>   cpu                6625m (83%)        60010m (758%)
>   cpu                5575m (70%)        29900m (378%)
>   cpu                6360m (80%)        71020m (897%)
>   cpu                6820m (86%)        65400m (826%)
>   cpu                6015m (76%)        70490m (891%)
>                     31395
> 
>   cpu                3865m (48%)        59310m (749%)
>   cpu                3897m (49%)        28350m (358%)
>   cpu                4176m (52%)        81670m (1032%)
>   cpu                6350m (80%)        65900m (833%)
>   cpu                4998m (63%)        69690m (881%)
>                     23286
> 
>   cpu                5092m (64%)        91940m (1162%)
>   cpu                5092m (64%)       113290m (1432%)
>   cpu                3662m (46%)        110840m (1401%)
>                     13846

```
kubectl get deploy -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,CONTAINER:.spec.template.spec.containers[*].name,CPUREQ:.spec.template.spec.containers[*].resources.requests.cpu
kubectl get daemonset -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,CONTAINER:.spec.template.spec.containers[*].name,CPUREQ:.spec.template.spec.containers[*].resources.requests.cpu
kubectl get prometheuses -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,CONTAINER:.spec.containers[*].name,CPUREQ:.spec.containers[*].resources.requests.cpu,PROMREQ:.spec.resources.requests.cpu

```

## SMAX (ITSMA Suite)
<details><summary>Sample pods and requests</suummary>

#itsma-pw118   autopass-lm-v2                        kubernetes-vault-renew,autopass-lm                        1m,5m
#itsma-pw118   idm                                   idm,kubernetes-vault-renew                                10m,1m
#itsma-pw118   itom-bo-ats-deployment                itom-bo-ats,kubernetes-vault-renew                        2m,1m
#itsma-pw118   itom-bo-config-deployment             kubernetes-vault-renew,itom-bo-config                     1m,2m
#itsma-pw118   itom-bo-facade-deployment             kubernetes-vault-renew,itom-bo-facade                     1m,2m
#itsma-pw118   itom-bo-fo-ui-deployment              itom-bo-fo-ui,kubernetes-vault-renew                      1m,1m
#itsma-pw118   itom-bo-license-deployment            kubernetes-vault-renew,itom-bo-license                    1m,2m
#itsma-pw118   itom-bo-login-deployment              kubernetes-vault-renew,itom-bo-login                      1m,5m
#itsma-pw118   itom-bo-ui-deployment                 kubernetes-vault-renew,itom-bo-ui                         1m,1m
#itsma-pw118   itom-bo-user-deployment               kubernetes-vault-renew,itom-bo-user                       1m,2m
#itsma-pw118   itom-bo-user-offline-deployment       kubernetes-vault-renew,itom-bo-user                       1m,2m

#itsma-pw118   itom-carbon-footprint-deployment      itom-carbon-footprint-deployment,kubernetes-vault-renew   2m
#itsma-pw118   itom-cgro-costpolicy                  kubernetes-vault-renew,itom-cgro-costpolicy               1m,5m
#itsma-pw118   itom-cgro-insights                    itom-cgro-insights,kubernetes-vault-renew                 5m,1m
#itsma-pw118   itom-cgro-insights-gateway            itom-cgro-insights-gateway,kubernetes-vault-renew         5m,1m
#itsma-pw118   itom-cgro-policy-gateway              itom-cgro-policy-gateway,kubernetes-vault-renew           5m,1m
#itsma-pw118   itom-cgro-showback                    kubernetes-vault-renew,itom-cgro-showback                 1m,5m
#itsma-pw118   itom-cgro-showback-gateway            kubernetes-vault-renew,itom-cgro-showback-gateway         1m,5m
#itsma-pw118   itom-cmp-accounts                     kubernetes-vault-renew,itom-cmp-accounts                  1m,5m
#itsma-pw118   itom-cmp-config-controller            itom-cmp-config-controller,kubernetes-vault-renew         5m,1m
#itsma-pw118   itom-cmp-integration-gateway          itom-cmp-integration-gateway,kubernetes-vault-renew       5m,1m
#itsma-pw118   itom-cmp-scheduler                    kubernetes-vault-renew,itom-cmp-scheduler                 1m,5m
#itsma-pw118   itom-content-store-backend            kubernetes-vault-renew,itom-content-store-backend         1m,5m
#itsma-pw118   itom-content-store-gateway            kubernetes-vault-renew,itom-content-store-gateway         1m,5m
#itsma-pw118   itom-dnd-cms-synchronizer             itom-dnd-cms-synchronizer,kubernetes-vault-renew          5m,1m
#itsma-pw118   itom-dnd-controller                   kubernetes-vault-renew,itom-dnd-controller                1m,5m
#itsma-pw118   itom-dnd-deploy-controller            itom-dnd-deploy-controller                                1m
#itsma-pw118   itom-dnd-image-catalog                kubernetes-vault-renew,itom-dnd-image-catalog             1m,5m
#itsma-pw118   itom-dnd-image-catalog-gateway        itom-dnd-image-catalog-gateway,kubernetes-vault-renew     5m,1m
#itsma-pw118   itom-dnd-instance-management          itom-dnd-instance-management,kubernetes-vault-renew       5m,1m
#itsma-pw118   itom-dnd-operations-gateway           itom-dnd-operations-gateway,kubernetes-vault-renew        5m,1m
</details>

#### ITOM BO / Autopass  
```
kubectl patch deploy -n $NS autopass-lm-v2 --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"}
]'; \
kubectl patch deploy -n $NS idm --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "10m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS itom-bo-ats-deployment --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "2m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS itom-bo-config-deployment --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "2m"}
]'; \
kubectl patch deploy -n $NS itom-bo-facade-deployment --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "2m"}
]'; \
kubectl patch deploy -n $NS itom-bo-fo-ui-deployment --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS itom-bo-license-deployment --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "2m"}
]'; \
kubectl patch deploy -n $NS itom-bo-login-deployment --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"}
]'; \
kubectl patch deploy -n $NS itom-bo-ui-deployment --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS itom-bo-user-deployment --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "2m"}
]'; \
kubectl patch deploy -n $NS itom-bo-user-offline-deployment --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "2m"}
]'

```

#### HCMX (Cost Governance)  
```
kubectl patch deploy -n $NS itom-carbon-footprint-deployment --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "2m"}
]'; \
kubectl patch deploy -n $NS itom-cgro-costpolicy --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"}
]'; \
kubectl patch deploy -n $NS itom-cgro-insights --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "5m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS itom-cgro-insights-gateway --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "5m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS itom-cgro-policy-gateway --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "5m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS itom-cgro-showback --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"}
]'; \
kubectl patch deploy -n $NS itom-cgro-showback-gateway --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"}
]'; \
kubectl patch deploy -n $NS itom-cmp-accounts --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"}
]'; \
kubectl patch deploy -n $NS itom-cmp-config-controller --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "5m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS itom-cmp-integration-gateway --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "5m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS itom-cmp-scheduler --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"}
]'; \
kubectl patch deploy -n $NS itom-content-store-backend --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"}
]'; \
kubectl patch deploy -n $NS itom-content-store-gateway --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"}
]'; \
kubectl patch deploy -n $NS itom-dnd-cms-synchronizer --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "5m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS itom-dnd-controller --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"}
]'; \
kubectl patch deploy -n $NS itom-dnd-deploy-controller --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS itom-dnd-image-catalog --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"}
]'; \
kubectl patch deploy -n $NS itom-dnd-image-catalog-gateway --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "5m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS itom-dnd-instance-management --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "5m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS itom-dnd-operations-gateway --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "5m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'

```

#### ESM (ITSMA SMAX Suite)
```
kubectl patch deploy -n $NS itom-esm-api --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "5m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS itom-iac-controller --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"}
]'; \
kubectl patch deploy -n $NS itom-itsma-certificate-deployment --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "2m"}
]'; \
kubectl patch deploy -n $NS itom-nginx-ingress-deployment --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "20m"}
]'; \
kubectl patch deploy -n $NS itom-scheduler --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "10m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS itom-sma-ui-deployment --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS itom-sma-xie-deployment --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "20m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS itom-toolkit --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS itom-xruntime-datahub --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"}
]'; \
kubectl patch deploy -n $NS itom-xruntime-gateway --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "15m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS itom-xruntime-mobile-gateway --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "2m"}
]'; \
kubectl patch deploy -n $NS itom-xruntime-opb-ui --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS itom-xruntime-platform --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "50m"}
]'; \
kubectl patch deploy -n $NS itom-xruntime-platform-offline --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "50m"}
]'; \
kubectl patch deploy -n $NS itom-xruntime-platform-offline-ng --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "10m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS itom-xruntime-platform-readonly --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "100m"}
]'; \
kubectl patch deploy -n $NS itom-xruntime-ppo --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS itom-xruntime-redis --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "10m"}
]'; \
kubectl patch deploy -n $NS itom-xruntime-serviceportal --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"}
]'; \
kubectl patch deploy -n $NS itom-xruntime-ui --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "5m"}
]'; \
kubectl patch deploy -n $NS itom-xruntime-websocket-gateway --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"}
]'; \
kubectl patch deploy -n $NS itom-xruntime-xmpp --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "2m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"},
  {"op": "replace", "path": "/spec/template/spec/containers/2/resources/requests/cpu", "value": "1m"}
]'; \
#kubectl patch deploy -n $NS sam-backend-deployment --type='json' -p='[
#  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "5m"},
#  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "50m"}
#]'; \
#kubectl patch deploy -n $NS sam-ui-deployment --type='json' -p='[
#  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "10m"},
#  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"}
#]'; \
kubectl patch deploy -n $NS smarta-admin-ui-backend --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS smarta-data-source --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "5m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS smarta-installer --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "5m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS smarta-ocr --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"}
]'; \
kubectl patch deploy -n $NS smarta-saw-dih --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "2m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS smarta-saw-proxy --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS smarta-sawarc-dih --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "2m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS smarta-sawmeta-dih --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS smarta-search --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "2m"}
]'; \
kubectl patch deploy -n $NS smarta-smart-ticket --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"}
]'; \
kubectl patch deploy -n $NS smarta-smart-ticket-admin-ui --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS smarta-smart-ticket-task --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"}
]'; \
kubectl patch deploy -n $NS smarta-stx-agent --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "11m"}
]'; \
kubectl patch deploy -n $NS smarta-stx-category --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS smarta-stx-media --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "10m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS virtual-agent-admin-ui --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "2m"},
  {"op": "replace", "path": "/spec/template/spec/containers/2/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS virtual-agent-bot-engine --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "2m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/2/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n $NS virtual-agent-nlu --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/2/resources/requests/cpu", "value": "1m"}
]'

```

#### Containerized OO
```
kubectl patch deploy -n oo itom-autopass-lms --type='json' --patch='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "50m"}
]'; \
kubectl patch deploy -n oo itom-oocentral --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "200m"}
]'; \
kubectl patch deploy -n oo itom-oocontroller --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "500m"}
]'; \
kubectl patch deploy -n oo itom-oodownloader --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "500m"}
]'; \
kubectl patch deploy -n oo itom-ooscheduler --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "500m"}
]'; \
kubectl patch deploy -n oo itom-oosession-manager --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "100m"}
]'; \
kubectl patch deploy -n oo itom-vault --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "100m"}
]'; \
kubectl patch deploy -n oo oo-itom-ingress-controller --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "10m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/2/resources/requests/cpu", "value": "1m"}
]'

```

#### Velero - Cluster Backup
```
kubectl patch deploy -n velero velero --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "50m"}
]'

```

#### OMT and related 'core'
```
kubectl patch deploy -n core apphub-apiserver --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"}
]'; \
kubectl patch deploy -n core apphub-ui --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"}
]'; \
kubectl patch deploy -n core cdf-apiserver --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n core frontend-ingress-controller --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "10m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n core itom-frontend-ui --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "5m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n core itom-idm --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "5m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n core itom-kube-dashboard --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n core itom-kube-dashboard-metrics-scraper --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n core itom-mng-portal --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "2m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n core itom-prometheus-grafana --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/2/resources/requests/cpu", "value": "5m"}
]'; \
kubectl patch deploy -n core itom-prometheus-kube-state-metrics --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/2/resources/requests/cpu", "value": "2m"}
]'; \
kubectl patch deploy -n core itom-prometheus-operator --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n core itom-reloader --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "5m"}
]'; \
kubectl patch deploy -n core itom-vault --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "100m"}
]'; \
kubectl patch deploy -n core portal-ingress-controller --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "10m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch deploy -n core suite-conf-pod-itsma --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "15m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'; \
kubectl patch daemonset -n $NS itom-throttling-controller --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'

```

#### Prometheus in OMT
```
kubectl patch prometheuses -n core itom-prometheus-prometheus --type='json' -p='[
  {"op": "replace", "path": "/spec/resources/requests/cpu", "value": "75m"},
  {"op": "replace", "path": "/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'

```

#### Audit Controller
```
kubectl patch deploy -n audit audit-itom-ingress-controller --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "5m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/2/resources/requests/cpu", "value": "2m"}
]'; \
kubectl patch deploy -n audit itom-audit-deployment --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "50m"}
]'; \
kubectl patch deploy -n audit itom-audit-gateway-deployment --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "20m"}
]'; \
kubectl patch deploy -n audit itom-vault --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "100m"}
]'

```

#### K8s Cluster environment 'kube-system'
##kube-system   aws-load-balancer-controller          aws-load-balancer-controller                              <none>
#kubectl patch deploy -n kube-system aws-load-balancer-controller --type='json' -p='[
#  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "5m"}
#]'

#kube-system   coredns                               coredns                                                   5m
kubectl patch deploy -n kube-system coredns --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "5m"}
]'

#kube-system   metrics-server                        metrics-server                                            5m
kubectl patch deploy -n kube-system metrics-server --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "5m"}
]'

##kubectl get ds -n kube-system -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,CONTAINER:.spec.template.spec.containers[*].name,CPUREQ:.spec.template.spec.containers[*].resources.requests.cpu
#kube-system   aws-node     aws-node     5m
kubectl patch daemonset -n kube-system aws-node --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "5m"}
]'

#kube-system   kube-proxy   kube-proxy   2m
kubectl patch daemonset -n kube-system kube-proxy --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "2m"}
]'


#AWS CNI AddOn
kubectl get ds -n kube-system -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,CONTAINER:.spec.template.spec.containers[*].name,CPUREQ:.spec.template.spec.containers[*].resources.requests.cpu

#kube-system   aws-node     aws-node     5m
kubectl patch daemonset -n kube-system aws-node --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "5m"}
]'





### The Following should be reset after hours as there could be service disruption

----- NIGHT CHANGE -----
#itsma-pw118   itom-nginx-ingress-deployment         nginx-ingress-lb-front                                    20m
kubectl patch deploy -n $NS itom-nginx-ingress-deployment --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "20m"}
]'

#itsma-pw118   itom-sma-xie-deployment               itom-sma-xie-engine,kubernetes-vault-renew                20m,1m
kubectl patch deploy -n $NS itom-sma-xie-deployment --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "20m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'

#itsma-pw118   itom-xruntime-platform                kubernetes-vault-renew,itom-xruntime-platform             1m,50m
kubectl patch deploy -n $NS itom-xruntime-platform --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "50m"}
]'

#itsma-pw118   itom-xruntime-platform-offline        kubernetes-vault-renew,itom-xruntime-platform             1m,50m
kubectl patch deploy -n $NS itom-xruntime-platform-offline --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "50m"}
]'

#itsma-pw118   itom-xruntime-platform-offline-ng     itom-xruntime-platform,kubernetes-vault-renew             10m,1m
kubectl patch deploy -n $NS itom-xruntime-platform-offline-ng --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "10m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'

#itsma-pw118   itom-xruntime-platform-readonly       kubernetes-vault-renew,itom-xruntime-platform             1m,100m
kubectl patch deploy -n $NS itom-xruntime-platform-readonly --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "100m"}
]'



### Update EKS Addon's

kubectl get daemonset aws-node -n kube-system -o yaml > ~/aws-k8s-cni-old.yaml
kubectl apply -f https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/v1.19.0/config/master/aws-k8s-cni.yaml

