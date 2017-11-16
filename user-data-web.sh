#!/bin/bash

sudo apt update -y
sudo apt install -y nginx
cp /tmp/index.html /var/www/html/
sudo service nginx start
