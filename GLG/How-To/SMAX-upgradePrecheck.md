1. Check Local Environment Executables
2. Check Images Repository for correct images
3. Check Application Component Versions

POST Upgrade Checks:
1. Check Alertmanager config
2. Check Promethues config
3. Check Prometheus metrics collected (Gitops Metrics)

---

## Check Local Environment Executables  
### AWS CLI  
```
aws --version
```
As of March 2024  
- AWS CLI version should be *2.15.27*  
- Python Version should be *3.11.8*  

### Kubernetes Client
```
kubectl version
```
As of March 2024:
- Kubernetes Client should be *v1.27*


   > - 1.19: curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.19.6/2021-01-05/bin/linux/amd64/kubectl
   > - 1.20: curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.20.15/2022-10-31/bin/linux/amd64/kubectl
   > - 1.21: curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.21.14/2023-01-11/bin/linux/amd64/kubectl
   > - 1.22: curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.22.17/2023-01-11/bin/linux/amd64/kubectl
   > - 1.23: curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.23.15/2023-01-11/bin/linux/amd64/kubectl
   > - 1.24: curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.24.9/2023-01-11/bin/linux/amd64/kubectl
   > - 1.24: curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.24.17/2023-09-14/bin/linux/amd64/kubectl
   > - 1.25: curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.25.13/2023-09-14/bin/linux/amd64/kubectl
   > - 1.26: curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.26.8/2023-09-14/bin/linux/amd64/kubectl
   > - 1.27: curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.27.5/2023-09-14/bin/linux/amd64/kubectl

 - Kubernetes Client for Rocky Linux
   > - Latest: curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   
- Helm Client
```
helm version
which helm
```

## Control Node binaries upgrade steps
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

---

# OpenText ITOM Cluster DNS records
#### Production
  | DNS Name                           | Purpose/Component                                  |
  | --                                 | --                                                 |
  | smax-west.gitops.com               | Primary Cluster FQDN                               |
  | smax-west-int.gitops.com           | Internal cross component integrations              |
  | smax-west-oo.gitops.com            | Operations Orchestration [OO]                      |
  | smax-west-cms.gitops.com           | Configuration Management System [CMS] - App Server |
  | smax-west-cms-gateway.gitops.com   | CMS Gateway for Native SACM                        |
  | smax-west-audit.gitops.com         | Audit Engine and Access Gateway                    |

#### Staging
  | DNS Name                           | Purpose/Component                                  |
  | --                                 | --                                                 |
  | qa.dev.gitops.com                  | Primary Cluster FQDN                               |
  | qa-int.dev.gitops.com              | Internal cross component integrations              |
  | qa-oo.dev.gitops.com               | Operations Orchestration [OO]                      |
  | qa-cms.dev.gitops.com              | Configuration Management System [CMS] - App Server |
  | qa-cms-gateway.dev.gitops.com      | CMS Gateway for Native SACM                        |
  | qa-audit.dev.gitops.com            | Audit Engine and Access Gateway                    |

#### Development
  | DNS Name                           | Purpose/Component                                  |
  | --                                 | --                                                 |
  | testing.dev.gitops.com             | Primary Cluster FQDN                               |
  | testing-int.dev.gitops.com         | Internal cross component integrations              |
  | testing-oo.dev.gitops.com          | Operations Orchestration [OO]                      |
  | testing-cms.dev.gitops.com         | Configuration Management System [CMS] - App Server |
  | testing-cms-gateway.dev.gitops.com | CMS Gateway for Native SACM                        |
  | testing-audit.dev.gitops.com       | Audit Engine and Access Gateway                    |

---

container - pod (ip address) - worker (ip address) - cluster | ingress - target group - listener - alb (FQDN)

ingress (CDF Install) - :3000 - ALB 1
ingress (Mgt Portal) - :5443 - ALB 1
ingress (SMAX) - :443 - ALB 1
ingress (OO) - :443 - ALB 2
ingress (INT-OO) - :2443 - ALB 3
ingress (INT-SMAX) - :4443 - ALB 3
