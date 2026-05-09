"""
Dumps all six PostgreSQL databases to SQL files in database/dumps/.
Run from project root: python scripts/dump_databases.py
"""

import os
import sys
import subprocess

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from config.settings import DB_CONFIGS

PG_DUMP = r"C:\Program Files\PostgreSQL\16\bin\pg_dump.exe"
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "database", "dumps")

os.makedirs(OUT_DIR, exist_ok=True)

for db_name, cfg in DB_CONFIGS.items():
    out_file = os.path.join(OUT_DIR, f"{db_name}.sql")
    env = {**os.environ, "PGPASSWORD": cfg["password"]}

    print(f"Dumping {db_name} -> database/dumps/{db_name}.sql ... ", end="", flush=True)
    result = subprocess.run(
        [
            PG_DUMP,
            "--host",     cfg["host"],
            "--port",     str(cfg["port"]),
            "--username", cfg["user"],
            "--dbname",   cfg["dbname"],
            "--clean",
            "--if-exists",
            "--no-owner",
            "--no-acl",
            "--file",     out_file,
        ],
        env=env,
        capture_output=True,
        text=True,
    )
    if result.returncode == 0:
        size = os.path.getsize(out_file)
        print(f"OK ({size:,} bytes)")
    else:
        print(f"FAILED\n{result.stderr}")

print("\nDone. Files in database/dumps/")
