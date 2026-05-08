"""
api_server.py
HTTP bridge between the React UI and the advisory pipeline.

Run with:
    python api_server.py           (port 8000, default)
    python api_server.py --port 8001
"""

import asyncio
import json
import os
import sys
import argparse

sys.path.insert(0, os.path.dirname(__file__))
sys.stdout.reconfigure(encoding="utf-8")

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from main import process_rm_query

app = FastAPI(title="Wealth Advisory Intelligence API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://127.0.0.1:5173"],
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)


class QueryRequest(BaseModel):
    query: str
    rm_id: str = "RM_USER"


@app.get("/api/health")
async def health():
    return {"status": "ok"}


@app.post("/api/query")
async def run_query(body: QueryRequest):
    result = await process_rm_query(body.query.strip(), body.rm_id.strip())
    try:
        parsed = json.loads(result)
        return parsed
    except (json.JSONDecodeError, TypeError):
        return {"error": True, "message": result}


if __name__ == "__main__":
    import uvicorn

    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8000)
    args = parser.parse_args()

    uvicorn.run("api_server:app", host="127.0.0.1", port=args.port, reload=False)
