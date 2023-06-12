# SSL Certificate creation notes

![GreenLight Group Logo](https://assets.website-files.com/5ebcb9396faf10d8f7644479/5ed6a066891af295a039860f_GLGLogolrg-p-500.png)

---

### Pre-cursor: SSL Certificate chain
Root CA
    |__ Subordinate CA (Intermediate)
        |__ Server Certificate

If you trust the Root CA certificate server inturn you trust anything that was signed by the Root CA
With the Subordinate CA signed by the Root CA inturn you trust anything that was signed by the Subordinate CA as well

The Server Certificate is used as a way to identify the server providing content.
The Subordinate, and Root CA certificates are only used to establish trust in the server that is providing content. [^1]

It is possible to combine multiple certificates into a single file creating a full certificate chain.
Each certificate in the chain should be:
- PEM formated Base64 encoded string
- Begin with '--------------------- BEGIN CERTIFICATE -----------------------'
- End with   '--------------------- END CERTIFICATE -------------------------'
- Reverse order in the chain file starting with the Server Certificate, ending with the Root CA

Certificate Configuration File
: OpenSSL certificate configuration file providing details for what to put into the certificate