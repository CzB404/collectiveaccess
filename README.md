# CollectiveAccess

## News

- Providence Version 1.7.17

## About

- Contains both Providence and Pawtucket2
- Contains mysql
- Pawtucket is accessed by `https://domain_or_ipaddress:port/`
- Providence is accessed by `https://domain_or_ipaddress:port/providence`

## Note

You should not use the `latest` tag, it is unstable and can break.

The `DISPLAY_NAME` is the name of your archive that will show in the tab title and on Pawtucket.

## Pull Requests

If you fork the repo and make some changes that other's can use as well, please contribute them back as a PR!

Thanks to @martjanz for contributing.

## Image build

```sh
docker build --tag collectiveaccess:latest .
```

## Usage with Docker Compose

```sh
docker compose -p collectiveaccess up -d
```

The first time this command is run MySQL database will be created from scratch.

If any error occur you can check containers status with `docker ps -a` and if something happened on backend container probably is due to a lagged start of MySQL server. Running `docker-compose -p collectiveaccess up -d` will trigger a backend restart and will fix it.

Providence (admin UI) will be running on http://server-ip:8080/providence
Pawtucket (client UI) will be running on http://server-ip:8080/

### Backup

Use `docker compose -p collectiveaccess up -d` to make sure the service is up and running.

Stop the CollectiveAccess container with `docker compose stop backend`.

Execute these commands:

```sh
docker compose exec db mysqldump -u root --password='rootpass' --all-databases > all-databases.sql
docker run --rm --volumes-from collectiveaccess -v $(pwd):/backup ubuntu bash -c "tar czf /backup/collectiveaccess_backend-config.tar.gz /var/www/providence/app/conf"
docker run --rm --volumes-from collectiveaccess -v $(pwd):/backup ubuntu bash -c "tar czf /backup/collectiveaccess_backend-media.tar.gz /var/www/providence/media"
docker run --rm --volumes-from collectiveaccess -v $(pwd):/backup ubuntu bash -c "tar czf /backup/collectiveaccess_frontend-config.tar.gz /var/www/app/conf"

# Optionally compress the DB dump:
tar czf /backup/collectiveaccess_db-data.tar.gz all-databases.sql
```

Use `docker compose -p collectiveaccess up -d` to start up the service again.

### Restore

Use `docker compose -p collectiveaccess up -d` to make sure the service is up and running. Make sure the volumes are newly created by `docker compose`.

Stop the CollectiveAccess container with `docker compose stop backend`.

Execute these commands:

```sh
# Untar the DB dump if it was compressed:
tar xvf /backup/collectiveaccess_db-data.tar.gz all-databases.sql

cat all-databases.sql | docker compose exec -T db /usr/bin/mysql -u root --password='rootpass'
docker run --rm --volumes-from collectiveaccess -v $(pwd):/backup ubuntu bash -c "cd /var/www/providence/app/conf && tar xvf /backup/collectiveaccess_backend-config.tar.gz --strip 1"
docker run --rm --volumes-from collectiveaccess -v $(pwd):/backup ubuntu bash -c "cd /var/www/providence/media && tar xvf /backup/collectiveaccess_backend-media.tar.gz --strip 1"
docker run --rm --volumes-from collectiveaccess -v $(pwd):/backup ubuntu bash -c "cd /var/www/app/conf && tar xvf /backup/collectiveaccess_frontend-config.tar.gz --strip 1"
```

Use `docker compose -p collectiveaccess up -d` to start up the service again.

## Usage with Docker

```sh
# Run mysql container
docker run
    --name ca_mysql
    -e MYSQL_USER=user
    -e MYSQL_PASSWORD=pass
    -e MYSQL_DATABASE=collective
    -e MYSQL_ROOT_PASSWORD=rootpass
    -v /var/ca/mysql:/var/lib/mysql
    -d
    mysql:5.7

# Run the collective access container
docker run
    -–link ca_mysql:mysql
    -p 8080:80
    -e DB_HOST=ca_mysql
    -e DB_USER=user
    -e DB_PASSWORD=pass
    -e DB_NAME=collective
    -e DISPLAY_NAME="My Archive"        # optional
    -e ADMIN_EMAIL=admin@my-archive.tld # optional
    -e SMTP_SERVER=mail.my-archive.tld  # optional
    -v /var/ca/conf:/var/www/providence/app/conf
    -v /var/ca/media:/var/www/providence/media/
    pkuehne/collectiveaccess:1.1.0

# Go to https://domain_or_ip:8080/providence to setup the database structure
```
