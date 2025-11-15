#!/bin/bash

# Set vm.max_map_count for Elasticsearch
grep -qxF 'vm.max_map_count=262144' /etc/sysctl.conf || echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf
sysctl -p

# Create necessary data directories
mkdir -p data/certs data/esdata01 data/esdata02 data/esdata03 data/kibanadata data/fluentd/fluentd-buffer data/td-agent/buffer
chmod -R 777 data

# Start the setup service and wait for it to complete
docker compose up setup -d
docker compose wait setup

# Start all other services
docker compose up -d

# Run the check script
bash check.sh

