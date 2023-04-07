resource "auth0_client" "default" {
  name = "Virtops"

  allowed_clients     = []
  allowed_logout_urls = []
  allowed_origins     = []
  callbacks = [
    "https://auth.nickeson.xyz/oauth2/callback",               # oauth2-proxy
    "https://grafana.nickeson.xyz/login/generic_oauth",        # Grafana
    "http://localhost:8000",                                # kubectl oidc-login
    "https://status.nickeson.xyz/authorization-code/callback", # Gatus
    "https://kubenav.io/auth/oidc.html",                    # Kubenav
    "https://gitops.nickeson.xyz/oauth2/callback",             # Weave-Gitops
  ]

  client_aliases       = []
  client_metadata      = {}
  cross_origin_auth    = false
  custom_login_page_on = true

  grant_types = [
    "authorization_code",
    "implicit",
    "refresh_token",
    "client_credentials",
  ]
  oidc_conformant = true

  sso = true

  jwt_configuration {
    alg                 = "RS256"
    lifetime_in_seconds = 36000
    scopes              = {}
    secret_encoded      = false
  }

  native_social_login {
    apple {
      enabled = false
    }

    facebook {
      enabled = false
    }
  }
}

resource "auth0_client" "miniflux" {
  name = "Miniflux"

  allowed_clients     = []
  allowed_logout_urls = []
  allowed_origins     = []
  callbacks = [
    "https://miniflux.nickeson.xyz/oauth2/oidc/callback"
  ]

  client_aliases       = []
  client_metadata      = {}
  cross_origin_auth    = false
  custom_login_page_on = true

  grant_types = [
    "authorization_code",
    "implicit",
    "refresh_token",
    "client_credentials",
  ]
  oidc_conformant = true

  sso = true

  jwt_configuration {
    alg                 = "RS256"
    lifetime_in_seconds = 36000
    scopes              = {}
    secret_encoded      = false
  }

  native_social_login {
    apple {
      enabled = false
    }

    facebook {
      enabled = false
    }
  }
}
