#!/bin/bash
source .env
# Wait for Elasticsearch to be ready
echo "Waiting for Elasticsearch to be ready..."
until curl -s -k -u "elastic:${ELASTIC_PASSWORD}" "https://localhost:9200/_cluster/health" | grep -q '"status":"green\|yellow"'; do
  echo "Waiting for Elasticsearch..."
  sleep 5
done

echo "Elasticsearch is up and running!"

# Verify template creation
echo "Verifying template..."
curl -s -k -u "elastic:${ELASTIC_PASSWORD}" "https://localhost:9200/_cat/templates"

echo ""
echo "Setup complete!"