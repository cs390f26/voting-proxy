# Polls

This is the Voting application. The **proxy** (nginx) is the only instance reachable from the internet: it has a public IP, receives HTTP, and forwards each request to one of two Flask servers (round-robin). The Flask servers and the database (DynamoDB Local) have no public IP.

Flask and the proxy find the other instances by calling `DescribeInstances` and looking for the tag `voting-role`. You never paste private IP addresses into user data.

SSH to a Flask server or the database goes through the proxy.

See the **specs** repository for the product specifications (use cases, API, data model, and related materials).


## Documentation

| Doc | Contents |
|-----|----------|
| [Development setup](docs/development.md) | Virtualenv, install, unit tests, lint, `.env`, DynamoDB Local, run the app, acceptance tests |
| [Deploy on EC2](docs/deploy-ec2.md) | Security groups, launch order, user data |
| [Design](docs/design.md) | Deployment layout, Flask layers, data types, package layout |


## Quick start (laptop)

- Create a virtual environment and install dependencies
- Configure `.env` from `config/example.env`
- Start DynamoDB Local and create the `Polls` table
- Run `python -m voting.app` and open [http://127.0.0.1:5000/](http://127.0.0.1:5000/)


See [Development setup](docs/development.md) for full steps.
