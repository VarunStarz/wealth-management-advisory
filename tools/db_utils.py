# ============================================================
# tools/db_utils.py
# PostgreSQL connection utility for all six source systems.
# Uses psycopg2 with RealDictCursor so rows return as dicts.
# ============================================================

import json
import logging
import psycopg2
import psycopg2.extras
from config.settings import DB_CONFIGS

logger = logging.getLogger(__name__)


def get_connection(db_name: str) -> psycopg2.extensions.connection:
    """
    Opens and returns a fresh psycopg2 connection to the named database.
    Uses RealDictCursor globally so every row is a plain Python dict.
    In production, replace with a connection pool (e.g. psycopg2.pool).
    """
    logger.debug("→ entering get_connection(db_name=%s)", db_name)
    cfg = DB_CONFIGS.get(db_name)
    if not cfg:
        raise ValueError(f"Unknown database name: '{db_name}'. "
                         f"Valid names: {list(DB_CONFIGS.keys())}")
    conn = psycopg2.connect(
        host=cfg["host"],
        port=cfg["port"],
        user=cfg["user"],
        password=cfg["password"],
        dbname=cfg["dbname"],
        cursor_factory=psycopg2.extras.RealDictCursor,
        connect_timeout=10,
    )
    conn.set_session(readonly=True, autocommit=True)
    logger.debug("← returning from get_connection(db_name=%s)", db_name)
    return conn


def query_db(db_name: str, sql: str, params: tuple = ()) -> list[dict]:
    """
    Executes a read-only parameterised query.
    psycopg2 uses %s placeholders (not ? like SQLite/MySQL).
    Returns a list of row dicts. Never raises — returns error dict on failure.
    """
    logger.debug("→ entering query_db(db=%s, sql=%.80s)", db_name, sql.strip())
    try:
        conn = get_connection(db_name)
        with conn.cursor() as cur:
            cur.execute(sql, params)
            rows = [dict(row) for row in cur.fetchall()]
        conn.close()
        logger.debug("← returning from query_db(db=%s) — %d row(s)", db_name, len(rows))
        return rows
    except psycopg2.OperationalError as e:
        logger.debug("← returning from query_db(db=%s) — connection error: %s", db_name, e)
        return [{"error": f"Connection failed to '{db_name}': {e}"}]
    except Exception as e:
        logger.debug("← returning from query_db(db=%s) — error: %s", db_name, e)
        return [{"error": str(e), "db": db_name}]


def query_one(db_name: str, sql: str, params: tuple = ()) -> dict | None:
    """Returns the first matching row as a dict, or None."""
    logger.debug("→ entering query_one(db=%s, sql=%.80s)", db_name, sql.strip())
    rows = query_db(db_name, sql, params)
    if rows and "error" not in rows[0]:
        logger.debug("← returning from query_one(db=%s) — found", db_name)
        return rows[0]
    logger.debug("← returning from query_one(db=%s) — None", db_name)
    return None


def to_json(data: list[dict] | dict) -> str:
    """Serialises query results to a JSON string for agent context."""
    return json.dumps(data, indent=2, default=str)
