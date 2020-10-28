exit_after_auth = false
pid_file = "./pidfile"

auto_auth {
   method "approle" {
       mount_path = "auth/approle"
       config = {
           role_id_file_path = "/home/vagrant/roleid.txt"
           secret_id_file_path = "/home/vagrant/secretid.txt"
           remove_secret_id_file_after_reading = false
           #type = "iam"
           #role = "app-role"
       }
   }

   sink "file" {
       config = {
           path = "/home/vagrant/vault-token-via-agent"
       }
   }
}

cache {
   use_auto_auth_token = true
}

listener "tcp" {
   address = "10.100.2.11:8200"
   tls_disable = true
}

vault {
   address = "http://10.100.1.11:8200"
}

template {
  source      = "/home/vagrant/custom.tmpl"
  destination = "/home/vagrant/custom.txt"
}