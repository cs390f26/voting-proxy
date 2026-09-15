"""Write .env from the instance tagged voting-role=db."""

from pathlib import Path

from tagged_private_ips import get_ips_for_role


def main() -> None:
    db_ip = get_ips_for_role("db", 1)[0]
    example = Path("config/example.env").read_text(encoding="utf-8")
    Path(".env").write_text(
        example.replace(
            "DYNAMODB_ENDPOINT_URL=http://localhost:8000",
            f"DYNAMODB_ENDPOINT_URL=http://{db_ip}:8000",
        ),
        encoding="utf-8",
    )
    print("Wrote .env")


if __name__ == "__main__":
    main()
