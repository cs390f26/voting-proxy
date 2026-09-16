#!/usr/bin/env bash
# Launch the four instances (database, two Flask, proxy) with the AWS CLI.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

AMI="$(
  aws ssm get-parameter \
    --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 \
    --query Parameter.Value \
    --output text
)"

echo "launching voting-db"
aws ec2 run-instances \
  --image-id "$AMI" \
  --instance-type t3.micro \
  --key-name vockey \
  --security-groups voting-db \
  --user-data "file://${SCRIPT_DIR}/userdata-db.sh" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=voting-db},{Key=voting-role,Value=db}]" \
  --query "Instances[].InstanceId" \
  --output text

echo "launching two voting-flask"
aws ec2 run-instances \
  --image-id "$AMI" \
  --instance-type t3.micro \
  --count 2 \
  --key-name vockey \
  --security-groups voting-flask \
  --iam-instance-profile Name=LabInstanceProfile \
  --user-data "file://${SCRIPT_DIR}/userdata-flask.sh" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=voting-flask},{Key=voting-role,Value=flask}]" \
  --query "Instances[].InstanceId" \
  --output text

echo "launching voting-proxy"
aws ec2 run-instances \
  --image-id "$AMI" \
  --instance-type t3.micro \
  --key-name vockey \
  --security-groups voting-proxy \
  --iam-instance-profile Name=LabInstanceProfile \
  --user-data "file://${SCRIPT_DIR}/userdata-nginx.sh" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=voting-proxy}]" \
  --query "Instances[].InstanceId" \
  --output text
