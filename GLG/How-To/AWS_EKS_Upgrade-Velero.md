curl https://owncloud.gitops.com/index.php/s/ZUpvWDgiHE5jnos/download -o /tmp/velero-v1.13.0-linux-amd64.tar.gz

tar zxvf /tmp/velero-v1.13.0-linux-amd64.tar.gz -C /tmp/

sudo cp /tmp/velero-v1.13.0-linux-amd64/velero /usr/bin/

kubectl get deploy -n velero -ojson \
| sed "s#\"image\"\: \"velero\/velero\:v[0-9]*.[0-9]*.[0-9]\"#\"image\"\: \"velero\/velero\:v1.13.0\"#g" \
| sed "s#\"server\",#\"server\",\"--uploader-type=kopia\",#g" \
| sed "s#default-volumes-to-restic#default-volumes-to-fs-backup#g" \
| sed "s#default-restic-prune-frequency#default-repo-maintain-frequency#g" \
| sed "s#restic-timeout#fs-backup-timeout#g" \
| kubectl apply -f -

kubectl set image -n velero deployment/velero \
    velero=velero/velero:v1.13.0 \
    velero-plugin-for-aws=velero/velero-plugin-for-aws:v1.9.0
