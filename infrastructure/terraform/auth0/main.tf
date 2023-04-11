terraform {
  cloud {
    organization = "Virtops"
    workspaces {
      name = "home-auth0-provisioner"
    }
  }

  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "0.45.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.2.1"
    }
  }
}

module "onepassword_item_auth0" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "Automation"
  item   = "auth0"
}

module "onepassword_item_mailgun" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "Services"
  item   = "mailgun"
}

module "virtops" {
  source = "./modules/virtops"

  secrets = {
    auth0_domain        = module.onepassword_item_auth0.fields.bjws_domain
    auth0_client_id     = module.onepassword_item_auth0.fields.terraform_client_id
    auth0_client_secret = module.onepassword_item_auth0.fields.terraform_client_secret
    users = {
      bernd = {
        email    = module.onepassword_item_auth0.fields.user_brian_email
        password = module.onepassword_item_auth0.fields.user_brian_password
      }
      manyie = {
        email    = module.onepassword_item_auth0.fields.user_sally_email
        password = module.onepassword_item_auth0.fields.user_sally_password
      }
    }
    mailgun = {
      api_key = module.onepassword_item_mailgun.fields.auth0_smtp_password
    }
  }
}
