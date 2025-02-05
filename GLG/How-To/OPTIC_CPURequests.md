kubectl describe nodes | grep cpu
  cpu                6625m (83%)        60010m (758%)
  cpu                5575m (70%)        29900m (378%)
  cpu                6360m (80%)        71020m (897%)
  cpu                6820m (86%)        65400m (826%)
  cpu                6015m (76%)        70490m (891%)
                    31395

  cpu                3865m (48%)        59310m (749%)
  cpu                3897m (49%)        28350m (358%)
  cpu                4176m (52%)        81670m (1032%)
  cpu                6350m (80%)        65900m (833%)
  cpu                4998m (63%)        69690m (881%)
                    23286

  cpu                5092m (64%)        91940m (1162%)
  cpu                5092m (64%)       113290m (1432%)
  cpu                3662m (46%)        110840m (1401%)
                    13846

kubectl get deploy -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,CONTAINER:.spec.template.spec.containers[*].name,CPUREQ:.spec.template.spec.containers[*].resources.requests.cpu
kubectl get daemonset -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,CONTAINER:.spec.template.spec.containers[*].name,CPUREQ:.spec.template.spec.containers[*].resources.requests.cpu

## SMAX (ITSMA Suite)
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
```
#itsma-pw118   itom-esm-api                          itom-esm-api,kubernetes-vault-renew                       5m,1m
kubectl patch deploy -n $NS itom-esm-api --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "5m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'

#itsma-pw118   itom-iac-controller                   kubernetes-vault-renew,itom-iac-controller                1m,5m
kubectl patch deploy -n $NS itom-iac-controller --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"}
]'

#itsma-pw118   itom-itsma-certificate-deployment     kubernetes-vault-renew,certificate                        1m,2m
kubectl patch deploy -n $NS itom-itsma-certificate-deployment --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "2m"}
]'

#itsma-pw118   itom-nginx-ingress-deployment         nginx-ingress-lb-front                                    20m
kubectl patch deploy -n $NS itom-nginx-ingress-deployment --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "20m"}
]'

#itsma-pw118   itom-scheduler                        scheduler,kubernetes-vault-renew                          10m,1m
kubectl patch deploy -n $NS itom-scheduler --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "10m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'

#itsma-pw118   itom-sma-ui-deployment                itom-sma-ui-deployment                                    1m
kubectl patch deploy -n $NS itom-sma-ui-deployment --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"}
]'

#itsma-pw118   itom-sma-xie-deployment               itom-sma-xie-engine,kubernetes-vault-renew                20m,1m
kubectl patch deploy -n $NS itom-sma-xie-deployment --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "20m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'

#itsma-pw118   itom-toolkit                          kubernetes-vault-renew,itom-toolkit                       1m
kubectl patch deploy -n $NS itom-toolkit --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'

#itsma-pw118   itom-xruntime-datahub                 kubernetes-vault-renew,itom-xruntime-datahub              1m,5m
kubectl patch deploy -n $NS itom-xruntime-datahub --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"}
]'

#itsma-pw118   itom-xruntime-gateway                 gateway,kubernetes-vault-renew                            15m,1m
kubectl patch deploy -n $NS itom-xruntime-gateway --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "15m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'

#itsma-pw118   itom-xruntime-mobile-gateway          kubernetes-vault-renew,mobile-gateway                     1m,2m
kubectl patch deploy -n $NS itom-xruntime-mobile-gateway --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "2m"}
]'

#itsma-pw118   itom-xruntime-opb-ui                  itom-xruntime-opb-ui                                      1m
kubectl patch deploy -n $NS itom-xruntime-opb-ui --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"}
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

#itsma-pw118   itom-xruntime-ppo                     kubernetes-vault-renew,ppo                                1m,1m
kubectl patch deploy -n $NS itom-xruntime-ppo --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'

#itsma-pw118   itom-xruntime-redis                   kubernetes-vault-renew,itom-xruntime-redis                1m,10m
kubectl patch deploy -n $NS itom-xruntime-redis --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "10m"}
]'

#itsma-pw118   itom-xruntime-serviceportal           kubernetes-vault-renew,itom-xruntime-serviceportal        1m,5m
kubectl patch deploy -n $NS itom-xruntime-serviceportal --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"}
]'

#itsma-pw118   itom-xruntime-ui                      itom-xruntime-ui                                          5m
kubectl patch deploy -n $NS itom-xruntime-ui --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "5m"}
]'

#itsma-pw118   itom-xruntime-websocket-gateway       kubernetes-vault-renew,itom-sma-wsgateway                 1m,5m
kubectl patch deploy -n $NS itom-xruntime-websocket-gateway --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"}
]'

#itsma-pw118   itom-xruntime-xmpp                    xmpp,xmpp-auth,kubernetes-vault-renew                     2m,5m,1m
kubectl patch deploy -n $NS itom-xruntime-xmpp --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "2m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"},
  {"op": "replace", "path": "/spec/template/spec/containers/2/resources/requests/cpu", "value": "1m"}
]'

##itsma-pw118   sam-backend-deployment                kubernetes-vault-renew,sam-service                        5m,50m
#kubectl patch deploy -n $NS sam-backend-deployment --type='json' -p='[
#  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "5m"},
#  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "50m"}
#]'
#
##itsma-pw118   sam-ui-deployment                     sam-ui,kubernetes-vault-renew                             10m,5m
#kubectl patch deploy -n $NS sam-ui-deployment --type='json' -p='[
#  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "10m"},
#  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"}
#]'

#itsma-pw118   smarta-admin-ui-backend               smarta-admin-ui-backend                                   1m
kubectl patch deploy -n $NS smarta-admin-ui-backend --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"}
]'

#itsma-pw118   smarta-data-source                    smarta-data-source,kubernetes-vault-renew                 5m,1m
kubectl patch deploy -n $NS smarta-data-source --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "5m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'

#itsma-pw118   smarta-installer                      suite-config,kubernetes-vault-renew                       5m,1m
kubectl patch deploy -n $NS smarta-installer --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "5m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'

#itsma-pw118   smarta-ocr                            kubernetes-vault-renew,smarta-ocr                         1m,5m
kubectl patch deploy -n $NS smarta-ocr --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"}
]'

#itsma-pw118   smarta-saw-dih                        smarta-saw-dih,kubernetes-vault-renew                     2m,1m
kubectl patch deploy -n $NS smarta-saw-dih --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "2m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'

#itsma-pw118   smarta-saw-proxy                      smarta-saw-proxy                                          1m
kubectl patch deploy -n $NS smarta-saw-proxy --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"}
]'

#itsma-pw118   smarta-sawarc-dih                     smarta-sawarc-dih,kubernetes-vault-renew                  2m,1m
kubectl patch deploy -n $NS smarta-sawarc-dih --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "2m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'

#itsma-pw118   smarta-sawmeta-dih                    smarta-sawmeta-dih,kubernetes-vault-renew                 1m,1m
kubectl patch deploy -n $NS smarta-sawmeta-dih --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'

#itsma-pw118   smarta-search                         kubernetes-vault-renew,smarta-search                      1m,2m
kubectl patch deploy -n $NS smarta-search --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "2m"}
]'

#itsma-pw118   smarta-smart-ticket                   kubernetes-vault-renew,smarta-smart-ticket                1m,5m
kubectl patch deploy -n $NS smarta-smart-ticket --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"}
]'

#itsma-pw118   smarta-smart-ticket-admin-ui          smarta-smart-ticket-admin-ui                              1m
kubectl patch deploy -n $NS smarta-smart-ticket-admin-ui --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"}
]'

#itsma-pw118   smarta-smart-ticket-task              kubernetes-vault-renew,smarta-smart-ticket-task           1m,5m
kubectl patch deploy -n $NS smarta-smart-ticket-task --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"}
]'

#itsma-pw118   smarta-stx-agent                      kubernetes-vault-renew,smarta-stx-agent                   1m,1m
kubectl patch deploy -n $NS smarta-stx-agent --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "11m"}
]'

#itsma-pw118   smarta-stx-category                   smarta-stx-category,kubernetes-vault-renew                1m,1m
kubectl patch deploy -n $NS smarta-stx-category --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'

#itsma-pw118   smarta-stx-media                      smarta-stx-media,kubernetes-vault-renew                   10m,1m
kubectl patch deploy -n $NS smarta-stx-media --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "10m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'

#itsma-pw118   virtual-agent-admin-ui                kubernetes-vault-renew,virtual-agent-admin-ui,gateway     1m,2m,1m
kubectl patch deploy -n $NS virtual-agent-admin-ui --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "2m"},
  {"op": "replace", "path": "/spec/template/spec/containers/2/resources/requests/cpu", "value": "1m"}
]'

#itsma-pw118   virtual-agent-bot-engine              virtual-agent-bot-engine,gateway,kubernetes-vault-renew   2m,1m,1m
kubectl patch deploy -n $NS virtual-agent-bot-engine --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "2m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/2/resources/requests/cpu", "value": "1m"}
]'

#itsma-pw118   virtual-agent-nlu                     gateway,kubernetes-vault-renew,virtual-agent-nlu          1m,1m,1m
kubectl patch deploy -n $NS virtual-agent-nlu --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/2/resources/requests/cpu", "value": "1m"}
]'


## Containerized OO
#oo            itom-autopass-lms                     vault-renew,itom-autopass-lms                             1m,50m
kubectl patch deploy -n oo itom-autopass-lms --type='json' --patch='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "50m"}
]'

#oo            itom-oocentral                        vault-renew,itom-oocentral                                1m,200m
kubectl patch deploy -n oo itom-oocentral --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "200m"}
]'

#oo            itom-oocontroller                     vault-renew,itom-oocontroller                             1m,500m
kubectl patch deploy -n oo itom-oocontroller --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "500m"}
]'

#oo            itom-oodownloader                     vault-renew,itom-oodownloader                             1m,500m
kubectl patch deploy -n oo itom-oodownloader --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "500m"}
]'

#oo            itom-ooscheduler                      vault-renew,itom-ooscheduler                              1m,500m
kubectl patch deploy -n oo itom-ooscheduler --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "500m"}
]'

#oo            itom-oosession-manager                vault-renew,itom-oosession-manager                        1m,100m
kubectl patch deploy -n oo itom-oosession-manager --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "100m"}
]'

#oo            itom-vault                            vault                                                     100m
kubectl patch deploy -n oo itom-vault --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "100m"}
]'

#oo            oo-itom-ingress-controller            nginx-ingress-lb,vault-renew,stunnel                      10m,1m,1m
kubectl patch deploy -n oo oo-itom-ingress-controller --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "10m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/2/resources/requests/cpu", "value": "1m"}
]'

##Velero - Cluster Backup
#velero        velero                                velero                                                    50m
kubectl patch deploy -n velero velero --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "50m"}
]'

## OMT and related 'core'
#core          apphub-apiserver                      apphub-apiserver,vault-renew                              5m,1m
kubectl patch deploy -n core apphub-apiserver --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"}
]'

#core          apphub-ui                             apphub-ui,vault-renew                                     5m,1m
kubectl patch deploy -n core apphub-ui --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "5m"}
]'

#core          cdf-apiserver                         cdf-apiserver,vault-renew                                 1m,1m
kubectl patch deploy -n core cdf-apiserver --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'

#core          frontend-ingress-controller           nginx-ingress-lb,vault-renew                              10m,1m
kubectl patch deploy -n core frontend-ingress-controller --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "10m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'

#core          itom-frontend-ui                      suite-installer-frontend,vault-renew                      5m,1m
kubectl patch deploy -n core itom-frontend-ui --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "5m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'

#core          itom-idm                              idm,vault-renew                                           5m,1m
kubectl patch deploy -n core itom-idm --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "5m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'

#core          itom-kube-dashboard                   dashboard,vault-renew                                     1m,1m
kubectl patch deploy -n core itom-kube-dashboard --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'

#core          itom-kube-dashboard-metrics-scraper   dashboard-metrics-scraper                                 1m
kubectl patch deploy -n core itom-kube-dashboard-metrics-scraper --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"}
]'

#core          itom-mng-portal                       mng-portal,vault-renew                                    2m,1m
kubectl patch deploy -n core itom-mng-portal --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "2m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'

#core          itom-prometheus-grafana               vault-renew,grafana-sc-dashboard,grafana                  1m,1m,5m
kubectl patch deploy -n core itom-prometheus-grafana --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/2/resources/requests/cpu", "value": "5m"}
]'

#core          itom-prometheus-kube-state-metrics    vault-renew,stunnel,kube-state-metrics                    1m,1m,2m
kubectl patch deploy -n core itom-prometheus-kube-state-metrics --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/2/resources/requests/cpu", "value": "2m"}
]'

#core          itom-prometheus-operator              vault-renew,prometheus                                    1m,1m
kubectl patch deploy -n core itom-prometheus-operator --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'

#core          itom-reloader                         itom-reloader                                             5m
kubectl patch deploy -n core itom-reloader --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "5m"}
]'

#core          itom-vault                            vault                                                     100m
kubectl patch deploy -n core itom-vault --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "100m"}
]'

#core          portal-ingress-controller             nginx-ingress-lb,vault-renew                              10m,1m
kubectl patch deploy -n core portal-ingress-controller --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "10m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'

#core          suite-conf-pod-itsma                  suite-config,kubernetes-vault-renew                       15m,1m
kubectl patch deploy -n core suite-conf-pod-itsma --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "15m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'

#SMAX          itom-throttling-controller            kubernetes-vault-renew,throttling-controller              1m,1m
kubectl patch daemonset -n $NS itom-throttling-controller --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'

###Prometheus in OMT
###kubectl get prometheuses -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,CONTAINER:.spec.containers[*].name,CPUREQ:.spec.containers[*].resources.requests.cpu,PROMREQ:.spec.resources.requests.cpu
kubectl patch prometheuses -n core itom-prometheus-prometheus --type='json' -p='[
  {"op": "replace", "path": "/spec/resources/requests/cpu", "value": "75m"},
  {"op": "replace", "path": "/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/containers/1/resources/requests/cpu", "value": "1m"}
]'

## Audit Controller
#audit         audit-itom-ingress-controller         nginx-ingress-lb,vault-renew,stunnel                      5m,1m,2m
kubectl patch deploy -n audit audit-itom-ingress-controller --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "5m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/2/resources/requests/cpu", "value": "2m"}
]'

#audit         itom-audit-deployment                 kubernetes-vault-renew,itom-audit-deployment              1m,50m
kubectl patch deploy -n audit itom-audit-deployment --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "50m"}
]'

#audit         itom-audit-gateway-deployment         kubernetes-vault-renew,itom-audit-gateway                 1m,20m
kubectl patch deploy -n audit itom-audit-gateway-deployment --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "1m"},
  {"op": "replace", "path": "/spec/template/spec/containers/1/resources/requests/cpu", "value": "20m"}
]'

#audit         itom-vault                            vault                                                     100m
kubectl patch deploy -n audit itom-vault --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "100m"}
]'

## K8s Cluster environment 'kube-system'
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

