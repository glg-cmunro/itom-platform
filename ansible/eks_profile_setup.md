# How to setup EKS Cluster Profile
 - Configure your AWS Profile
 - Assume Role with privleges to access Cluster
 - Set Environment Variables for the Session Created with Assume Role
 - AWS Call to create kube config (aws eks update-kubeconfig)
 - Unset Environment Variables used to create kube config
 
aws sts assume-role --role-arn arn:aws:iam::713745958112:role/GLG_DevAdmin --role-session-name GLG_DevAdmin
aws sts assume-role --role-arn arn:aws:iam::658787151672:role/GLG_ProdEngineer --role-session-name GLG_ProdEngineer

AWS_SESSION=`aws sts assume-role --role-arn arn:aws:iam::713745958112:role/GLG_DevAdmin --role-session-name GLG_DevAdmin`
AWS_ACCESS_KEY=`echo $AWS_SESSION | jq -r .Credentials.AccessKeyId`
AWS_ACCESS_SECRET=`echo $AWS_SESSION | jq -r .Credentials.SecretAccessKey`
AWS_SESSION_TOKEN=`echo $AWS_SESSION | jq -r .Credentials.SessionToken`
