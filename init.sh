#!bin/bash

SITE_NAME="helpdesk.localhost"

if [ -d "/home/frappe/frappe-bench/apps/frappe" ]; then
    echo "Bench already exists, skipping init"
    cd frappe-bench
    bench start
else
    echo "Creating new bench..."
fi

bench init --skip-redis-config-generation frappe-bench --version version-15

cd frappe-bench

# Use containers instead of localhost
bench set-mariadb-host mariadb
bench set-redis-cache-host redis://redis:6379
bench set-redis-queue-host redis://redis:6379
bench set-redis-socketio-host redis://redis:6379

# Remove redis, watch from Procfile
sed -i '/redis/d' ./Procfile
sed -i '/watch/d' ./Procfile

bench get-app helpdesk --branch main

curl -L https://raw.githubusercontent.com/abdulazizkomilov/frappe-helpdesk/main/apps/helpdesk/helpdesk/helpdesk/doctype/hd_ticket/api.py \
    -o /home/frappe/frappe-bench/apps/helpdesk/helpdesk/helpdesk/doctype/hd_ticket/api.py

bench new-site helpdesk.localhost \
--force \
--mariadb-root-password 123 \
--admin-password admin \
--no-mariadb-socket

bench --site helpdesk.localhost install-app helpdesk
bench --site helpdesk.localhost set-config developer_mode 1
bench --site helpdesk.localhost set-config mute_emails 0
bench --site helpdesk.localhost set-config server_script_enabled 1
bench --site helpdesk.localhost clear-cache
bench use helpdesk.localhost

bench --site $SITE_NAME 

bench build

bench --site $SITE_NAME clear-cache

bench start
