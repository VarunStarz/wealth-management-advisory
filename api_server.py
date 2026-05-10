"""
api_server.py — FastAPI bridge for the Wealth Advisory Intelligence Platform

Endpoints:
  GET  /api/health            Health check
  GET  /api/scenarios         List all 17 test scenarios
  POST /api/query             Run a free-form RM query
  POST /api/scenario/{n}      Run a numbered test scenario directly

Run:
    python api_server.py              # http://127.0.0.1:8000
    python api_server.py --port 8001
    python api_server.py --host 0.0.0.0 --port 8000   # expose on LAN

Swagger UI: http://localhost:8000/docs
"""

import json
import os
import sys
import argparse

sys.path.insert(0, os.path.dirname(__file__))
sys.stdout.reconfigure(encoding="utf-8")

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, field_validator

from main import process_rm_query, SCENARIOS

# ── App setup ─────────────────────────────────────────────────
app = FastAPI(
    title="Wealth Advisory Intelligence API",
    version="1.0.0",
    description="Multi-agent advisory pipeline for wealth management RMs.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://127.0.0.1:5173"],
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)


# ── Request / Response models ─────────────────────────────────
class QueryRequest(BaseModel):
    query: str
    rm_id: str = "RM_USER"
    risk_preference: str = "MEDIUM"

    @field_validator("query")
    @classmethod
    def query_not_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("query cannot be empty")
        return v.strip()

    @field_validator("rm_id")
    @classmethod
    def rm_id_strip(cls, v: str) -> str:
        return v.strip() or "RM_USER"

    @field_validator("risk_preference")
    @classmethod
    def risk_preference_valid(cls, v: str) -> str:
        valid = {"NO_RISK", "LOW", "MEDIUM", "HIGH"}
        return v.upper() if v.upper() in valid else "MEDIUM"


class ScenarioItem(BaseModel):
    id: int
    label: str
    rm_id: str
    query: str
    blocked: bool


# ── Helpers ───────────────────────────────────────────────────
def _parse_pipeline_result(result: str) -> dict:
    """Parse the string returned by process_rm_query into a dict."""
    try:
        return json.loads(result)
    except (json.JSONDecodeError, TypeError):
        return {"error": True, "message": result}


# ── Routes ────────────────────────────────────────────────────
@app.get("/api/health", tags=["System"])
async def health():
    """Returns OK if the server is running."""
    return {"status": "ok"}


@app.get("/api/scenarios", response_model=list[ScenarioItem], tags=["Scenarios"])
async def list_scenarios():
    """Returns all 17 test scenarios with their id, label, rm_id, and query text."""
    return [
        ScenarioItem(
            id=n,
            label=s["label"],
            rm_id=s["rm_id"],
            query=s["query"],
            blocked="BLOCKED" in s["label"],
        )
        for n, s in SCENARIOS.items()
    ]


@app.post("/api/query", tags=["Pipeline"])
async def run_query(body: QueryRequest):
    """
    Runs the full advisory pipeline for a free-form RM query.
    Returns the structured JSON briefing (or a blocked/compliance-block response).
    """
    result = await process_rm_query(body.query, body.rm_id, body.risk_preference)
    return _parse_pipeline_result(result)


@app.post("/api/scenario/{n}", tags=["Pipeline"])
async def run_scenario(n: int):
    """
    Runs one of the 17 numbered test scenarios by ID.
    Returns the same structured JSON briefing as /api/query.
    """
    scenario = SCENARIOS.get(n)
    if not scenario:
        raise HTTPException(
            status_code=404,
            detail=f"Scenario {n} not found. Valid range: 1–{max(SCENARIOS)}.",
        )
    result = await process_rm_query(scenario["query"], scenario["rm_id"])
    return _parse_pipeline_result(result)


# ── Entry point ───────────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn

    parser = argparse.ArgumentParser(description="Wealth Advisory Intelligence API server")
    parser.add_argument("--host", default="127.0.0.1", help="Bind host (default: 127.0.0.1)")
    parser.add_argument("--port", type=int, default=8000, help="Bind port (default: 8000)")
    args = parser.parse_args()

    print("\n" + "=" * 56)
    print("  Wealth Advisory Intelligence API")
    print(f"  http://{args.host}:{args.port}")
    print(f"  Swagger docs → http://{args.host}:{args.port}/docs")
    print("=" * 56 + "\n")

    uvicorn.run("api_server:app", host=args.host, port=args.port, reload=False)
