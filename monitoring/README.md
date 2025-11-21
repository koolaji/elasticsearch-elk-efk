mkdir -p   grafana_logs/ grafana_data/ prometheus_data/
chmod -R 7777  grafana_logs/ grafana_data/ prometheus_data/
docker compose up -d
