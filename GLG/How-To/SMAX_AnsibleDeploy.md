#### Build Order
1. Create VPC (VPC, Subnets, Security Groups, IAM Roles, ...)
2. 

> Create AWS Infrastructure resources
```
ansible-playbook /opt/glg/itom-aws/ansible/playbooks/v3.0.2/aws-infra-create-all.yml -e full_name=T800.dev.gitops.com -v

```
> Run second time to complete config
```
ansible-playbook /opt/glg/itom-aws/ansible/playbooks/v3.0.2/aws-infra-create-all.yml -e full_name=T800.dev.gitops.com -v

```

> Login to the Control Node to git clone aws-smax repo
```
cd /opt/glg
git clone git@github.com:GreenLightGroup/aws-smax.git
git clone git@github.com:GreenLightGroup/itom-aws.git

```

> Deploy OMT and SMAX using silent install
```
ansible-playbook /opt/glg/itom-aws/ansible/playbooks/v3.0.2/optic-deploy-omt.yml -e full_name=T800.dev.gitops.com -v
ansible-playbook /opt/glg/itom-aws/ansible/playbooks/v3.0.2/optic-deploy-omt.yml -e full_name=testing.dev.gitops.com -v

```


998. Deploy AWS Load Balancer Controller add-on
export CLUSTER_NAME=T800

curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.11.0/docs/install/iam_policy.json
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy-${CLUSTER_NAME} \
    --policy-document file://iam_policy.json \
    --profile automation

#Install EKSCTL
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
curl -sL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_checksums.txt" | grep $PLATFORM | sha256sum --check
tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz
sudo mv /tmp/eksctl /usr/local/bin

###Per Cluster
##Associate OIDC Provider
eksctl utils associate-iam-oidc-provider --cluster ${CLUSTER_NAME} --approve --profile automation

#Check for association
oidc_id=$(aws eks describe-cluster --name ${CLUSTER_NAME} --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
aws iam list-open-id-connect-providers | grep $oidc_id | cut -d "/" -f4

#Create Kubernetes Service Account
eksctl create iamserviceaccount \
  --cluster=${CLUSTER_NAME} \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole-${CLUSTER_NAME} \
  --attach-policy-arn=arn:aws:iam::713745958112:policy/AWSLoadBalancerControllerIAMPolicy-${CLUSTER_NAME} \
  --approve \
  --profile automation

#Helm deploy alb controller
/opt/cdf/bin/helm repo add eks https://aws.github.io/eks-charts
/opt/cdf/bin/helm repo update eks
/opt/cdf/bin/helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=${CLUSTER_NAME} \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller 

999. Deploy K8s managed ALB
 - Gather AWS details (Cert ARN, Security Groups, ...)
 - Create Ingress core:3000
 - Create Ingress core:5443
 - Create Ingress smax:443

```
CERT_ARN=arn:aws:acm:us-east-1:713745958112:certificate/4210d4fc-eb24-458b-b2ee-4585f0597b25
VPC_CIDR=10.8.0.0/16
CLUSTER_NAME=T800
CLUSTER_FQDN=t800.dev.gitops.com
NS=itsma-hj3ym

cat << EOT | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    alb.ingress.kubernetes.io/backend-protocol: HTTPS
    alb.ingress.kubernetes.io/certificate-arn: ${CERT_ARN}
    alb.ingress.kubernetes.io/group.name: ${CLUSTER_NAME,,}-sma
    alb.ingress.kubernetes.io/healthcheck-path: /healthz
    alb.ingress.kubernetes.io/healthcheck-port: traffic-port
    alb.ingress.kubernetes.io/healthcheck-protocol: HTTPS
    alb.ingress.kubernetes.io/inbount-cidrs: ${VPC_CIDR},65.100.209.45/32,35.80.160.129/32
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS": 5443}]'
    alb.ingress.kubernetes.io/manage-backend-security-group-rules: "true"
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/security-groups: ""
    alb.ingress.kubernetes.io/success-codes: 200-399
    alb.ingress.kubernetes.io/target-type: instance
  finalizers:
    - group.ingress.k8s.aws/${CLUSTER_NAME,,}-sma
  labels:
    app: mng-nginx-ingress
  name: mng-ingress
  namespace: core
spec:
  ingressClassName: alb
  rules:
  - http:
      paths:
      - backend:
          service:
            name: portal-ingress-controller-svc
            port:
              number: 5443
        path: /*
        pathType: ImplementationSpecific
  tls:
  - hosts:
    - ${CLUSTER_FQDN,,}
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    alb.ingress.kubernetes.io/backend-protocol: HTTPS
    alb.ingress.kubernetes.io/certificate-arn: ${CERT_ARN}
    alb.ingress.kubernetes.io/group.name: ${CLUSTER_NAME,,}-sma
    alb.ingress.kubernetes.io/healthcheck-path: /
    alb.ingress.kubernetes.io/healthcheck-port: traffic-port
    alb.ingress.kubernetes.io/healthcheck-protocol: HTTPS
    alb.ingress.kubernetes.io/inbount-cidrs: ${VPC_CIDR},65.100.209.45/32,35.80.160.129/32
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS": 3000}]'
    alb.ingress.kubernetes.io/manage-backend-security-group-rules: "true"
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/security-groups: ""
    alb.ingress.kubernetes.io/success-codes: 200-399
    alb.ingress.kubernetes.io/target-type: instance
  finalizers:
  - group.ingress.k8s.aws/${CLUSTER_NAME,,}-sma
  labels:
    app: install-ingress
  name: install-ingress
  namespace: core
spec:
  ingressClassName: alb
  rules:
  - http:
      paths:
      - backend:
          service:
            name: frontend-ingress-controller-svc
            port:
              number: 3000
        path: /*
        pathType: ImplementationSpecific
  tls:
  - hosts:
    - ${CLUSTER_FQDN,,}
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    alb.ingress.kubernetes.io/backend-protocol: HTTPS
    alb.ingress.kubernetes.io/certificate-arn: ${CERT_ARN}
    alb.ingress.kubernetes.io/group.name: qa-sma
    alb.ingress.kubernetes.io/healthcheck-path: /healthz
    alb.ingress.kubernetes.io/healthcheck-port: traffic-port
    alb.ingress.kubernetes.io/healthcheck-protocol: HTTPS
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS": 443}]'
    alb.ingress.kubernetes.io/load-balancer-attributes: idle_timeout.timeout_seconds=180
    alb.ingress.kubernetes.io/manage-backend-security-group-rules: "true"
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/security-groups: ""
    alb.ingress.kubernetes.io/success-codes: 200-399
    alb.ingress.kubernetes.io/target-type: instance
  finalizers:
  - group.ingress.k8s.aws/${CLUSTER_NAME,,}-sma
  labels:
    app: sma-ingress
  name: sma-ingress
  namespace: ${NS}
spec:
  ingressClassName: alb
  rules:
  - http:
      paths:
      - backend:
          service:
            name: itom-nginx-ingress-svc
            port:
              number: 443
        path: /*
        pathType: ImplementationSpecific
  tls:
  - hosts:
    - ${CLUSTER_FQDN,,}
EOT

 - Add/Update DNS entry in Route53 with new ALB
