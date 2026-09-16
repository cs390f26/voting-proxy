#!/usr/bin/env bash
# Create the three voting security groups (inbound rules).
# If a group already exists, print that and leave it unchanged.

set -euo pipefail

group_id() {
  aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=$1" \
    --query "SecurityGroups[0].GroupId" \
    --output text
}

exists() {
  local id
  id="$(group_id "$1")"
  [[ -n "$id" && "$id" != "None" ]]
}

PROXY_ID=""
FLASK_ID=""

if exists voting-proxy; then
  PROXY_ID="$(group_id voting-proxy)"
  echo "voting-proxy already exists ($PROXY_ID)"
else
  PROXY_ID="$(
    aws ec2 create-security-group \
      --group-name voting-proxy \
      --description "SG for Voting Proxy allowing SSH and HTTP." \
      --query GroupId \
      --output text
  )"
  aws ec2 authorize-security-group-ingress \
    --group-id "$PROXY_ID" --protocol tcp --port 22 --cidr 0.0.0.0/0
  aws ec2 authorize-security-group-ingress \
    --group-id "$PROXY_ID" --protocol tcp --port 80 --cidr 0.0.0.0/0
  echo "created voting-proxy ($PROXY_ID)"
fi

if exists voting-flask; then
  FLASK_ID="$(group_id voting-flask)"
  echo "voting-flask already exists ($FLASK_ID)"
else
  FLASK_ID="$(
    aws ec2 create-security-group \
      --group-name voting-flask \
      --description "SG for Voting Web servers allowing SSH and port 5000 from proxy SG." \
      --query GroupId \
      --output text
  )"
  aws ec2 authorize-security-group-ingress \
    --group-id "$FLASK_ID" --protocol tcp --port 22 --source-group "$PROXY_ID"
  aws ec2 authorize-security-group-ingress \
    --group-id "$FLASK_ID" --protocol tcp --port 5000 --source-group "$PROXY_ID"
  echo "created voting-flask ($FLASK_ID)"
fi

if exists voting-db; then
  echo "voting-db already exists ($(group_id voting-db))"
else
  DB_ID="$(
    aws ec2 create-security-group \
      --group-name voting-db \
      --description "SG for database server allowing SSH access from proxy SG and DB access from flask SG." \
      --query GroupId \
      --output text
  )"
  aws ec2 authorize-security-group-ingress \
    --group-id "$DB_ID" --protocol tcp --port 22 --source-group "$PROXY_ID"
  aws ec2 authorize-security-group-ingress \
    --group-id "$DB_ID" --protocol tcp --port 8000 --source-group "$FLASK_ID"
  echo "created voting-db ($DB_ID)"
fi
