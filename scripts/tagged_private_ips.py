"""Look up private IPs of running EC2 instances by voting-role tag."""

import time

import boto3

# LabInstanceProfile gives credentials, not a region. Amazon Linux does not
# set AWS_DEFAULT_REGION. Learner Lab is us-east-1.
ec2 = boto3.client("ec2", region_name="us-east-1")


def get_ips_for_role(role: str, number: int) -> list[str]:
    """Return private IPs of running instances tagged voting-role=<role>.

    All matching instances must come from a single reservation (one launch).
    Polls until that reservation has `number` addresses. Raises RuntimeError
    if more than one reservation matches. Raises TimeoutError if `number`
    addresses do not appear in time.
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
        reservations = response["Reservations"]
        if not reservations or len(reservations[0]["Instances"]) < number:
            have = 0 if not reservations else len(reservations[0]["Instances"])
            print(f"have {have} {role}; need {number}", flush=True)
            time.sleep(5)
            continue
        if len(reservations) > 1:
            raise RuntimeError(f"extra launch tagged {role}; terminate leftovers")
        if len(reservations[0]["Instances"]) > number:
            n = len(reservations[0]["Instances"])
            raise RuntimeError(f"{n} {role} instances; expected {number}")
        return [
            instance.get("PrivateIpAddress")
            for instance in reservations[0]["Instances"]
        ]
    raise TimeoutError(f"timed out waiting for {number} {role}")

