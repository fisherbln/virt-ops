restore procedure: 

https://thedatabaseme.de/2022/05/03/restore-and-clone-from-s3-configure-zalando-postgres-operator-restore-with-wal-g/

In an earlier blogpost, I wrote about doing Postgres backups using WAL-G to a S3 storage. This time we have a look to either clone or “inplace” restore a postgres instance from these backups. All of this using the Zalando Postgres Operator. If you haven’t done so, please read the backup post before proceeding reading this one.

There are several scenarios doing clones from an earlier or already running Postgres instance using the Zalando Postgres Operator. They are documented here. We have a deeper look on two of these scenarios, both of them involving using WAL-G backups. Only for the records, you can clone a running Postgres Instance using the same manifest syntax we use down below in the same namespace as a running Postgres cluster. This will lead to a clone using pg_basebackup directly from the existing cluster and not using your S3 backups.

One general prerequisite for creating clones using WAL-G is to specify the S3 bucket configuration for cloning. We did for the backup in the above named blog post, but it has to be done as well for cloning. This is done by adding the same environment variables you have specified for backup but with a CLONE_ prefix. I did so by having a pod-config configmap, where all variables will be added to all Postgres clusters which are managed by the Zalando Operator (see here). You can also specify all those settings in the postgresql CRD, if you do so, here is the list of variables you probably need to set in order to get the cloning to work:

YAML
  CLONE_USE_WALG_RESTORE: "true"
  CLONE_AWS_ACCESS_KEY_ID: postgresql
  CLONE_AWS_SECRET_ACCESS_KEY: supersecret
  CLONE_AWS_ENDPOINT: http://minio.home.lab:9000 # Endpoint URL to your S3 Endpoint; MinIO in this example
  CLONE_AWS_REGION: de01
  CLONE_METHOD: CLONE_WITH_WALE
  CLONE_WAL_BUCKET_SCOPE_PREFIX: ""
  CLONE_WAL_S3_BUCKET: postgresql
  CLONE_AWS_S3_FORCE_PATH_STYLE: "true"
Inplace restore

When speaking of an inplace restore, we mean restoring a Postgres instance to an earlier point in time and keeping the instance name the same. You cannot overwrite a running cluster, so you first need to delete it and then (re)create it newly with the clone configuration down below. You can change some of the configurations also during an inplace restore, but I would advice you not to do so. It’s already a “risky” process. So if you’re unsure about the specific point in time or you want to try it out without deleting the actual instance, use the clone restore method described in the next chapter.

Let’s assume we’ve created a Postgres cluster with the name postgres-demo-cluster with the following definition (you can also find the manifest in my Github repository)

demo-cluster.yaml
apiVersion: "acid.zalan.do/v1"
kind: postgresql
metadata:
  name: postgres-demo-clustere
  namespace: postgres
spec:
  teamId: "postgres"
  volume:
    size: 2Gi
  numberOfInstances: 2
  users:
    demouser:  # database owner
    - superuser
    - createdb
  databases:
    demo: demo_owner  # dbname: owner
  preparedDatabases:
    demo: {}
  postgresql:
    version: "14"
Ensure, that you have a valid full backup and recent WAL archives in your S3 bucket, which cover the point in time you want to restore the instance to. Then delete the cluster from your Kubernetes environment.

kubectl delete postgresqls -n postgres postgres-demo-cluster
postgresql.acid.zalan.do "postgres-demo-cluster" deleted
Let’s wait for the cluster to get removed, if you check the S3 bucket again, you will find out, that a recent WAL archive is getting created during the shutdown / termination of the instance.

So now let’s update the CRD manifest and add a clone section to it (again, you can find the manifest also here).

demo-cluster-inplace-restore.yaml
apiVersion: "acid.zalan.do/v1"
kind: postgresql
metadata:
  name: postgres-demo-cluster
  namespace: postgres
spec:
  teamId: "postgres"
  volume:
    size: 2Gi
  numberOfInstances: 2
  users:
    demouser:  # database owner
    - superuser
    - createdb
  databases:
    demo: demo_owner  # dbname: owner
  preparedDatabases:
    demo: {}
  postgresql:
    version: "14"
  clone:
    cluster: "postgres-demo-cluster"  # Inplace restore when having the same cluster name as the source
    timestamp: "2022-05-03T19:50:00+00:00"  # timezone required (offset relative to UTC, see RFC 3339 section 5.6)
If you’ve read the official documentation, you might wonder why I don’t use the uid parameter in the clone section. It’s because in my backup setup, I set the WAL_BUCKET_SCOPE_PREFIX and WAL_BUCKET_SCOPE_SUFFIX both to null. This leaves out the cluster uid in the S3 backup path and makes it more straight forward in my opinion.

Let’s apply the updated manifest (kubectl apply -f demo-cluster-inplace-restore.yaml) and check the logfiles of the Postgres pods. You will find something like this in it:

```
2022-05-03 20:05:04,811 - bootstrapping - INFO - Configuring wal-e
2022-05-03 20:05:04,811 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/WALE_S3_PREFIX
2022-05-03 20:05:04,812 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/WALG_S3_PREFIX
2022-05-03 20:05:04,812 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/AWS_ACCESS_KEY_ID
2022-05-03 20:05:04,812 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/AWS_SECRET_ACCESS_KEY
2022-05-03 20:05:04,812 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/WALE_S3_ENDPOINT
2022-05-03 20:05:04,813 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/AWS_ENDPOINT
2022-05-03 20:05:04,813 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/AWS_REGION
2022-05-03 20:05:04,813 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/WALE_DISABLE_S3_SSE
2022-05-03 20:05:04,813 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/WALG_DISABLE_S3_SSE
2022-05-03 20:05:04,813 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/AWS_S3_FORCE_PATH_STYLE
2022-05-03 20:05:04,813 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/WALG_DOWNLOAD_CONCURRENCY
2022-05-03 20:05:04,814 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/WALG_UPLOAD_CONCURRENCY
2022-05-03 20:05:04,814 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/USE_WALG_BACKUP
2022-05-03 20:05:04,814 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/USE_WALG_RESTORE
2022-05-03 20:05:04,814 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/WALE_LOG_DESTINATION
2022-05-03 20:05:04,814 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/PGPORT
2022-05-03 20:05:04,815 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/BACKUP_NUM_TO_RETAIN
2022-05-03 20:05:04,815 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/TMPDIR
2022-05-03 20:05:04,815 - bootstrapping - INFO - Configuring pam-oauth2
2022-05-03 20:05:04,815 - bootstrapping - INFO - Writing to file /etc/pam.d/postgresql
2022-05-03 20:05:04,815 - bootstrapping - INFO - Configuring certificate
2022-05-03 20:05:04,815 - bootstrapping - INFO - Generating ssl self-signed certificate
2022-05-03 20:05:04,847 - bootstrapping - INFO - Configuring bootstrap
2022-05-03 20:05:04,847 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env-clone-postgres-demo-cluster/WALE_S3_PREFIX
2022-05-03 20:05:04,848 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env-clone-postgres-demo-cluster/WALG_S3_PREFIX
2022-05-03 20:05:04,848 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env-clone-postgres-demo-cluster/AWS_ACCESS_KEY_ID
2022-05-03 20:05:04,848 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env-clone-postgres-demo-cluster/AWS_SECRET_ACCESS_KEY
2022-05-03 20:05:04,848 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env-clone-postgres-demo-cluster/WALE_S3_ENDPOINT
2022-05-03 20:05:04,848 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env-clone-postgres-demo-cluster/AWS_ENDPOINT
2022-05-03 20:05:04,848 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env-clone-postgres-demo-cluster/AWS_REGION
2022-05-03 20:05:04,849 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env-clone-postgres-demo-cluster/WALE_DISABLE_S3_SSE
2022-05-03 20:05:04,849 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env-clone-postgres-demo-cluster/WALG_DISABLE_S3_SSE
2022-05-03 20:05:04,849 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env-clone-postgres-demo-cluster/AWS_S3_FORCE_PATH_STYLE
2022-05-03 20:05:04,849 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env-clone-postgres-demo-cluster/USE_WALG_BACKUP
2022-05-03 20:05:04,849 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env-clone-postgres-demo-cluster/USE_WALG_RESTORE
2022-05-03 20:05:04,849 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env-clone-postgres-demo-cluster/WALE_LOG_DESTINATION
2022-05-03 20:05:04,849 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env-clone-postgres-demo-cluster/TMPDIR
2022-05-03 20:05:06,051 WARNING: Kubernetes RBAC doesn't allow GET access to the 'kubernetes' endpoint in the 'default' namespace. Disabling 'bypass_api_service'.
2022-05-03 20:05:06,065 INFO: No PostgreSQL configuration items changed, nothing to reload.
2022-05-03 20:05:06,067 INFO: Lock owner: None; I am postgres-demo-cluster-0
2022-05-03 20:05:06,097 INFO: trying to bootstrap a new cluster
2022-05-03 20:05:06,098 INFO: Running custom bootstrap script: envdir "/run/etc/wal-e.d/env-clone-postgres-demo-cluster" python3 /scripts/clone_with_wale.py --recovery-target-time="2022-05-03T19:50:00+00:00"
2022-05-03 20:05:06,230 INFO: Trying s3://postgresql/spilo/postgres-demo-cluster/wal/14/ for clone
2022-05-03 20:05:06,290 INFO: cloning cluster postgres-demo-cluster using wal-g backup-fetch /home/postgres/pgdata/pgroot/data base_000000010000000000000004
INFO: 2022/05/03 20:05:06.313280 Selecting the backup with name base_000000010000000000000004...
INFO: 2022/05/03 20:05:06.409909 Finished decompression of part_003.tar.lz4
INFO: 2022/05/03 20:05:06.409930 Finished extraction of part_003.tar.lz4
2022-05-03 20:05:16,568 INFO: Lock owner: None; I am postgres-demo-cluster-0
2022-05-03 20:05:16,568 INFO: not healthy enough for leader race
2022-05-03 20:05:16,587 INFO: bootstrap in progress
```

There are two things to mention, in the upper part of the log, you can see, that the Postgres Operator sets some environment variables in the envdir /run/etc/wal-e.d/env-clone-postgres-demo-cluster/. These are the settings WAL-G needs to find the backups of your source instance (where source and target is the same in this scenario). The second thing to mention is the actual restore that takes place. Once in the line with out specified target time for the point in time restore and then second, that he has found the backup of our source database.

When you shell into your database pod and issue a patronictl list command, you can also see, that the timeline (so the incarnation of the instance) has increased. We took the backup from the 1st timeline, after the restore has been finished, we’re now at timeline 3.

root@postgres-demo-cluster-0:/home/postgres# patronictl list
| Member                  | Host         | Role    | State   | TL | Lag in MB |
+-------------------------+--------------+---------+---------+----+-----------+
| postgres-demo-cluster-0 | 10.244.1.11  | Leader  | running |  3 |           |
...
Let’s proceed to the next scenario, this time, we clone to a new instance / cluster in a different namespace.

Clone restore

This time, out manifest for cloning our postgres-demo-cluster looks like this. It’s mostly the same than in the first scenario, with the exception, that we use a different namespace and also a different cluster name. (Also, you can find the manifest here).

demo-cluster-clone.yaml
apiVersion: "acid.zalan.do/v1"
kind: postgresql
metadata:
  name: postgres-demo-cluster-clone
  namespace: postgres-clone
spec:
  teamId: "postgres"
  volume:
    size: 2Gi
  numberOfInstances: 1
  users:
    demouser:  # database owner
    - superuser
    - createdb
  databases:
    demo: demo_owner  # dbname: owner
  preparedDatabases:
    demo: {}
  postgresql:
    version: "14"
  clone:
    cluster: "postgres-demo-cluster"  # Source instance name; Instance name to clone from
    timestamp: "2022-05-03T19:50:00+00:00"  # timezone required (offset relative to UTC, see RFC 3339 section 5.6)
When doing a restore as a clone, you have more choices in changing the configuration of your database. I would still advice you not to change too much. On the positive side is, if there is a problem with this cloned restore, just delete it and start fresh. Also your source instance does not need to be deleted. You can doublecheck if the clone delivers the expected result first. Apply the manifest:

Fish
kubectl apply -f demo-cluster-clone.yaml
postgresql.acid.zalan.do/postgres-demo-cluster-clone created
```
2022-05-03 20:20:04,356 - bootstrapping - INFO - Configuring bootstrap
2022-05-03 20:20:04,357 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env-clone-postgres-demo-cluster/WALE_S3_PREFIX
2022-05-03 20:20:04,357 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env-clone-postgres-demo-cluster/WALG_S3_PREFIX
2022-05-03 20:20:04,357 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env-clone-postgres-demo-cluster/AWS_ACCESS_KEY_ID
2022-05-03 20:20:04,357 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env-clone-postgres-demo-cluster/AWS_SECRET_ACCESS_KEY
2022-05-03 20:20:04,357 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env-clone-postgres-demo-cluster/WALE_S3_ENDPOINT
2022-05-03 20:20:04,358 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env-clone-postgres-demo-cluster/AWS_ENDPOINT
2022-05-03 20:20:04,358 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env-clone-postgres-demo-cluster/AWS_REGION
2022-05-03 20:20:04,358 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env-clone-postgres-demo-cluster/WALE_DISABLE_S3_SSE
2022-05-03 20:20:04,358 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env-clone-postgres-demo-cluster/WALG_DISABLE_S3_SSE
2022-05-03 20:20:04,358 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env-clone-postgres-demo-cluster/AWS_S3_FORCE_PATH_STYLE
2022-05-03 20:20:04,358 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env-clone-postgres-demo-cluster/USE_WALG_BACKUP
2022-05-03 20:20:04,359 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env-clone-postgres-demo-cluster/USE_WALG_RESTORE
2022-05-03 20:20:04,359 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env-clone-postgres-demo-cluster/WALE_LOG_DESTINATION
2022-05-03 20:20:04,359 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env-clone-postgres-demo-cluster/TMPDIR
2022-05-03 20:20:04,359 - bootstrapping - INFO - Configuring certificate
2022-05-03 20:20:04,359 - bootstrapping - INFO - Generating ssl self-signed certificate
2022-05-03 20:20:04,417 - bootstrapping - INFO - Configuring standby-cluster
2022-05-03 20:20:04,417 - bootstrapping - INFO - Configuring log
2022-05-03 20:20:04,417 - bootstrapping - INFO - Configuring pgbouncer
2022-05-03 20:20:04,417 - bootstrapping - INFO - No PGBOUNCER_CONFIGURATION was specified, skipping
2022-05-03 20:20:04,418 - bootstrapping - INFO - Configuring crontab
2022-05-03 20:20:04,418 - bootstrapping - INFO - Skipping creation of renice cron job due to lack of SYS_NICE capability
2022-05-03 20:20:04,431 - bootstrapping - INFO - Configuring pam-oauth2
2022-05-03 20:20:04,431 - bootstrapping - INFO - Writing to file /etc/pam.d/postgresql
2022-05-03 20:20:04,431 - bootstrapping - INFO - Configuring wal-e
2022-05-03 20:20:04,431 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/WALE_S3_PREFIX
2022-05-03 20:20:04,431 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/WALG_S3_PREFIX
2022-05-03 20:20:04,432 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/AWS_ACCESS_KEY_ID
2022-05-03 20:20:04,432 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/AWS_SECRET_ACCESS_KEY
2022-05-03 20:20:04,432 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/WALE_S3_ENDPOINT
2022-05-03 20:20:04,432 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/AWS_ENDPOINT
2022-05-03 20:20:04,432 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/AWS_REGION
2022-05-03 20:20:04,432 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/WALE_DISABLE_S3_SSE
2022-05-03 20:20:04,432 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/WALG_DISABLE_S3_SSE
2022-05-03 20:20:04,432 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/AWS_S3_FORCE_PATH_STYLE
2022-05-03 20:20:04,433 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/WALG_DOWNLOAD_CONCURRENCY
2022-05-03 20:20:04,433 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/WALG_UPLOAD_CONCURRENCY
2022-05-03 20:20:04,433 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/USE_WALG_BACKUP
2022-05-03 20:20:04,433 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/USE_WALG_RESTORE
2022-05-03 20:20:04,433 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/WALE_LOG_DESTINATION
2022-05-03 20:20:04,433 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/PGPORT
2022-05-03 20:20:04,433 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/BACKUP_NUM_TO_RETAIN
2022-05-03 20:20:04,434 - bootstrapping - INFO - Writing to file /run/etc/wal-e.d/env/TMPDIR
2022-05-03 20:20:05,608 WARNING: Kubernetes RBAC doesn't allow GET access to the 'kubernetes' endpoint in the 'default' namespace. Disabling 'bypass_api_service'.
2022-05-03 20:20:05,620 INFO: No PostgreSQL configuration items changed, nothing to reload.
2022-05-03 20:20:05,623 INFO: Lock owner: None; I am postgres-demo-cluster-clone-0
2022-05-03 20:20:05,643 INFO: trying to bootstrap a new cluster
2022-05-03 20:20:05,644 INFO: Running custom bootstrap script: envdir "/run/etc/wal-e.d/env-clone-postgres-demo-cluster" python3 /scripts/clone_with_wale.py --recovery-target-time="2022-05-03T19:50:00+00:00"
2022-05-03 20:20:05,776 INFO: Trying s3://postgresql/spilo/postgres-demo-cluster/wal/14/ for clone
2022-05-03 20:20:05,884 INFO: cloning cluster postgres-demo-cluster-clone using wal-g backup-fetch /home/postgres/pgdata/pgroot/data base_000000010000000000000004
INFO: 2022/05/03 20:20:05.906757 Selecting the backup with name base_000000010000000000000004...
INFO: 2022/05/03 20:20:05.989340 Finished decompression of part_003.tar.lz4
INFO: 2022/05/03 20:20:05.989414 Finished extraction of part_003.tar.lz4
INFO: 2022/05/03 20:20:15.138568 Finished decompression of part_001.tar.lz4
INFO: 2022/05/03 20:20:15.138590 Finished extraction of part_001.tar.lz4
INFO: 2022/05/03 20:20:15.153621 Finished decompression of pg_control.tar.lz4
INFO: 2022/05/03 20:20:15.153764 Finished extraction of pg_control.tar.lz4
INFO: 2022/05/03 20:20:15.154067
Backup extraction complete.
```
Again, you will find the same output then before. Shell into the database pod and check the cluster status by patronictl list.

root@postgres-demo-cluster-clone-0:/home/postgres# patronictl list
+ Cluster: postgres-demo-cluster-clone (7093595735000756305) ----+----+-----------+
| Member                        | Host        | Role   | State   | TL | Lag in MB |
+-------------------------------+-------------+--------+---------+----+-----------+
| postgres-demo-cluster-clone-0 | 10.244.1.13 | Leader | running |  4 |           |
+-------------------------------+-------------+--------+---------+----+-----------+
All seems fine. One more word regarding the cloned instance. If you’ve followed my backup setup instructions from this blogpost, the cloned instance will do a backup right after the restore. This might be a wanted behavior or not, this totally depends on you. So keep it on your list.

Philip

Ähnliche Beiträge:
Backup to S3 – Configure Zalando Postgres Operator Backup with WAL-G Get me those metrics – Use Prometheus WAL-G backup exporter A pinch of salt – Encrypt WAL-G PostgreSQL backups Keep the Elephants in line – Deploy Zalando Postgres Operator on your Kubernetes cluster
Tags:BACKUPBASEBACKUPBUCKETK8SKUBERNETESMINIOOBJECT STORAGEPOSTGRESPOSTGRESQLRESTORES3WALWAL-GZALANDO OPERATOR
27 thoughts on “Restore and Clone from S3 – Configure Zalando Postgres Operator Restore with WAL-G”


Michael
5. August 2022 at 18:14
REPLY
One question… On restore, I need to set a timestamp. Does this need to be the exact timestamp for an existing backup, or something relative to a possible backup? How can I know the exact timestamp once the deployment was destroyed, for example?
Avatar photo
TheDatabaseMe
5. August 2022 at 23:27
REPLY
Hello Michael,

the timestamp is a point in time between the oldest existing backup and the newest WAL archive. So it doesn’t need to be an exact timestamp of a basebackup. There are some issues when you want to restore to a timeline before the current one. But this topic is adressed and actively worked on.

In case you have lost the complete deployment, the only way to know which backups exist is to check the S3 bucket for existing backups or to recreate the deployment as a single instance with the same name. What then will happen is, that a new timeline will be created but you can check the existing backups with the wal-g commands then. (At least when you followed the instructions within the blogpost with unsetting prefix and suffix)
I would suggest, you check the S3 storage though.
