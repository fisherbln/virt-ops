cert creation for oidc: https://florianmuller.com/setup-authelia-bare-metal-with-openid-and-cloudflare-tunnel-on-a-hardened-proxmox-lxc-ubuntu-22-04-lts-container#configureauthelia

Create Authelia secrets

As you might not need all of the following keys and secrets, because you are not using all services, you can skip them. Just run the ones you need:

AUTHELIA_JWT_SECRET_FILE

tr -cd '[:alnum:]' < /dev/urandom | fold -w "64" | head -n 1 | tr -d '\n' > /etc/authelia/.secrets/jwtsecret

AUTHELIA_SESSION_SECRET_FILE

tr -cd '[:alnum:]' < /dev/urandom | fold -w "64" | head -n 1 | tr -d '\n' > /etc/authelia/.secrets/session

STORAGE_ENCRYPTION_KEY

tr -cd '[:alnum:]' < /dev/urandom | fold -w "64" | head -n 1 | tr -d '\n' > /etc/authelia/.secrets/storage

STORAGE_MYSQL_PASSWORD

tr -dc 'A-Za-z0-9!#$%&*#' </dev/urandom | head -c 64 | tr -d '\n' > /etc/authelia/.secrets/mysql

Important: The mysql password command is different. As we need the mysql password later to setup our database, it is important it is matching the requirements of also having special characters in there. Once generated read out and note the password somewhere save to use it later in this guide with:

cat /etc/authelia/.secrets/mysql

If you already have a mysql server and want to use that, add its password in here with:

nano /etc/authelia/.secrets/mysql

AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE

tr -cd '[:alnum:]' < /dev/urandom | fold -w "64" | head -n 1 | tr -d '\n' > /etc/authelia/.secrets/smtp

Important: If you already have a smtp password, you need to write it in this file plaintext and replace any existing characters in there:

nano /etc/authelia/.secrets/smtp

Or if you don't have a smtp provider yet, you may want to read out the previously generated password to use it in your smtp setup. For that just use:

cat /etc/authelia/.secrets/smtp

AUTHELIA_IDENTITY_PROVIDERS_OIDC_HMAC_SECRET

tr -cd '[:alnum:]' < /dev/urandom | fold -w "64" | head -n 1 | tr -d '\n' > /etc/authelia/.secrets/oidcsecret

AUTHELIA_IDENTITY_PROVIDERS_OIDC_ISSUER_PRIVATE_KEY_FILE

This generates the public and private key if you are going to use an OpenID Provider like cloudflare:

openssl genrsa -out /etc/authelia/.secrets/oicd.pem 4096

openssl rsa -in /etc/authelia/.secrets/oicd.pem -outform PEM -pubout -out /etc/authelia/.secrets/oicd.pub.pem

AUTHELIA_SESSION_REDIS_PASSWORD_FILE (optional)

tr -cd '[:alnum:]' < /dev/urandom | fold -w "64" | head -n 1 | tr -d '\n' > /etc/authelia/.secrets/redis