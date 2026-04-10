# SSL Certificate creation notes

![GreenLight Group Logo](https://assets.website-files.com/5ebcb9396faf10d8f7644479/5ed6a066891af295a039860f_GLGLogolrg-p-500.png)

---

### Pre-cursor: SSL Certificate chain
Root CA
    |__ Subordinate CA (Intermediate)
        |__ Server Certificate

If you trust the Root CA certificate server inturn you trust anything that was signed by the Root CA
By then trusting the Subordinate CA signed by the Root CA inturn you trust anything that was signed by the Subordinate CA as well

The Server Certificate is used as a way to identify the server providing content.
The Subordinate, and Root CA certificates are only used to establish trust in the server that is providing content. [^1]

It is possible to combine multiple certificates into a single file creating a full certificate chain.
Each certificate in the chain should be:
- PEM formated
- Begin with '--------------------- BEGIN CERTIFICATE -----------------------'
- End with   '--------------------- END CERTIFICATE -------------------------'
- Reverse order in the chain file starting with the Server Certificate, ending with the Root CA

Certificate Configuration File
: OpenSSL certificate configuration file providing details for what to put into the certificate



#### Retreive existing Private Key from PKCS12 Keystore (what NNM uses)
openssl pkcs12 -in certificate.p12 -nocerts -nodes -out private.key

openssl pkcs12 -in /var/opt/OV/shared/nnm/certificates/nnm-key.p12 -nocerts -nodes -out ~/nnm.key

openssl pkcs12 -export -out nnm-key.p12 -inkey nnm.key -in nnm.cer




### Setup PKI Infrastructure  
#### Create PKI directory structure
mkdir root issuing
cd root
mkdir -p private cert issued_certs crl csr data && chmod 0700 private
openssl rand -hex -out private/.rand 16 && chmod 0600 private/.rand
touch index.dat && openssl rand -hex -out serial.dat 8 && echo "1000" > crl_number && chmod 0600 ./*

cd ../issuing
mkdir -p private cert issued_certs crl csr data && chmod 0700 private
openssl rand -hex -out private/.rand 16 && chmod 0600 private/.rand
touch data/index.dat && echo "10000" > data/crl_number && openssl rand -out data/serial.dat -hex 8 && chmod 0600 data/*

#### Create Root CA Key/Cert  
> Setup root.cnf OpenSSL configuration file and directory structure
openssl ecparam -genkey -name secp521r1 | openssl ec -aes256 -out root/private/root.key && chmod 0400 root/private/root.key
openssl req -config root.cnf -key root/private/root.key -new -x509 -sha256 -extensions v3_ca -days 7300 -out root/cert/root.cer

#### Create Issuing CA Key/CSR/Cert
> Setup issuing.cnf OpenSSL configuration file and directory structure
openssl genrsa -aes256 -out issuing/private/issuing.key 2048
openssl req -config root.cnf -key issuing/private/issuing.key -new -sha256 -out issuing/csr/issuing.csr
openssl ca -config root.cnf -extensions v3_intermediate_ca -days 3650 -notext -md sha256 -in issuing/csr/issuing.csr -out issuing/cert/issuing.cer
cat issuing/cert/issuing.cer root/cert/root.cer > issuing/cert/cacert.cer
openssl verify -CAfile issuing/cert/cacert.cer issuing/cert/issuing.cer

#### Revoke a certificate signed by CA  
openssl ca -config issuing.cnf -revoke issuing/cert/server.cer

#### Generate CRL with revoked certificates
openssl ca -config issuing.cnf -gencrl -out issuing/crl/issuing.crl

#### Generate a new Key and Certificate Signing Request (CSR)
openssl req -newkey rsa:4096 -nodes -config ./tkk8s.conf -keyout tkk8s.key -out tkk8s.csr

#### Sign CSR using issuing CA
openssl ca -config issuing.cnf -in tkk8s.csr -out tkk8s.cer -extensions server_cert