#!/usr/bin/env bash
# Terminate the voting instances. Security groups are left in place.

set -euo pipefail

NAMES=(voting-db voting-flask voting-proxy)

ids="$(
  aws ec2 describe-instances \
    --filters \
      "Name=tag:Name,Values=$(IFS=,; echo "${NAMES[*]}")" \
      "Name=instance-state-name,Values=pending,running,stopping,stopped" \
    --query "Reservations[].Instances[].InstanceId" \
    --output text
)"

if [[ -z "$ids" ]]; then
  echo "no voting instances to terminate"
  exit 0
fi

echo "terminating: $ids"
aws ec2 terminate-instances --instance-ids $ids >/dev/null
aws ec2 wait instance-terminated --instance-ids $ids
echo "instances terminated"
