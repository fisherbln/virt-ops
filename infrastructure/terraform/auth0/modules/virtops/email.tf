resource "auth0_email" "mailgun_provider" {
  name    = "mailgun"
  enabled = true

  default_from_address = "nickeson authentication <noreply@nickeson.xyz>"

  credentials {
    domain    = "mg.nickeson.xzy"
    region    = "eu"
    smtp_port = 0
    api_key   = var.secrets["mailgun"]["api_key"]
  }
}
