# Deploy with CloudFormation (CLI)

This document explains how to launch the voting app with **AWS CloudFormation** and the **AWS CLI**.


## Prerequisites

You need the **AWS CLI** installed and configured with current AWS Academy Learner Lab credentials in the `[default]` profile.


## One-Time Setup

The files `deploy/userdata-db.sh`, `deploy/userdata-flask.sh`, and `deploy/userdata-nginx.sh` are used in the deployment process. You must change `REPO_URL` in **all three** before you deploy.

* Open each userdata file in Cursor or `nano`.
* Near the top of each file you will find the line:

  ```
  REPO_URL="https://github.com/YOUR_GITHUB_USERNAME/voting-proxy.git"
  ```
* Change `YOUR_GITHUB_USERNAME` to your GitHub username.
* Commit this change and push it back to your GitHub account:

  ```
  git add deploy/userdata-db.sh deploy/userdata-flask.sh deploy/userdata-nginx.sh
  git commit -m "set github account"
  git push origin main
  ```


If the `git push` command fails, check the url of `origin` and make sure it points at your fork of the repo:

  ```
  git remote -v
  ```


## Create the stack

CloudFormation defines a *stack* of AWS resources. For this application we need:

* Three security groups (proxy, Flask, database)
* Four EC2 instances (database, two Flask servers, proxy)


The file `deploy/cloudformation.yaml` specifies those resources.

From the root of your clone:

```bash
aws cloudformation create-stack \
  --stack-name voting-proxy \
  --template-body file://deploy/cloudformation.yaml \
  --parameters ParameterKey=GitHubUsername,ParameterValue=YOUR_GITHUB_USERNAME
```

Replace `YOUR_GITHUB_USERNAME` with your GitHub username.

Wait until the stack finished creating:

```bash
aws cloudformation wait stack-create-complete \
  --stack-name voting-proxy
```


## After the stack is complete

Read the public IP from the stack output:

```bash
aws cloudformation describe-stacks \
  --stack-name voting-proxy \
  --query 'Stacks[0].Outputs' \
  --output table
```

**CREATE_COMPLETE does not mean the app is ready.** User data still installs packages, clones the repo, and starts services. Wait a few minutes, then:

```bash
curl -s http://PUBLIC_IP/health
```

Or SSH with your Academy key and check `/var/log/cloud-init-output.log` if something failed.

If you use an Elastic IP for the semester, **associate it** with the proxy instance in the EC2 console (or with the CLI) after the instance exists, then use that address instead of the ephemeral public IP.


## Delete the stack

When you are done with the resources this template created:

```bash
aws cloudformation delete-stack --stack-name voting-proxy
aws cloudformation wait stack-delete-complete --stack-name voting-proxy
```

Deleting the stack removes the instances and the security groups. It does **not** release an Elastic IP you associated by hand.
