{{- with secret "pki_int/issue/example-dot-com" "common_name=test.example.com" "format=pem_bundle"}}
{{ .Data.ca_chain }}
{{ end }}
