Playbook to stage SMAX Upgrade
- Create Directory for SMAX binaries
- Pull Binaries from OwnCloud
    OMT BYOK
    SMA toolkit
    OO Helm chart
    
- Extract files as needed
    OMT BYOK

- Setup image-set.json
    OMT
    SMAX
    OO
    CGRO
    DND
    

ECR_PASS=$(aws ecr get-login-token)
/opt/smax/2021.11/install --k8s-provider aws \
 --config /opt/smax/2021.11/smax_silent_config_2021_11.json \
 --registry-orgname hpeswitom \
 --registry-url 713745958112.dkr.ecr.us-east-1.amazonaws.com \
 --registry-password ${ECR_PASS} \
 --registry-username AWS \
 --skip-warning -t 200 \
 --metadata /opt/smax/2021.11/itsma-suite-metadata-2021.11-b27.tgz \
 --external-access-host testing.dev.gitops.com \
 -P Gr33nl1ght_ \
 --nfs-server fs-092958bb9253c9b2a.efs.us-east-1.amazonaws.com \
 --nfs-folder /var/vols/itom/itsma/core \
 --db-user cdfapiserver \
 --db-password Gr33nl1ght_ \
 --db-url jdbc:postgresql://testingrds.c9y7wv2ugz7q.us-east-1.rds.amazonaws.com:5432/cdfapiserverdb

/opt/smax/2022.11/install --config /opt/smax/2022.11/smax_silent_config_2022_11.json --k8s-provider aws --registry-orgname hpeswitom --registry-url 713745958112.dkr.ecr.us-east-1.amazonaws.com --registry-password eyJwYXlsb2FkIjoick5QWCtyTmgrMFZ3QlFMb28wMEZCYzFHdlBKUFpQaTlhQndyU1oxc2ZLU29SVnAwcGdFOHFBVWtjNUdEUUhzL3FPbjE0NHZKSzhiR2RvM3FZbHJKSFFlZjFMN1I3STRpN3AwTW1MS210ZDhPeTVGY1BCaTJUYUZZQks2aVJZVy9xVm1DOXNCSDZQOUUzWkNIYm4rNGdsa3drYkNZN0lnZ1p6UzFTeEd4eUcrWHovcmJKS2VUa2Q0ei9Pa1U0RGJaOFJxU1BWM2JRY2VPbjR0Z3pVS09oSlRjSml5NWhCS3hZSXhXd2g2MHQ4Rkd6dFJ2K28rbDIwTUFOYU9ndURvaU5nZk9oOS94cEVPdjhDQm83dHVSUHZoYTd6bXAwTXlzemhnaVlUU1hUYWlnZ05NZDJ4VlJ6c3pVRXRqMC9xbEV4MWFVZzdtUmdtdDhyeGhWcUh3NXFVQUNldnZxL0xVTXBObHB6Rk5iWDc5TnVmV2tJKzRFUkJtdHVWb0RRcDhSQ1BHL1RlRGVYWFlqdVg5Yi9ET3hJU1d5UG50Q04rTVJyK0ZhaU9TaUw5dkJxeFczSFBJUlZSb0ozTFIyMUNFOGZXNnFGRlZxdGFjc2FUUHFsOWhqV0l4Q3VXMmFMRm1valNLSHZtak9aTEMrTHk3MzR2L1Jac0VVdHBqMHhGaGZzMHBwWnJ0UWRoeCtFeFYrSnExVXRVc08rQkQrMkloQTVheFNaWXgrQlVHKzljOXZuWnNSUGNDRmNYSUFLSWNyVE43Ymh3aWtMbElWUzY4aDhnOThocS9CakZxUzd5R2doeWk5cHlCQlNuTWFyUjJVdDh6SUMydUsxY0FjSzE3MHRKcnduRGhTZlZVQ1FtWlYxQ2l6bTBybG9QT0dobGFPd1ByL2hmYkdXSXpRazRyNStyS2RTV2dnL3JNbjlISFpVVnpuSGU1ZWZLdjRMRGZadnFRd2JKQ3JzRUNPL3A0aXVrQnlldUVnclJ2OFFlKzQ3cm01alZhVm9FOTI1a0lZenN5UWxJcGNYRzcyUlJpSjBHbktPQ1lsOXd5SFducU4vZmc5K2pjc01SWk4xanMxTEdyYXZoQzhFNGp4UmxuVDY1bG9LL000WTV2RFpHTkZOdDFjd2xjaW10SXA1VUhtYVZDZ2JrZEMwWkpoYnhQK1BrNkFCWkNnSCs2aC9GK2lUTXVGSWdRc0cxYTNEY2kvVDRRRVV5aGliRzQ3QnBybFFOY3I5T2NEQ3VwbXY2QXMvMHdhZlB1T1hhMys5L0pZSXFvSFdyc0l0aWpjelI4SG5kOXc2Qy92RkJlNlp5R09TTGZnNkxCOXR3TXVENHhuVkVPdXhYZEc1dktpeXlkS20wRm9ha2RiK3liMGZuY2hwZzJ2ZHJqbVpHdmIwQTRnckE9PSIsImRhdGFrZXkiOiJBUUVCQUhod20wWWFJU0plUnRKbTVuMUc2dXFlZWtYdW9YWFBlNVVGY2U5UnE4LzE0d0FBQUg0d2ZBWUpLb1pJaHZjTkFRY0dvRzh3YlFJQkFEQm9CZ2txaGtpRzl3MEJCd0V3SGdZSllJWklBV1VEQkFFdU1CRUVER0xVcnpJVzQvQ3p6aUxjZXdJQkVJQTdXWjVYT3Y1UlZWZ1BtVHUrbjlYUkdhTU5ISDlGLzNybStoYW5ZSHpVWXpuZmF1V1U2WkY2a1RUdkQyaXNJUjN1d1k5aVdNb2JLOHZCWVJrPSIsInZlcnNpb24iOiIyIiwidHlwZSI6IkRBVEFfS0VZIiwiZXhwaXJhdGlvbiI6MTY4Mzk1NDA3MX0= --registry-username AWS --skip-warning -t 200 --metadata /opt/smax/2022.11/itsma-suite-metadata-2022.11-b46.tgz --external-access-host testing.dev.gitops.com -P Gr33nl1ght_ --nfs-server fs-0a796224849d02d2b.efs.us-east-1.amazonaws.com --nfs-folder /var/vols/itom/itsma/core --db-user cdfapiserver --db-password Gr33nl1ght_ --db-url jdbc:postgresql://testingrds.c9y7wv2ugz7q.us-east-1.rds.amazonaws.com:5432/cdfapiserverdb



New Tenant PoC Steps:

Add roles to user(s) - Administration->People
Create KeyChain - Administration->ApplicationSettings
Enable CGRO - Administration->ApplicationSettings
Enable Aggregation - Administration->ApplicationSettings
Enable OO RAS Download - Administration->Integrations
