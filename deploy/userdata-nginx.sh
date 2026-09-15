#!/bin/bash
# EC2 user-data script for the nginx reverse-proxy instance.
#
# When you launch the instance, paste this file into the User data field.
# Cloud-init runs it once as root on first boot.
#
# All output is saved to /var/log/cloud-init-output.log.

# Exit on error, undefined variable, or failure in a pipeline.
set -euo pipefail

##############################################################################
##############################################################################
# CHANGE REPO_URL BELOW: REPLACE YOUR_GITHUB_USERNAME WITH YOUR GITHUB
# USERNAME. DO NOT CHANGE THE REPOSITORY NAME (voting_proxy).
##############################################################################
##############################################################################
REPO_URL="https://github.com/YOUR_GITHUB_USERNAME/voting_proxy.git"

APP_DIR=/home/ec2-user/voting_proxy

yum install -y git nginx python3.12

git clone "$REPO_URL" "$APP_DIR"
cd "$APP_DIR"

python3.12 -m venv .venv
.venv/bin/pip install --upgrade pip
.venv/bin/pip install boto3

# Look up Flask instances by tag voting-role=flask (LabInstanceProfile).
.venv/bin/python scripts/write_nginx_config.py

nginx -t
systemctl enable --now nginx
