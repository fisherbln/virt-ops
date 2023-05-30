migrate to postgres for *arr apps

# 1. Read
# https://wiki.servarr.com/lidarr/postgres-setup
# https://wiki.servarr.com/prowlarr/postgres-setup
# https://wiki.servarr.com/radarr/postgres-setup

# 2. Create the Database
docker run --network=host \
  -e INIT_POSTGRES_HOST="<postgres-host-or-ip>" \
  -e INIT_POSTGRES_SUPER_PASS="<postgres-su-password>" \
  -e INIT_POSTGRES_USER="radarr" \
  -e INIT_POSTGRES_PASS="<app-db-password>" \
  -e INIT_POSTGRES_DBNAME="radarr_main radarr_log" \
  ghcr.io/onedr0p/postgres-init:14.8

# 3. Seed the database
# Make sure you use the version of the app you currently have installed
docker run --network=host \
  -e LIDARR__POSTGRES_HOST="<postgres-host-or-ip>" \
  -e LIDARR__POSTGRES_PORT="5432" \
  -e LIDARR__POSTGRES_USER="radarr" \
  -e LIDARR__POSTGRES_PASSWORD="<app-db-password>" \
  -e LIDARR__POSTGRES_MAIN_DB="radarr_main" \
  -e LIDARR__POSTGRES_LOG_DB="radarr_log" \
  ghcr.io/onedr0p/radarr-develop:1.2.0.3183

# 3a. Kill container after migrations have ran

# 4. Drop tables if needed as described in the docs above

# 5. Clone https://github.com/Roxedus/Pgloader-bin and build it with docker
# 5a. `docker build --progress=plain -t pgloader:latest .`

# 6. Go to the radarr UI and create a backup, download it and extract it.

# 7. Run the migration
docker run --network=host \
  -v $(pwd)/radarr.db:/radarr.db \
  pgloader:latest \
  --with "quote identifiers" \
  --with "data only" \
  --with "prefetch rows = 100" \
  --with "batch size = 1MB" \
  /radarr.db \
  "postgresql://radarr:<app-db-password>@<postgres-host-or-ip>/radarr_main"

# 8. Ignore any PL/pgSQL function errors
# 9. Update your secrets in cluster for the app (check step 3 for required vars)
# 10. Success?
