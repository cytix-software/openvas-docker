#!/bin/bash

# start redis server
/usr/bin/redis-server /etc/redis/redis-openvas.conf --supervised systemd --daemonize yes

# start postgres then create DB if not exists
service postgresql start

# start mosquitto
mosquitto -c /etc/mosquitto.conf &

while ! pg_isready > /dev/null 2>&1; do echo "Awaiting postgres server to come online." && sleep 1; done
echo "Postgres server online."

gvmd --listen-mode=666 &
gsad --http-only &
ospd-openvas --config /etc/gvm/ospd-openvas.conf -f -m 666 &
echo "OpenVAS is online."