Here is the workaround with updated steps which simplifies the process. You can use the code below and paste it into your terminal after you specified the release name and namespace at the top. You can also execute the commands one by one:

# please specify these two variables

release_name=optic

release_namespace=opsb-helm

 

# get the secret for the release manifest

secret_name=$(kubectl get secret -l owner=helm,status=deployed,name=$release_name --namespace $release_namespace | awk '{print $1}' | grep -v NAME)

# save the release manifest to a file

kubectl get secret $secret_name -n $release_namespace -o yaml > helm_release.yaml

# decode the helm release manifest

cat helm_release.yaml | grep -oP '(?<=release: ).*' | base64 -d | base64 -d | gzip -d > release_decoded

# replace the unsupported API version

sed -i 's/v1beta1/v1/g' release_decoded

# encode the release manifest again

cat release_decoded | gzip | base64 | base64 > release_encoded

# remove newline characters

echo -n $(tr -d "\n" < release_encoded) > release_encoded

# insert the encoded release into the release manifest

sed -i -f - helm_release.yaml << EOF 

s/release:.*/release: $(cat release_encoded)/g 

EOF

 

rm -f release_decoded release_encoded

 

# replace the secret with the new release manifest

kubectl replace -f helm_release.yaml -n $release_namespace
