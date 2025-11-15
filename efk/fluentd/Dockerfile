FROM fluentd:v1.16-debian-1

USER root

# Install dependencies
RUN apt-get update && \
    apt-get install -y build-essential ruby-dev curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install compatible elasticsearch client first
RUN gem install elasticsearch -v 7.17.11

# Install all required plugins
RUN gem install fluent-plugin-elasticsearch -v 5.4.3 && \
    gem install fluent-plugin-record-modifier && \
    gem install fluent-plugin-rewrite-tag-filter && \
    gem install fluent-plugin-multi-format-parser && \
    gem install fluent-plugin-kubernetes_metadata_filter && \
    gem install oj

# Create necessary directories
RUN mkdir -p /fluentd/log/buffer /fluentd/etc /fluentd/certs /tmp/fluentd-buffers /tmp/fluentd-failed && \
    chown -R fluent:fluent /fluentd /tmp/fluentd-buffers /tmp/fluentd-failed

USER fluent
WORKDIR /fluentd

EXPOSE 24224 9880 24220

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:9880/api/plugins.json || exit 1

CMD ["fluentd", "-c", "/fluentd/etc/fluent.conf", "-v"]


