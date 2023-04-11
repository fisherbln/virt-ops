provider "kubernetes" {
  host                   = "https://10.28.1.81:6443"
  client_certificate     = base64decode(data.sops_file.secrets.data["client_certificate"])
  client_key             = base64decode(data.sops_file.secrets.data["client_key"])
  cluster_ca_certificate = base64decode(data.sops_file.secrets.data["cluster_ca_certificate"])
}

#provider "nexus" {
#  alias    = "nas"
#  insecure = true
#  url      = "http://nexus.nickeson.net"
#  username = "admin"
#  password = var.nexus_password
#}
