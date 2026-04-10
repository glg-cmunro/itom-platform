# AWS_EKS - Upgrade aws-node / kube-proxy


aws eks describe-addon --cluster-name my-cluster --addon-name vpc-cni --query addon.addonVersion --output text	#Should not return anything for self-managed

kubectl set image deployment.apps/coredns -n kube-system  coredns=602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/coredns:v1.11.3-eksbuild.1

kubectl set image daemonset.apps/kube-proxy -n kube-system kube-proxy=602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/kube-proxy:v1.32.6-minimal-eksbuild.8

kubectl describe deployment coredns -n kube-system | grep Image; \
kubectl describe ds kube-proxy -n kube-system | grep Image; \
kubectl describe ds aws-node -n kube-system | grep Image

kubectl get daemonset aws-node -n kube-system -o yaml > aws-k8s-cni-old.yaml
curl -O https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/v1.20.2/config/master/aws-k8s-cni.yaml

cat aws-k8s-cni.yaml

kubectl apply -f aws-k8s-cni.yaml
