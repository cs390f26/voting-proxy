#!/usr/bin/env bash
# Delete the three voting security groups.
# Delete dependents first (db and flask reference other groups as sources).

set -euo pipefail

group_id() {
  aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=$1" \
    --query "SecurityGroups[0].GroupId" \
    --output text
}

for name in voting-db voting-flask voting-proxy; do
  id="$(group_id "$name")"
  if [[ -z "$id" || "$id" == "None" ]]; then
    echo "$name already gone"
    continue
  fi
  aws ec2 delete-security-group --group-id "$id"
  echo "deleted $name ($id)"
done
