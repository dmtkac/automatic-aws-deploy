#!/bin/bash

# For this script to work uncomment '# add_header X-Instance-ID $hostname;' line in 'nginx.conf'.
# If you provisioned EC2 instances with commented line, than edit 'nginx.conf' on-site and restart Nginx server.
# Alternatively, use CI/CD pipeline for recompiling the 'gateway' container and pushing its image to AWS ECR.

for i in {1..10}; do
  response=$(curl -s -k -D - *** -o /dev/null)
  instance_id=$(echo "$response" | grep -i "X-Instance-ID" | awk '{print $2}')
  remote_ip=$(echo "$response" | grep "Location" | awk -F/ '{print $3}' | cut -d: -f1)

  printf "Request %d: from %s Instance: %s\n" "$i" "$remote_ip" "$instance_id"
done