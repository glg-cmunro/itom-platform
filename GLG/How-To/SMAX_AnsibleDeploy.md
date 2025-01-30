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

```

> Deploy OMT and SMAX using silent install
```
ansible-playbook /opt/glg/itom-aws/ansible/playbooks/v3.0.2/optic-deploy-omt.yml -e full_name=T800.dev.gitops.com -v

```


998. Deploy AWS Load Balancer Controller add-on
export cluster_name=qa
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.7/docs/install/iam_policy.json
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy-$cluster_name \
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
export cluster_name=qa
eksctl utils associate-iam-oidc-provider --cluster $cluster_name --approve --profile automation

#Check for association
oidc_id=$(aws eks describe-cluster --name $cluster_name --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
aws iam list-open-id-connect-providers | grep $oidc_id | cut -d "/" -f4

#Create Kubernetes Service Account
eksctl create iamserviceaccount \
  --cluster=$cluster_name \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::713745958112:policy/AWSLoadBalancerControllerIAMPolicy-qa \
  --approve \
  --profile automation

#Helm deploy alb controller
/opt/smax/2022.11/bin/helm repo add eks https://aws.github.io/eks-charts
/opt/smax/2022.11/bin/helm repo update eks
/opt/smax/2022.11/bin/helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$cluster_name \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller 

999. Deploy K8s managed ALB
 - Gather AWS details (Cert ARN, Security Groups, ...)
 - Create Ingress core:3000
 - Create Ingress core:5443
 - Create Ingress smax:443
 - Patch SVC frontend-ingress-controller-svc to NodePort
 - Patch SVC portal-ingress-controller-svc to NodePort
 - Patch SVC itom-nginx-ingress-svc to NodePort
