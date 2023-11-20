# GreenLight Docs - POC Tenant Deployment Guide
![GreenLight Group Logo](https://assets.website-files.com/5ebcb9396faf10d8f7644479/5ed6a066891af295a039860f_GLGLogolrg-p-500.png)

---

### Create a new Tenant in existing SMAX Deployment 
> This guide is written for deployment of a POC Tenant in an existing SMAX 2023.05 cluster
>> The following components must already be deployed and configured within the cluster
>> - Containerized OO - for Design and Deploy [DnD]
>> - Cost Governance and Resource Optimization [CGRO]
>> - Containerized CMS - for Native SACM

### REST API Calls to process each task
1. BO Auth
    - Auth Location
    - Token Request
    - Token URI
    - BO_AUTH_TOKEN
2. Create Customer
3. Create Account
4. Create Users
    - Tenant Admin
    - DnD Admin
    - DnD Integration
    - Bob the Agent
    - Sam the EndUser
5. Create Tenant
6. Create Licenses
    - License Pool
    - SMAX Premium License
    - Associate License with Pool
    - Attach License to Tenant
    - Cloud Management License
    - Associate License with Pool
    - Attach License to Tenant
7. 