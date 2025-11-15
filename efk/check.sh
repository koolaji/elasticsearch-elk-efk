#!/bin/bash
source .env
# Wait for Elasticsearch to be ready
echo "Waiting for Elasticsearch to be ready..."
until curl -s -k -u "elastic:${ELASTIC_PASSWORD}" "https://localhost:9200/_cluster/health" | grep -q '"status":"green\|yellow"'; do
  echo "Waiting for Elasticsearch..."
  sleep 5
done

echo "Creating Fluentd index template..."

# Create index template for Fluentd logs
curl -X PUT "https://localhost:9200/_index_template/fluentd-logs" \
  -k -u "elastic:${ELASTIC_PASSWORD}" \
  -H "Content-Type: application/json" \
  -d '{
  "index_patterns": ["fluentd-logs-*"],
  "priority": 500,
  "template": {
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0,
      "index.refresh_interval": "5s"
    },
    "mappings": {
      "properties": {
        "@timestamp": {
          "type": "date",
          "format": "strict_date_optional_time||epoch_millis"
        },
        "timestamp": {
          "type": "date",
          "format": "yyyy-MM-dd HH:mm:ss Z||strict_date_optional_time||epoch_millis"
        },
        "time": {
          "type": "date",
          "format": "strict_date_optional_time||epoch_millis"
        },
        "message": {
          "type": "text",
          "fields": {
            "keyword": {
              "type": "keyword",
              "ignore_above": 256
            }
          }
        },
        "hostname": {
          "type": "keyword"
        },
        "level": {
          "type": "keyword"
        },
        "worker_id": {
          "type": "integer"
        },
        "container_id": {
          "type": "keyword"
        },
        "container_name": {
          "type": "keyword"
        },
        "source": {
          "type": "keyword"
        },
        "tag": {
          "type": "keyword"
        }
      }
    }
  }
}'

echo ""
echo "Index template created successfully!"

# Verify template creation
echo "Verifying template..."
curl -s -k -u "elastic:${ELASTIC_PASSWORD}" "https://localhost:9200/_index_template/fluentd-logs" | jq .

echo ""
echo "Template setup complete!"

