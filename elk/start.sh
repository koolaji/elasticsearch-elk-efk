#!/bin/bash
source .env
set -e  # Exit on any error

echo "=== Starting ELK Stack with Auto-Configuration ==="

# Set vm.max_map_count for Elasticsearch
echo "Setting vm.max_map_count..."
grep -qxF 'vm.max_map_count=262144' /etc/sysctl.conf || echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf
sysctl -p

# Check if ELASTIC_PASSWORD is set
if [ -z "$ELASTIC_PASSWORD" ]; then
  echo "ERROR: ELASTIC_PASSWORD environment variable is not set"
  echo "Please set it with: export ELASTIC_PASSWORD=your_password"
  exit 1
fi

# Create necessary data directories
echo "Creating data directories..."
mkdir -p data/certs data/esdata01 data/esdata02 data/esdata03 data/kibanadata
chmod -R 777 data

# Start Elasticsearch first
echo "Starting Elasticsearch cluster and Kibana..."
docker compose up -d setup es01 es02 es03 kibana

# Wait for Elasticsearch to be ready (using es01)
echo "Waiting for Elasticsearch to be ready..."
max_retries=30
retries=0
until curl -s -k -u elastic:${ELASTIC_PASSWORD} https://localhost:9200 >/dev/null; do
  retries=$((retries+1))
  if [ $retries -ge $max_retries ]; then
    echo "ERROR: Elasticsearch did not start after $max_retries retries"
    echo "Check Elasticsearch logs with: docker compose logs es01"
    exit 1
  fi
  sleep 5
  echo "Still waiting for Elasticsearch... (Attempt $retries/$max_retries)"
done
echo "✅ Elasticsearch is running!"

# Wait for Kibana to be ready
echo "Waiting for Kibana to be ready..."
max_retries=30
retries=0
until curl -s -k -u elastic:${ELASTIC_PASSWORD} http://localhost:5601/api/status | grep -q "\"status\":{\"overall\":{\"level\":\"available\""; do
  retries=$((retries+1))
  if [ $retries -ge $max_retries ]; then
    echo "ERROR: Kibana did not start after $max_retries retries"
    echo "Check Kibana logs with: docker compose logs kibana"
    exit 1
  fi
  sleep 5
  echo "Still waiting for Kibana... (Attempt $retries/$max_retries)"
done
echo "✅ Kibana is running!"

# Get the cluster UUID with validation
echo "Getting cluster UUID..."
CLUSTER_UUID=$(curl -s -k -u elastic:${ELASTIC_PASSWORD} https://localhost:9200?pretty | grep cluster_uuid | awk -F'"' '{print $4}')

# Validate UUID
if [[ ! $CLUSTER_UUID =~ ^[0-9a-zA-Z_-]+$ ]] || [ -z "$CLUSTER_UUID" ]; then
  echo "ERROR: Failed to get a valid cluster UUID. Got: '$CLUSTER_UUID'"
  echo "Check Elasticsearch is running correctly"
  exit 1
fi
echo "✅ Found cluster UUID: ${CLUSTER_UUID}"

# Update Filebeat config with cluster UUID
echo "Updating Filebeat configuration with cluster UUID..."
if grep -q "cluster_uuid:" ./filebeat/filebeat.yml; then
  sed -i "s/cluster_uuid: \".*\"/cluster_uuid: \"${CLUSTER_UUID}\"/" ./filebeat/filebeat.yml
elif grep -q "monitoring:" ./filebeat/filebeat.yml; then
  sed -i "/monitoring:/a \ \ cluster_uuid: \"${CLUSTER_UUID}\"" ./filebeat/filebeat.yml
else
  echo -e "\n# Monitoring with explicit cluster UUID\nmonitoring:\n  enabled: true\n  cluster_uuid: \"${CLUSTER_UUID}\"\n  elasticsearch:\n    hosts: [\"https://es01:9200\"]\n    username: \"elastic\"\n    password: \"\${ELASTIC_PASSWORD}\"\n    ssl.certificate_authorities: [\"/usr/share/filebeat/certs/ca/ca.crt\"]" >> ./filebeat/filebeat.yml
fi

# Update Metricbeat config with cluster UUID
echo "Updating Metricbeat configuration with cluster UUID..."
if grep -q "cluster_uuid:" ./metricbeat/metricbeat.yml; then
  sed -i "s/cluster_uuid: \".*\"/cluster_uuid: \"${CLUSTER_UUID}\"/" ./metricbeat/metricbeat.yml
elif grep -q "monitoring:" ./metricbeat/metricbeat.yml; then
  sed -i "/monitoring:/a \ \ cluster_uuid: \"${CLUSTER_UUID}\"" ./metricbeat/metricbeat.yml
else
  echo -e "\n# Monitoring with explicit cluster UUID\nmonitoring:\n  enabled: true\n  cluster_uuid: \"${CLUSTER_UUID}\"\n  elasticsearch:\n    hosts: [\"https://es01:9200\"]\n    username: \"elastic\"\n    password: \"\${ELASTIC_PASSWORD}\"\n    ssl.certificate_authorities: [\"/usr/share/metricbeat/certs/ca/ca.crt\"]" >> ./metricbeat/metricbeat.yml
fi

# Setup Logstash certificates
echo "Setting up Logstash certificates..."
cp -r data/certs/ca data/ca-logstash
sudo chown 1000:0 -R data/ca-logstash
sudo chmod 7777 -R data/ca-logstash

# Start the remaining services
echo "Starting Logstash, Filebeat, and Metricbeat..."
docker compose up -d logstash filebeat metricbeat

echo ""
echo "====================================================================="
echo "🎉 All services started with cluster UUID: ${CLUSTER_UUID}"
echo "The 'Standalone Cluster' should disappear from monitoring within 5-10 minutes."
echo "====================================================================="

