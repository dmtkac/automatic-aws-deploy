FROM grafana/loki:latest

USER root

RUN mkdir -p /loki/cache /loki/index /loki/compactor && \
    chown -R 1000:999 /loki 
    # Adjust UID:GID according to environment, using 'id' command

COPY loki/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]