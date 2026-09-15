"""Write /etc/nginx/nginx.conf from instances tagged voting-role=flask."""

from pathlib import Path

from tagged_private_ips import get_ips_for_role


def main() -> None:
    flask_ips = get_ips_for_role("flask", 2)
    servers = "\n".join(f"        server {ip}:5000;" for ip in flask_ips)
    template = Path("deploy/nginx.conf").read_text(encoding="utf-8")
    Path("/etc/nginx/nginx.conf").write_text(
        template.replace("UPSTREAM_SERVERS", servers),
        encoding="utf-8",
    )
    print("wrote /etc/nginx/nginx.conf")


if __name__ == "__main__":
    main()
