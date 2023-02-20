1. Check local environment executables

 - AWS CLI Client version
   - `aws --version`

 - Kubernetes Client
   - `kubectl version`
   > - 1.19: curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.19.6/2021-01-05/bin/linux/amd64/kubectl
   > - 1.20: curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.20.15/2022-10-31/bin/linux/amd64/kubectl
   > - 1.21: curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.21.14/2023-01-11/bin/linux/amd64/kubectl
   > - 1.22: curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.22.17/2023-01-11/bin/linux/amd64/kubectl
   > - 1.23: curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.23.15/2023-01-11/bin/linux/amd64/kubectl
   > - 1.24: curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.24.9/2023-01-11/bin/linux/amd64/kubectl

 - Kubernetes Client for Rocky Linux
   > - Latest: curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   
 - Helm Client
   - `helm version`

# Control Node vinaries upgrade steps
1. AWS CLI
   ```
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
   ```
2. Kubernetes client (kubectl)
   - execute curl command for specific version from above
   - rename current kubectl before replacing
   ```
   oldVersion=121
   sudo cp /usr/bin/kubectl /usr/bin/kubectl$oldVersion
   ```
   - Add execute and move kubectl to system path
   ```
   chmod +x ./kubectl
   sudo mv ./kubectl /usr/bin/kubectl
   ```
3. ALL Engineers:  Update Kubernetes Cluster configuration
   ```
   ansible-playbook /opt/glg/aws-smax/ansible/playbooks/glg-config-aws-profile.yaml -e prod=true -e aws_role_name=GLG_ProdEngineer -e aws_mfa_code=<YOUR OTP CODE HERE>
   ```
   ```
   aws eks update-kubeconfig --name smax-west --profile GLG_ProdEngineer
   ```
   ```
   sed -i '/      env:/d' ~/.kube/config
   sed -i '/      - name: AWS_PROFILE/d' ~/.kube/config
   sed -i '/        value: GLG_ProdEngineer/d' ~/.kube/config
   ```


# MF ITOM Cluster DNS records
1. Cluster FQDN
  - recovery2.dev.gitops.com
2. OO External FQDN
  - recovery2-oo.dev.gitops.com
3. OO Integration - Internal
  - recovery2-int.dev.gitops.com
4. CMS Application Server
  - recovery2-cms.dev.gitops.com
5. CMS Gateway - Internal
  - recovery2-cms-gateway.dev.gitops.com


container - pod (ip address) - worker (ip address) - cluster | ingress - target group - listener - alb (FQDN)

ingress (CDF Install) - :3000 - ALB 1
ingress (Mgt Portal) - :5443 - ALB 1
ingress (SMAX) - :443 - ALB 1
ingress (OO) - :443 - ALB 2
ingress (INT-OO) - :2443 - ALB 3
ingress (INT-SMAX) - :4443 - ALB 3
