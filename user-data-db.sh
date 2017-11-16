#!/bin/bash

sudo apt update -y
sudo apt install -y postgresql
echo "host all all 10.10.1.0/24 trust" > /etc/postgresql/9.5/main/pg_hba.conf
echo "local all all trust" >> /etc/postgresql/9.5/main/pg_hba.conf
echo "listen_addresses='*'" >> /etc/postgresql/9.5/main/postgresql.conf
sudo service postgresql restart


