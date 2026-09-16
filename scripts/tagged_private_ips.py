"""Look up private IPs of running EC2 instances by voting-role tag."""

import time

import boto3

# LabInstanceProfile gives credentials, not a region. Amazon Linux does not
# set AWS_DEFAULT_REGION. Learner Lab is us-east-1.
ec2 = boto3.client("ec2", region_name="us-east-1")


def get_ips_for_role(role: str, number: int) -> list[str]:
    """Return private IPs of running instances tagged voting-role=<role>.

    Polls until `number` matching addresses exist. Raises RuntimeError if more
    than `number` instances match. Raises TimeoutError if `number` addresses
    do not appear in time.
    """
    timeout_seconds = 600
    deadline = time.monotonic() + timeout_seconds
    while time.monotonic() < deadline:
        response = ec2.describe_instances(
            Filters=[
                {"Name": "tag:voting-role", "Values": [role]},
                {"Name": "instance-state-name", "Values": ["running"]},
            ]
        )
        instances = [
            instance
            for reservation in response["Reservations"]
            for instance in reservation["Instances"]
        ]
        if len(instances) < number:
            print(f"have {len(instances)} {role}; need {number}", flush=True)
            time.sleep(5)
            continue
        if len(instances) > number:
            raise RuntimeError(f"{len(instances)} {role} instances; expected {number}")
        return [instance.get("PrivateIpAddress") for instance in instances]
    raise TimeoutError(f"timed out waiting for {number} {role}")
