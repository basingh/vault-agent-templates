This is a sample example to add fetch PKI secrets from Vault using vault agent. 
This particular example is an attempt use intermidiate CA and return full chain in response. 

1. Enable pki secret engine and tune it
```
vagrant@v1:~/pki$ vault secrets enable pki
vagrant@v1:~/pki$ vault secrets tune -max-lease-ttl=87600h pki
Success! Tuned the secrets engine at: pki/
```
2. Generate the root certificate and save the certificate in CA_cert.crt

```
vagrant@v1:~/pki$ vault write -field=certificate pki/root/generate/internal \
>         common_name="example.com" \
>         ttl=87600h > CA_cert.crt
```
3. Configure the CA and CRL URLs
```
vagrant@v1:~/pki$ vault write pki/config/urls \
>         issuing_certificates="http://127.0.0.1:8200/v1/pki/ca" \
>         crl_distribution_points="http://127.0.0.1:8200/v1/pki/crl"
Success! Data written to: pki/config/urls
```
4. Generate intemediate CA
```
vagrant@v1:~/pki$ vault secrets enable -path=pki_int pki
vagrant@v1:~/pki$ vault secrets tune -max-lease-ttl=43800h pki_int
Success! Tuned the secrets engine at: pki_int/
```
5.  generate an intermediate and save the CSR as `pki_intermediate.csr`
```
vagrant@v1:~/pki$ vault write -format=json pki_int/intermediate/generate/internal \
>         common_name="example.com Intermediate Authority" \
>         | jq -r '.data.csr' > pki_intermediate.csr
```
6. Sign the intermediate certificate with the root certificate and save the generated certificate as `intermediate.cert.pem`
```
vagrant@v1:~/pki$ vault write -format=json pki/root/sign-intermediate csr=@pki_intermediate.csr \
>         format=pem_bundle ttl="43800h" \
>         | jq -r '.data.certificate' > intermediate.cert.pem
```
7. ###### Now add both root pem and intermidiate pem together before setting `set-signed`. Something like 

```
vagrant@v1:~/pki$ cat appendcert.pem
-----BEGIN CERTIFICATE-----
MIIDNTCCAh2gAwIBAgIUNAowEYWIDfroGAcJg1dnhn6/MGEwDQYJKoZIhvcNAQEL
...............
QOyoeVHe9Zba
-----END CERTIFICATE-----,
-----BEGIN CERTIFICATE-----
MIIDpjCCAo6gAwIBAgIUIbuxOzwtRM4vT/p7jqGWQnu4vTcwDQYJKoZIhvcNAQEL
..............
6xQOlk0F6e897CVDKSxGTpcG+/BZAhVYOh4=
-----END CERTIFICATE-----

vagrant@v1:~/pki$ vault write pki_int/intermediate/set-signed certificate=@appendcert.pem
Success! Data written to: pki_int/intermediate/set-signed
```
8. Create a role 
```
vault write pki_int/roles/example-dot-com \
        allowed_domains="example.com" \
        allow_subdomains=true \
        max_ttl="720h"

```
9. Request certificate and it should generate cert with full `ca_chain` information
```
vagrant@v1:~/pki$ vault write pki_int/issue/example-dot-com common_name="test.example.com" ttl="24h"
Key                 Value
---                 -----
ca_chain            [-----BEGIN CERTIFICATE-----
MIIDpjCCAo6gAwIBAgIUIbuxOzwtRM4vT/p7jqGWQnu4vTcwDQYJKoZIhvcNAQEL
......
6xQOlk0F6e897CVDKSxGTpcG+/BZAhVYOh4=
-----END CERTIFICATE----- -----BEGIN CERTIFICATE-----
MIIDNTCCAh2gAwIBAgIUNAowEYWIDfroGAcJg1dnhn6/MGEwDQYJKoZIhvcNAQEL
......
QOyoeVHe9Zba
-----END CERTIFICATE-----]
certificate         -----BEGIN CERTIFICATE-----
MIIDZjCCAk6gAwIBAgIUYRr5g+HPM7ZoKGYsFApVVfpHQjAwDQYJKoZIhvcNAQEL
......
lgbruUPlJRqKEQ==
-----END CERTIFICATE-----
expiration          1610408502
issuing_ca          -----BEGIN CERTIFICATE-----
MIIDpjCCAo6gAwIBAgIUIbuxOzwtRM4vT/p7jqGWQnu4vTcwDQYJKoZIhvcNAQEL
....
6xQOlk0F6e897CVDKSxGTpcG+/BZAhVYOh4=
-----END CERTIFICATE-----
private_key         -----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEArDM8DYAKpD8LpgsFdq/Ealn7wZaqKpRvdm5aNz1N/5ipKOm9
.....
lh5A3lZuz4l22gI+SgQebqmTwpSgbNX6ooXS+BT6qoujbekoTumW
-----END RSA PRIVATE KEY-----
private_key_type    rsa
serial_number       61:1a:f9:83:e1:cf:33:b6:68:28:66:2c:14:0a:55:55:fa:47:42:30

```
 9. Lastly bring vault agent using config here:

 ```
 ## update value of agent file based on output you need, for example in array or string

 $ vault agent -config=vault-agent.hcl -log-level=trace
 ```