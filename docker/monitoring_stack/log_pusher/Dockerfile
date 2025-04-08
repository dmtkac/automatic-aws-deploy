FROM python:3.9-slim

USER root

WORKDIR /app

COPY push_logs.py /app/push_logs.py

RUN mkdir -p /app/state && chown 1000:999 /app/push_logs.py && \
    # Adjust UID:GID according to environment, using 'id' command
    chmod +x /app/push_logs.py

RUN pip install requests pygtail geoip2

USER 1000:999 
    # Adjust UID:GID according to environment, using 'id' command

CMD ["python3", "push_logs.py"]