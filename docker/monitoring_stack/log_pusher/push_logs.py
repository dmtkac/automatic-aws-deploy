#!/usr/bin/env python3
#
# -----------------------------------------------------------------------------
# Log Pusher Application
#
# This script continuously tails various log sources and pushes new log entries 
# to a Loki instance via its HTTP push API.
#
# The reason for creating custom log pusher for Loki was that existing agents/scrapers
# (e.g., fluent bit, promtail, alloy etc.) were over complicated software blobs, which
# did not have functions AND simplicity that I needed; plus after hours and hours spent
# on reading documentation and experimenting, some of them they were still not working 
# correctly (or at all!). But luckily, Loki supports pushing logs via API and we have 
# Python almighty :) 
# 
# So, features:
# - Supports multiple log sources (e.g., syslog, auth.log, dpkg.log, fail2ban.log,
#   gateway logs, and optionally geoip2 and cookie consent logs).
# - Uses optional filtering per source (e.g., filtering out lines with a specific IP).
# - Applies timestamp filtering to only push recent log entries.
# - Enriches "gateway" logs with HTTP status level for color coding and GeoIP data
#   for connection request visualization on geographical map.
# - Processes each log source in its own thread.
#
# -----------------------------------------------------------------------------

import os
import time
import json
import re
import requests
from pygtail import Pygtail
import threading
import datetime
import subprocess
import shlex
import geoip2.database
import datetime

STATE_DIR = "/app/state"
# Environment variable for a filtered IP (for instance, user's own IP).
#FILTERED_IP = os.getenv("FILTERED_IP", None) # uncomment if a certain IP needs to be filtered out from gateway and fail2ban logs
os.makedirs(STATE_DIR, exist_ok=True)

# MaxMind free GeoIP-City IP database. Mounts from host OS inside container as a volume.
# Can be placed manually or updated automatically twice a week (updating script not provided).
reader = geoip2.database.Reader('/app/GeoLite2-City.mmdb')

LOG_SOURCES = [
    {
        "path": "/var/log/syslog", 
        "job": "syslog",
        "filter": None,
        "poll_interval": 10
    },
    {
        "path": "/var/log/auth.log", 
        "job": "auth",
        "filter": None,
        "poll_interval": 10
    },
    {
        "path": "/var/log/dpkg.log", 
        "job": "dpkg",
        "filter": None,
        "poll_interval": 10
    },
    {
        "path": "/var/log/fail2ban.log",
        "job": "fail2ban",
        "filter": None,
        #"filter": lambda line: re.search(rf"{re.escape(FILTERED_IP)}", line) is None,
        "poll_interval": 10
    },
    {
        "path": "/host_home/gateway_logs.log",
        "job": "gateway",
        "filter": None,
        #"filter": lambda line: re.search(rf"{re.escape(FILTERED_IP)}", line) is None,
        "poll_interval": 5
    }
    # ** Not implemented in this demo **
    #{
    #    "path": "/host_home/geoip2_lite.log",
    #    "job": "geoip2",
    #    "filter": lambda line: ("successfully" in line) or ("ERROR" in line),
    #    "poll_interval": 60
    #},
    #{
    #    "path": "/host_home/cookie_consent.log",
    #    "job": "cookie",
    #    "filter": None,
    #    "poll_interval": 60
    #}
]

LOKI_URL = "http://loki:3100/loki/api/v1/push"

def extract_status_code(line):
    """
    Extracts HTTP status code from a log line using a regex.
    Returns the status code as an integer, or None if extraction fails.
    """
    m = re.search(
        r'^(?P<ip>\S+)\s+-\s+-\s+\[[^\]]+\]\s+"[^"]+"\s+(?P<status>\d{3})\s+',
        line
    )
    if m:
        try:
            return int(m.group("status"))
        except Exception as e:
            return None
    return None

def is_recent_log(line, job, max_age_hours=24):
    """
    Determines if a log line is recent (not older than 24 hours) based on its timestamp.
    Uses different timestamp formats based on the job.
    Returns True if the log's age is less than max_age_hours.
    """
    # Expected formats for each job
    formats = {
        # Gateway (Docker Nginx) logs / cookie consent logs:
        "docker": ("%d/%b/%Y:%H:%M:%S %z", r'\[(?P<timestamp>[^\]]+)\]'),
        #"cookie": ("%d/%b/%Y:%H:%M:%S %z", r'\[(?P<timestamp>[^\]]+)\]'), # not implemented in this demo
        # Syslog, auth.log:
        "syslog": ("%b %d %H:%M:%S", r'^(?P<timestamp>[A-Z][a-z]{2}\s+\d+\s+\d{2}:\d{2}:\d{2})'),
        "auth":   ("%b %d %H:%M:%S", r'^(?P<timestamp>[A-Z][a-z]{2}\s+\d+\s+\d{2}:\d{2}:\d{2})'),
        # dpkg and fail2ban logs:
        "dpkg":   ("%Y-%m-%d %H:%M:%S", r'^(?P<timestamp>\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2})'),
        "fail2ban": ("%Y-%m-%d %H:%M:%S", r'^(?P<timestamp>\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2})'),
    }

    # Gets format and regex for the job; if not defined, assumes they they are recent
    fmt, regex = formats.get(job, (None, None))
    if fmt is None:
        # For jobs not listed, assumes they are recent
        return True

    # Extracts the timestamp using the regex
    m = re.search(regex, line)
    if not m:
        # If no timestamp is found, assumes the log is recent
        return True

    timestamp_str = m.group("timestamp")
    try:
        log_time = datetime.datetime.strptime(timestamp_str, fmt)
        # If the parsed datetime is naive, attaches UTC as its timezone
        if log_time.tzinfo is None:
            log_time = log_time.replace(tzinfo=datetime.timezone.utc)
        if job in ["syslog", "auth"]:
            log_time = log_time.replace(year=datetime.datetime.now().year, tzinfo=datetime.timezone.utc)
    except Exception as e:
        # If parsing fails, assumes the log is recent
        return True

    now = datetime.datetime.now(datetime.timezone.utc)
    age_seconds = (now - log_time).total_seconds()
    return age_seconds < max_age_hours * 3600

def map_status_to_level(code):
    """
    Maps an HTTP status code to a level string.
    Returns 'info' for 200-298 (or 304), 'warn' for 300, 301, 307, 308, and 'error' for 400-599.
    This is done for logs to appear color coded in Grafana's 'Nginx.log' panel
    """
    if code is None:
        return None
    if (200 <= code < 299) or code == 304:
        return "info"
    elif code in [300, 301, 307, 308]:
        return "warn"
    elif 400 <= code < 600:
        return "error"
    return None

def push_log(job, message, extra_labels=None):
    """
    Sends a log message to Loki using the push API.
    Enriches the log with HTTP status level for gateway logs.
    """
    import time, json, requests
    ts = str(int(time.time() * 1e9))
    if extra_labels is None:
        extra_labels = {}

    if job == "gateway":
        status_code = extract_status_code(message)
        log_level = map_status_to_level(status_code)
        if log_level is not None:
            extra_labels["level"] = log_level

    stream_labels = {"job": job}
    stream_labels.update(extra_labels)
    payload = {
        "streams": [
            {
                "stream": stream_labels,
                "values": [[ts, message]]
            }
        ]
    }
    headers = {"Content-Type": "application/json"}
    try:
        response = requests.post(LOKI_URL, data=json.dumps(payload), headers=headers)
        if response.status_code == 204:
            print(f"[{job}] Pushed: {message}")
        else:
            print(f"[{job}] Error pushing log: {response.status_code} {response.text}")
    except Exception as e:
        print(f"[{job}] Exception pushing log: {e}")

# ** Not implemented in this demo **
#def should_poll_geoip2():
#    """
#    Returns True if the current time falls within a specific window 
#    (e.g., 1:00-1:15 AM on selected weekdays)
#    for polling the geoip2 log source.
#    """
#    now = datetime.datetime.now()
#    # Weekday: Monday is 0, Tuesday 1, ..., Sunday 6.
#    if now.weekday() in [1, 2, 4, 5] and now.hour == 1 and 0 <= now.minute < 15:
#        return True
#    return False

def enrich_with_geo(ip_address):
    """
    Uses the GeoIP2 database to look up geographic information for an IP address.
    Returns a dictionary with 'lat', 'lon', and 'country' if successful; otherwise, 
    returns an empty dict.
    """
    try:
        resp = reader.city(ip_address)
        return {
            "lat": resp.location.latitude,
            "lon": resp.location.longitude,
            "country": resp.country.iso_code
        }
    except Exception as e:
        print(f"GeoIP lookup failed for {ip_address}: {e}")
        return {}

def extract_ip(line):
    """
    Extracts the IP address at the beginning of a log line.
    Returns the IP as a string.
    """
    match = re.search(r'^(\d{1,3}(?:\.\d{1,3}){3})', line)
    if match:
        ip = match.group(1)
        return ip
    return None

def tail_log_source(source):
    """
    Continuously tails a log source.    
    For file-based sources, it uses Pygtail to track and read new lines.
    For command-based sources, it runs the command (e.g., docker logs) and processes its output.
    Each new line is filtered (if a filter function is provided) and checked if it's recent,
    then enriched with 'lon' and 'lat' parameters (for gateway logs) before being pushed to Loki.
    """
    job = source["job"]
    poll_interval = source.get("poll_interval", 5)
    filter_fn = source.get("filter")
    
    # Command-based sources
    if "command" in source:
        command = shlex.split(source["command"])
        print(f"Starting to tail logs for job {job} using command: {' '.join(command)}")
        while True:
            try:
                proc = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                for line in proc.stdout:
                    line = line.strip()
                    if not line:
                        continue
                    if filter_fn and not filter_fn(line):
                        continue
                    # Timestamp filtering:
                    if not is_recent_log(line, job):
                        continue
                    extra_labels = {}
                    if job == "gateway":
                        ip_address = extract_ip(line)
                        if ip_address:
                            extra_labels = enrich_with_geo(ip_address)
                    push_log(job, line, extra_labels)
                proc.wait()
            except Exception as e:
                print(f"Error running command for {job}: {e}")
            time.sleep(poll_interval)
    else:
        # File-based source
        path = source["path"]
        state_file = os.path.join(STATE_DIR, os.path.basename(path) + ".offset")
        print(f"Starting to tail {path} for job {job} using state file {state_file}")
        while True:
            try:
                for line in Pygtail(path, offset_file=state_file):
                    line = line.strip()
                    if not line:
                        continue
                    if filter_fn and not filter_fn(line):
                        continue
                    # Timestamp filtering:
                    if not is_recent_log(line, job):
                        continue
                    extra_labels = {}
                    if job == "gateway":
                        ip_address = extract_ip(line)
                        if ip_address:
                            extra_labels = enrich_with_geo(ip_address)
                    push_log(job, line, extra_labels)
            except Exception as e:
                print(f"Error tailing {path}: {e}")
            time.sleep(poll_interval)

if __name__ == "__main__":
    print("Starting continuous log tailing and pushing with pygtail in threads...")
    threads = []
    for source in LOG_SOURCES:
        t = threading.Thread(target=tail_log_source, args=(source,))
        t.daemon = True
        t.start()
        threads.append(t)
    
    while True:
        time.sleep(60)