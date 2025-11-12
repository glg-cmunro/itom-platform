# ![GreenLight Group Logo](https://assets.website-files.com/5ebcb9396faf10d8f7644479/5ed6a066891af295a039860f_GLGLogolrg-p-500.png)
# GreenLight Group - How To - Prometheus setup on OPTIC Cluster

#Steps to deploy Prometheus monitoring for GITOpS SMAX cluster
1. Check the current state of monitoring in the cluster
2. 




### Prometheus Ingress for external access   
---  
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    ingress.kubernetes.io/backend-protocol: HTTPS
    ingress.kubernetes.io/force-ssl-redirect: "true"
    ingress.kubernetes.io/rewrite-target: /$2
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
            name: itom-prometheus-prometheus
            port:
              number: 9090
        path: /prometheus(/|$)(.*)
        pathType: Prefix
  tls:
  - secretName: nginx-default-secret
```
