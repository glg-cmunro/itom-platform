# GreenLight Group - How To - Deploy OPTIC Cluster via Ansible  
# ![GreenLight Group Logo](https://assets.website-files.com/5ebcb9396faf10d8f7644479/5ed6a066891af295a039860f_GLGLogolrg-p-500.png)  

## Deployment Steps  
1. Create AWS Infrastructure  
2. Configure GreenLight User Access  
3. Deploy OMT / SMAX with silent install
3. Update Route53 for Bastion Host  
4. Clone GIT Repository for aws-smax  

---

## Create AWS Infrastructure  
<details><summary>Create AWS Infrastructure</summary>  

> Environment variables and prep  
*_Update the values below to represent the environment you want to build_*  
```
CLUSTER_FQDN=T800.dev.gitops.com
```
*_Set FQDN variable above, then copy/paste the following block.  Edit as needed_*  
```
cat << EOT > /opt/glg/itom-aws/ansible/vars/${CLUSTER_FQDN}$.yml
---
stack_prefix: testing
cluster_domain: dev.gitops.com

tags:
  Application: OPTIC Platform
  CostGroup:   GITOpS SaaS
  Customer:    GreenLight Group
  Environment: Testing

aws:
  region: us-east-1
  org_id: 713745958112
  vpc:
    cidr_prefix: '10.1'
  eks:
    version: 1.30
  eks_nodes:
    workers: 6
  rds:
    version: 15.10
    multi_az: "false"

global:
  suite_version: 24.2

EOT

vi /opt/glg/itom-aws/ansible/vars/${CLUSTER_FQDN}$.yml
```

> Run ansible playbook to build infrastructure  
```
startTime=`date`
echo "Start Infrastructure Build: ${startTime}" > ~/ansible-build.log
ansible-playbook /opt/glg/itom-aws/ansible/playbooks/v3.0.2/aws-infra-create-all.yml -e full_name=testing.dev.gitops.com
endTime=`date`
echo "End Infrastructure Build: ${endTime} >> ~/ansible-build.log"

```

</details>

## Configure GreenLight User Access  
<details><summary>Configure GreenLight User Access</summary>  

> Access to the cluster and cluster resources should be completed with the previous step  
> Login to the Control Node and verify access  
*_Perform the setups on a new Control Node to setup your AWS Environment_*  
If you are prompted for a sudo password the configuration of the Control Node is NOT complete
```
sudo mount

```
```
aws eks update-kubeconfig --name T800 --alias T800

kubectl get nodes

```
```
aws sts get-caller-identity

```
> If access is not available, re-run the 'Create All' playbook to complete access setup

> Add the Git repository for OPTIC to the Control Node
```
cd /opt/glg
git clone git@github.com:GreenLightGroup/aws-smax.git

```
</details>

## Deploy OMT / SMAX with silent install  
<details><summary>Deploy OMT / SMAX</summary>  

> Install Metrics Server
```
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

> Run ansible playbook to deploy OMT/SMAX using silent install
```
ansible-playbook /opt/glg/itom-aws/ansible/playbooks/v3.0.2/optic-deploy-omt.yml -e full_name=testing.dev.gitops.com -i ../../inventory/testing.dev.gitops.com
```
</details>

> Post OMT deploy: Setup bash profile
```
ansible-playbook /opt/glg/itom-aws/ansible/playbooks/v3.0.2/glg-config-bash-profile-by-role.yml -e full_name=T800.dev.gitops.com -i /opt/glg/itom-aws/ansible/inventory/T800.dev.gitops.com -e inv_host=controlNode-v302 -e role=control_node

```

998. Deploy AWS Load Balancer Controller add-on
```
CLUSTER_NAME=T800

```

- Create AWS IAM Policy
   ```
   curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.11.0/docs/install/iam_policy.json
   aws iam create-policy \
    --policy-name AmazonEKS-LBController-IAMPolicy-${CLUSTER_NAME} \
    --policy-document file://iam_policy.json \
    --profile automation

    ```

- Install EKSCTL
   ```
   ARCH=amd64
   PLATFORM=$(uname -s)_$ARCH
   curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
   curl -sL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_checksums.txt" | grep $PLATFORM | sha256sum --check
   tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz
   sudo mv /tmp/eksctl /usr/local/bin

   ```

- Associate OIDC Provider
   ```
   eksctl utils associate-iam-oidc-provider --cluster ${CLUSTER_NAME} --approve --profile automation

   #Check for association
   oidc_id=$(aws eks describe-cluster --name ${CLUSTER_NAME} --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
   aws iam list-open-id-connect-providers | grep $oidc_id | cut -d "/" -f4
   
   #Create Kubernetes Service Account
   eksctl create iamserviceaccount \
     --cluster=${CLUSTER_NAME} \
     --namespace=kube-system \
     --name=aws-load-balancer-controller \
     --role-name AmazonEKS-LBControllerRole-${CLUSTER_NAME} \
     --attach-policy-arn=arn:aws:iam::713745958112:policy/AmazonEKS-LBController-IAMPolicy-${CLUSTER_NAME} \
     --approve \
     --profile automation
   
   ```

- Helm deploy alb controller  
   ```
   /opt/cdf/bin/helm repo add eks https://aws.github.io/eks-charts
   /opt/cdf/bin/helm repo update eks
   /opt/cdf/bin/helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
     -n kube-system \
     --set clusterName=${CLUSTER_NAME} \
     --set serviceAccount.create=false \
     --set serviceAccount.name=aws-load-balancer-controller 
   
   ```

999. Deploy K8s managed ALB
 - Gather AWS details (Cert ARN, Security Groups, ...)
 - Create Ingress core:3000
 - Create Ingress core:5443
 - Create Ingress smax:443

```
VPC_CIDR=10.8.0.0/16
CLUSTER_NAME=T800
CLUSTER_FQDN=T800.dev.gitops.com
CSN=$(echo ${CLUSTER_FQDN} | awk -F. '{print $1}')
CERT_ARN=$(aws acm list-certificates --query "CertificateSummaryList[?DomainName=='*.dev.gitops.com'].CertificateArn" --output text)
CLUSTER_FQDN_INT=$(echo ${CLUSTER_FQDN} | sed "/$CSN/s//$CSN-int/")
NS=$(kubectl get ns | grep itsma | awk '{print $1}') && echo $NS

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
    alb.ingress.kubernetes.io/group.name: ${CLUSTER_NAME,,}-sma
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
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    alb.ingress.kubernetes.io/backend-protocol: HTTPS
    alb.ingress.kubernetes.io/certificate-arn: ${CERT_ARN}
    alb.ingress.kubernetes.io/group.name: ${CLUSTER_NAME,,}-int
    alb.ingress.kubernetes.io/healthcheck-path: /healthz
    alb.ingress.kubernetes.io/healthcheck-port: traffic-port
    alb.ingress.kubernetes.io/healthcheck-protocol: HTTPS
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS": 2443}]'
    alb.ingress.kubernetes.io/load-balancer-attributes: idle_timeout.timeout_seconds=180
    alb.ingress.kubernetes.io/scheme: internal
    alb.ingress.kubernetes.io/success-codes: 200-399
    alb.ingress.kubernetes.io/target-type: instance
  finalizers:
  - group.ingress.k8s.aws/${CLUSTER_NAME,,}-int
  labels:
    app: sma-integration-ingress
  name: sma-integration-ingress
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
    - ${CLUSTER_FQDN_INT,,}
EOT

```

 - Add/Update DNS entry in Route53 with new ALB
```
CLUSTER_FQDN=T800.dev.gitops.com
CSN=$(echo ${CLUSTER_FQDN} | awk -F. '{print $1}')
CLUSTER_FQDN_INT=$(echo ${CLUSTER_FQDN} | sed "/$CSN/s//$CSN-int/")
NS=$(kubectl get ns | grep itsma | awk '{print $1}') && echo ${NS}

HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name --query 'HostedZones[?Name==`dev.gitops.com.`].Id' --output text) && echo ${HOSTED_ZONE_ID}
ALB_NAME=$(kubectl get ing -n ${NS} sma-ingress -o json | /opt/cdf/bin/jq -r .status.loadBalancer.ingress[].hostname); echo ${ALB_NAME}
ALB_INT_NAME=$(kubectl get ing -n ${NS} sma-integration-ingress -o json | /opt/cdf/bin/jq -r .status.loadBalancer.ingress[].hostname) && echo ${ALB_INT_NAME}
ALB_QRY=LoadBalancers[?DNSName==\`${ALB_NAME}\`].CanonicalHostedZoneId
ALB_ZONE_ID=$(aws elbv2 describe-load-balancers --query ${ALB_QRY} --output text) && echo ${ALB_ZONE_ID}
ALB_INT_QRY=LoadBalancers[?DNSName==\`${ALB_INT_NAME}\`].CanonicalHostedZoneId
ALB_INT_ZONE_ID=$(aws elbv2 describe-load-balancers --query ${ALB_INT_QRY} --output text) && echo ${ALB_ZONE_ID}

CHANGE_BATCH="{\"Changes\": [{ \"Action\": \"UPSERT\", \"ResourceRecordSet\": {\"Name\": \"${CLUSTER_FQDN,,}\", \"Type\": \"A\", \"AliasTarget\": {\"HostedZoneId\": \"${ALB_ZONE_ID}\", \"DNSName\": \"${ALB_NAME}\", \"EvaluateTargetHealth\": false }}}]}"
aws route53 change-resource-record-sets \
  --hosted-zone-id ${HOSTED_ZONE_ID} \
  --change-batch "${CHANGE_BATCH}"

CHANGE_BATCH_INT="{\"Changes\": [{ \"Action\": \"UPSERT\", \"ResourceRecordSet\": {\"Name\": \"${CLUSTER_FQDN_INT,,}\", \"Type\": \"A\", \"AliasTarget\": {\"HostedZoneId\": \"${ALB_INT_ZONE_ID}\", \"DNSName\": \"${ALB_INT_NAME}\", \"EvaluateTargetHealth\": false }}}]}"
aws route53 change-resource-record-sets \
  --hosted-zone-id ${HOSTED_ZONE_ID} \
  --change-batch "${CHANGE_BATCH_INT}"

```


"""
- name: Use a routing policy to distribute traffic
  amazon.aws.route53:
    state: present
    zone: foo.com
    record: www.foo.com
    type: CNAME
    value: host1.foo.com
    ttl: 30
"""


#### Install/Configure Velero
```
CLUSTER_FQDN=T800.dev.gitops.com
BUCKET_NAME=t800.dev.gitops
BUCKET_REGION=us-east-1
aws s3api create-bucket \
    --bucket $BUCKET \
    --region $REGION
```

#### DEV1

BUCKET_NAME=t800.dev.gitops
BUCKET_REGION=us-east-1

aws s3api create-bucket --bucket ${BUCKET_NAME} --region ${BUCKET_REGION}

ECR_URL=$(kubectl get deploy -n core itom-idm -o json | jq -r .spec.template.spec.containers[0].image | awk -F/ '{print $1}') && echo $ECR_URL
export VELERO_NAMESPACE=velero
source $CDF_HOME/properties/images/charts.properties

kubectl create ns velero

helm install itom-velero $CDF_HOME/charts/$CHART_ITOM_VELERO -n ${VELERO_NAMESPACE} \
 --set fullnameOverride=velero \
 --set cleanupCRDs=true \
 --set upgradeCRDs=true \
 --set global.cluster.k8sProvider=aws \
 --set global.docker.imagePullSecret=registrypullsecret \
 --set global.docker.registry=${ECR_URL} \
 --set global.docker.orgName=hpeswitom \
 --set global.securityContext.user=1999 \
 --set global.securityContext.fsGroup=1999 \
 --set configuration.provider=aws \
 --set configuration.backupStorageLocation.bucket=${BUCKET_NAME} \
 --set configuration.backupStorageLocation.prefix=velero \
 --set configuration.backupStorageLocation.config.region=${BUCKET_REGION} \
 --set configuration.backupStorageLocation.config.serverSideEncryption=AES256 \
 --set configuration.volumeSnapshotLocation.config.region=${BUCKET_REGION} \
 --set cloudserver.deployment.enabled=false \

