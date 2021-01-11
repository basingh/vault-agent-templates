{{- with secret "test-intermediate-ca/issue/vault" "common_name=test" }}
{{ range $idx, $cert := .Data.ca_chain }}{{ $cert }}
{{ end }}
{{- end -}}
