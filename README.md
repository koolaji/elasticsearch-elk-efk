# ELK and EFK Docker Compose Stacks

This repository provides Docker Compose configurations for deploying ELK (Elasticsearch, Logstash, Kibana) and EFK (Elasticsearch, Fluentd, Kibana) stacks. These stacks are designed for log collection, analysis, and visualization.

**Author:** Mehrdad Koolaji

## Directory Structure

*   `elk/`: Contains the Docker Compose and configuration files for the ELK stack.
*   `efk/`: Contains the Docker Compose and configuration files for the EFK stack.

## ELK Stack

The ELK stack is located in the `elk` directory and includes the following services:

*   **Elasticsearch**: A distributed search and analytics engine.
*   **Logstash**: A data processing pipeline that ingests, transforms, and sends data to Elasticsearch.
*   **Kibana**: A web interface for visualizing and exploring data in Elasticsearch.
*   **Filebeat**: A lightweight log shipper that forwards log data to Logstash.
*   **Metricbeat**: A lightweight metric shipper that collects system and service metrics and sends them to Elasticsearch.

### Data Flow

1.  **Filebeat**: Collects container logs from `/var/lib/docker/containers/*.log` and forwards them to Logstash on port `5044`.
2.  **Metricbeat**: Collects Docker container metrics and sends them directly to Elasticsearch.
3.  **Logstash**: Receives logs from Filebeat, processes them, and indexes them in Elasticsearch under the `filebeat-*` index pattern.

### Usage

To start the ELK stack, navigate to the `elk` directory and run:

```bash
docker-compose up -d
```

To stop the stack, run:

```bash
docker-compose down
```

## EFK Stack

The EFK stack is located in the `efk` directory and includes the following services:

*   **Elasticsearch**: A distributed search and analytics engine.
*   **Fluentd**: A data collector for unified logging.
*   **Kibana**: A web interface for visualizing and exploring data in Elasticsearch.
*   **td-agent**: A stable distribution of Fluentd, configured to forward logs to the main Fluentd service.

### Data Flow

1.  **td-agent**: Listens for logs on port `24225` and forwards them to the `fluentd` service.
2.  **Fluentd**: Receives logs from `td-agent` on port `24224` and can also accept logs via HTTP on port `9880`. It processes the logs and sends them to Elasticsearch, where they are indexed under the `fluentd-logs` index.

### Usage

To start the EFK stack, navigate to the `efk` directory and run:

```bash
docker-compose up -d
```

To stop the stack, run:

```bash
docker-compose down
```

## Prerequisites

*   Docker
*   Docker Compose

## License

This project is licensed under the MIT License.
