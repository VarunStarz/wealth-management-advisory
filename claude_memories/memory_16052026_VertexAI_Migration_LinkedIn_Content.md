# Session Memory — 16 May 2026: Vertex AI Migration + LinkedIn Content + Commit

## What Was Done

---

### 1. Vertex AI Migration (Gemini Developer API → Vertex AI)

**Files changed (comment-old, add-new pattern):**

| File | Change |
|---|---|
| `config/settings.py` | Commented `GOOGLE_API_KEY`; added `GOOGLE_CLOUD_PROJECT` + `GOOGLE_CLOUD_LOCATION` |
| `main.py` | Commented `GOOGLE_API_KEY` import + `os.environ` line; added `GOOGLE_GENAI_USE_VERTEXAI=1`, `GOOGLE_CLOUD_PROJECT`, `GOOGLE_CLOUD_LOCATION` |
| `requirements.txt` | Commented `google-generativeai>=0.8.0`; added `google-cloud-aiplatform>=1.60.0` |
| `.env` | Commented `GOOGLE_API_KEY`; added `GOOGLE_CLOUD_PROJECT` + `GOOGLE_CLOUD_LOCATION` |
| `.env.example` | Same as `.env` |

**GCP project ID set by user:** `project-15058b99-a2c0-4a75-8be`
**Region:** `us-central1`
**Auth:** `gcloud auth application-default login` already done by user before session.

**Error encountered:** `gemini-3.1-pro-preview` returned 404 NOT_FOUND on Vertex AI.
**Fix:** Switched active model to `gemini-2.5-pro` (was already a commented option in `settings.py`).

```python
# config/settings.py
#GEMINI_MODEL   = "gemini-3-pro-preview"
#GEMINI_MODEL   = "gemini-3.1-pro-preview"   ← commented out
GEMINI_MODEL   = "gemini-2.5-pro"            ← now active
```

**Warning (non-blocking):** `quota project not set` — fix: `gcloud auth application-default set-quota-project <PROJECT_ID>`. gcloud was not available on the user's PATH during session.

---

### 2. Google ADK Class Hierarchy Explained

- `Agent` = `LlmAgent` — same class, just an alias. All 13 agents correctly use this.
- `BaseAgent` — abstract, no LLM. For non-LLM agents only.
- `SequentialAgent`, `ParallelAgent`, `LoopAgent` — ADK orchestration primitives not used; custom orchestration in `main.py` provides conditional branching + scope-driven routing which these primitives can't express easily.

---

### 3. Prompt Caching Discussion

**Decision:** NOT implemented. Reason: Google ADK's `Agent` class abstracts raw Gemini API calls — you cannot pass a `CachedContent` reference without bypassing ADK internals.

**Token estimates derived from reading agent files:**
- `report_generation_agent` instruction: ~3,200 tokens (largest — includes full JSON schema)
- `client_360_agent` instruction: ~1,000 tokens
- `cdd_agent` instruction: ~475 tokens (below 1,024 token cache threshold on its own)
- Total across all 13 agents: ~12,000–14,000 tokens per pipeline run
- Parallel burst in FULL_BRIEFING (6 agents): ~8,000 tokens of static instructions simultaneously

**LinkedIn post drafted** (not published): framed around the problem of re-processing static agent instructions on every call, the caching solution, and the broader lesson for multi-agent systems. Token numbers included to make it concrete.

---

### 4. Report_Contents File Created

`Report_Contents/Entity_Resolution_JaroWinkler.txt` — documents the Jaro-Winkler probabilistic entity resolution engine: problem statement, algorithm steps, blocking strategy, weight tables, confidence tiers, LLM arbitration, verified scores, and rationale.

---

### 5. Business Problems List Compiled

Documented 7 business problems + 6 implementation bugs with business impact from the full project history. Key business problems:
1. Client identity fragmented across 6 systems → Jaro-Winkler + LLM arbitration
2. Guardrail blocking legitimate wealth advisory → WEALTH_RECOMMENDATION pipeline type
3. Compliance risk tier conflated with investment risk preference → separated cleanly
4. Fund performance fetch too slow → fund_performance_cache (24hr TTL)
5. External APIs unreliable → hardcoded fallbacks for all 6 APIs
6. Employer stability had no objective signal → NSE EQUITY_L.csv lookup
7. No inflation-adjusted portfolio view → World Bank CPI + IMF GDP integration

---

### 6. Git Commit + Push

**Commit:** `cd48011` — "Add Wealth Recommendation, Entity Resolution, and Vertex AI migration"
**30 files changed, 6,096 insertions, 251 deletions**
**Pushed to:** `https://github.com/VarunStarz/wealth-management-advisory.git` (main)

**Excluded from commit (per user instruction):**
- `claude_memories/`
- `Report_Contents/`
- `Plans_ToDo/`
- `scripts/.pids`

---

## Key Decisions / Rules This Session

- **Comment, don't replace** — user's explicit instruction for Vertex AI migration. Old lines commented, new lines added below. Apply this pattern for future migrations/changes.
- `Report_Contents/` folder purpose: one .txt file per unique technical decision/feature. Style matches `External_REST_APIs.txt`.
- `claude_memories/`, `Report_Contents/`, `Plans_ToDo/` are never committed to git.
