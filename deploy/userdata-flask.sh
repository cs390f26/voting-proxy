#!/bin/bash
# EC2 user-data script for a Flask / gunicorn instance.
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
# USERNAME. DO NOT CHANGE THE REPOSITORY NAME (voting-proxy).
##############################################################################
##############################################################################
REPO_URL="https://github.com/YOUR_GITHUB_USERNAME/voting-proxy.git"

APP_DIR=/home/ec2-user/voting-proxy

yum install -y python3.12 git

git clone "$REPO_URL" "$APP_DIR"
cd "$APP_DIR"

python3.12 -m venv .venv
.venv/bin/pip install --upgrade pip
.venv/bin/pip install -r requirements.txt
.venv/bin/pip install -e .

# Look up the database instance by tag voting-role=db (LabInstanceProfile).
.venv/bin/python scripts/write_dotenv.py

chown -R ec2-user:ec2-user "$APP_DIR"

cp deploy/voting.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now voting.service
