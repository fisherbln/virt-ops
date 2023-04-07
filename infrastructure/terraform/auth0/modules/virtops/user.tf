resource "auth0_user" "brian" {
  connection_name = auth0_connection.username_password_authentication.name

  name     = var.secrets["users"]["brian"]["email"]
  nickname = "brian"
  email    = var.secrets["users"]["brian"]["email"]
  password = var.secrets["users"]["brian"]["password"]

  roles = [
    auth0_role.admins.id,
    auth0_role.k8s_admin.id,
    auth0_role.grafana_admin.id,
    auth0_role.calibre_web.id,
    auth0_role.paperless.id,
    auth0_role.miniflux.id,
  ]

  blocked        = false
  email_verified = true
  picture        = "https://s.gravatar.com/avatar/0e840c4607e58c510774bcf301b5b534?s=480&r=pg&d=https%3A%2F%2Fcdn.auth0.com%2Favatars%2Fbe.png"
}

resource "auth0_user" "sally" {
  connection_name = auth0_connection.username_password_authentication.name

  name     = var.secrets["users"]["sally"]["email"]
  nickname = "sally"
  email    = var.secrets["users"]["sally"]["email"]
  password = var.secrets["users"]["sally"]["password"]

  roles = [
    auth0_role.calibre_web.id,
    auth0_role.paperless.id,
  ]

  blocked        = false
  email_verified = true
  picture        = "https://s.gravatar.com/avatar/0e840c4607e58c510774bcf301b5b534?s=480&r=pg&d=https%3A%2F%2Fcdn.auth0.com%2Favatars%2Fmf.png"
}
