exit_after_auth = false
pid_file = "./pidfile"

auto_auth {
   method "approle" {
       mount_path = "auth/approle"
       config = {
           role_id_file_path = "/vagrant/ent/agent/config/role-id.txt"
           secret_id_file_path = "/vagrant/ent/agent/config/secret-id.txt"
           remove_secret_id_file_after_reading = false
           #type = "iam"
           #role = "app-role"
       }
   }

   sink "file" {
       config = {
           path = "/vagrant/ent/agent/config/vault-token-via-agent"
       }
   }
}

cache {
   use_auto_auth_token = true
}

listener "tcp" {
   address = "10.100.1.12:9200"
   tls_disable = true
}

vault {
   address = "http://10.100.1.11:8200"
}

template {
  source      = "/vagrant/ent/agent/config/custom_template.tpl"
  destination = "/vagrant/ent/agent/config/cachain.pem"
}
