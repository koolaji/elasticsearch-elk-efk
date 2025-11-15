#!/bin/bash
docker load -i kibana.tar
docker load -i elasticsearch.tar
docker load -i fluentd.tar


grep -qxF 'vm.max_map_count=262144' /etc/sysctl.conf || echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf
sysctl -p
mkdir -p data
cd data
mkdir -p  certs  esdata01  esdata02  esdata03  fluentd  kibanadata fluentd/fluentd-buffer/
cd ../
chmod -R 777 data
docker compose up setup   -d
docker compose up  -d
bash check.sh
docker compose up  -d
