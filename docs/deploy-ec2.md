# Overview

This document is the steps to run the voting app on four EC2 instances:

* the **proxy** (nginx)
* **two Flask servers**, launched at the same time
* a **database** server (DynamoDB Local)


## One-Time Setup: GitHub

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


If the `git push` command fails, check the URL of `origin` and make sure it points at your fork of the repo:

  ```
  git remote -v
  ```


## One-Time Setup: Security Groups

The proxy, Flask servers, and database each use their own security groups. We will create them
before we launch the instances so they can be reused each time we launch the system.

NOTE: The order matters because some groups are referenced by others.


### `voting-proxy`

The following steps will create a security group that will allow access to the proxy via ports 22 (SSH) and 80 (HTTP) from anywhere (0.0.0.0/0).

* In the EC2 console, open **Security Groups**.
* Click **Create security group**.
* For **Description** enter, "SG for Voting Proxy allowing SSH and HTTP."
* Name the group `voting-proxy`.
* Under **Inbound rules**, click **Add rule** and then set:
  * **Type**: "SSH"
  * **Source**: "Anywhere-IPv4"
* Click **Add rule** again and then set:
  * **Type**: "HTTP"
  * **Source**: "Anywhere-IPv4"
* At the bottom of the page, click **Create security group**.


### `voting-flask`

The following steps will create a security group that will allow access to the Flask servers via ports 22 (SSH) and 5000 (to access gunicorn on that port). In this case, we will only allow access from the `voting-proxy` security group (i.e. only from the proxy).


* In the EC2 console, open **Security Groups**.
* Click **Create security group**.
* Name the group `voting-flask`.
* For **Description** enter, "SG for Voting Web servers allowing SSH and port 5000 from proxy SG."
* Under **Inbound rules**, click **Add rule** and then set:
  * **Type**: "SSH"
  * **Source**: "Custom"
  * Click the search icon next to **Source** and select the security group `voting-proxy`.
* Click **Add rule** again and then set:
  * **Type**: "Custom TCP"
  * **Port range**: 5000
  * **Source**: "Custom"
  * Click the search icon next to **Source** and select the security group `voting-proxy`.
* At the bottom of the page, click **Create security group**.


### `voting-db`

The following steps will create a security group that will allow access to the database server via ports 22 (SSH) and 8000 (to access DynamoDB Local on that port). In this case, we will only allow SSH access from the `voting-proxy` security group (i.e. only from the proxy), and we will only allow DB access from the `voting-flask` security group (i.e. from the two Flask servers).


* In the EC2 console, open **Security Groups**.
* Click **Create security group**.
* Name the group `voting-db`.
* For **Description** enter, "SG for database server allowing SSH access from proxy SG and DB access from flask SG."
* Under **Inbound rules**, click **Add rule** and then set:
  * **Type**: "SSH"
  * **Source**: "Custom"
  * Click the search icon next to **Source** and select the security group `voting-proxy`.
* Click **Add rule** again and then set:
  * **Type**: "Custom TCP"
  * **Port range**: 8000
  * **Source**: "Custom"
  * Click the search icon next to **Source** and select the security group `voting-flask`.  **THIS ONE IS DIFFERENT**
* At the bottom of the page, click **Create security group**.


## Deploy Process

This deploy process has a number of steps, and different machines require different properties. You must launch the database first, then the Flask servers, and finally the proxy. When you launch the database and Flask servers you must add a special tag so that later launches can find those instances. When you launch the Flask servers and proxy you must add a role to give that machine additional permissions.

The following table summarizes the special aspects of each machine:


| Launch order | Type | `voting-role` Tag | IAM instance profile |
|--------------|----------|------|---------------|
| 1 | Database | `db` | (none) |
| 2 | Flask (x2) | `flask` | **LabInstanceProfile** |
| 3 | Proxy (nginx) | None | **LabInstanceProfile** |


### Launch the database

You must launch the database first because the Flask instances look for it when they launch. It has
a `voting-role` tag.


* In the EC2 console, click **Launch an instance**.
* Set **Name** as `voting-db`.
* Under **Name and tags**, click **Add additional tags** and then **Add new Tag**.
  * Key: `voting-role`
  * Value: `db`
* Leave **Application and OS Images:** Amazon Linux 2023.
* Leave **Instance type:** `t3.micro`.
* Under **Key pair**, select `vockey`.
* Under **Security group**:
  * Choose **Select existing security group**.
  * Select `voting-db`.
* Expand **Advanced details**.
* Under **User data** (at the bottom of advanced) paste the contents of `deploy/userdata-db.sh`.
* Click **Launch instance**.


### Launch the Flask servers

Launch the two Flask servers after the database is running. They have a `voting-role` tag, and they use the `LabInstanceProfile` role.


* In the EC2 console, click **Launch an instance**.
* In the **Summary** panel on the right, set **Number of instances** to **2**.
* Set **Name** as `voting-flask`.
* Under **Name and tags**, click **Add additional tags** and then **Add new Tag**.
  * Key: `voting-role`
  * Value: `flask`
* Leave **Application and OS Images:** Amazon Linux 2023.
* Leave **Instance type:** `t3.micro`.
* Under **Key pair**, select `vockey`.
* Under **Security group**:
  * Choose **Select existing security group**.
  * Select `voting-flask`.
* Expand **Advanced details**.
* Under **IAM instance profile** select `LabInstanceProfile`.
* Under **User data** (at the bottom of advanced) paste the contents of `deploy/userdata-flask.sh`.
* Click **Launch instance**.


### Launch the proxy

Launch the proxy after the Flask servers are running. This instance does not need a `voting-role` tag, but it does need the `LabInstanceProfile` role.


* In the EC2 console, click **Launch an instance**.
* Set **Name** as `voting-proxy`.
* Leave **Application and OS Images:** Amazon Linux 2023.
* Leave **Instance type:** `t3.micro`.
* Under **Key pair**, select `vockey`.
* Under **Security group**:
  * Choose **Select existing security group**.
  * Select `voting-proxy`.
* Expand **Advanced details**.
* Under **IAM instance profile** select `LabInstanceProfile`.
* Under **User data** (at the bottom of advanced) paste the contents of `deploy/userdata-nginx.sh`.
* Click **Launch instance**.


After the instance is running, associate your Elastic IP with the `voting-proxy` instance:

* In the EC2 console, open **Elastic IPs**.
* Select your Elastic IP.
* Under **Actions** select **Associate Elastic IP address**.
* Make sure **Resource type** is "Instance."
* Under **Instance** select the `voting-proxy` instance.
* Click **Associate**.
