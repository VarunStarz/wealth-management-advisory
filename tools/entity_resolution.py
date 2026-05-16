"""
Multi-Attribute Probabilistic Entity Resolution Engine.

For each of the three external systems (KYC, Card, DMS) that no longer carry
customer_id, this module:
  1. Retrieves candidate records via three independent blocking keys
     (PAN exact, DOB exact for KYC, first-word name ILIKE).
  2. Scores each candidate with weighted Jaro-Winkler similarity.
  3. Assigns a resolution tier: CONFIRMED / AMBIGUOUS / NOT_FOUND.

CRM and PMS remain deterministic lookups (PAN for CRM, CRM client_id for PMS).
"""

import logging
from tools.db_utils import query_db, query_one

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Jaro-Winkler similarity (pure Python, no external dependency)
# ---------------------------------------------------------------------------

def _jaro(s1: str, s2: str) -> float:
    if s1 == s2:
        return 1.0
    len1, len2 = len(s1), len(s2)
    if len1 == 0 or len2 == 0:
        return 0.0

    match_dist = max(len1, len2) // 2 - 1
    if match_dist < 0:
        match_dist = 0

    s1_matches = [False] * len1
    s2_matches = [False] * len2
    matches = 0
    transpositions = 0

    for i in range(len1):
        lo = max(0, i - match_dist)
        hi = min(i + match_dist + 1, len2)
        for j in range(lo, hi):
            if s2_matches[j] or s1[i] != s2[j]:
                continue
            s1_matches[i] = True
            s2_matches[j] = True
            matches += 1
            break

    if matches == 0:
        return 0.0

    k = 0
    for i in range(len1):
        if not s1_matches[i]:
            continue
        while not s2_matches[k]:
            k += 1
        if s1[i] != s2[k]:
            transpositions += 1
        k += 1

    jaro = (matches / len1 + matches / len2 + (matches - transpositions / 2) / matches) / 3
    return jaro


def _jaro_winkler(s1: str, s2: str, p: float = 0.1) -> float:
    """
    Jaro-Winkler similarity in [0, 1].
    Inputs are uppercased and stripped before comparison.
    """
    s1 = s1.upper().strip()
    s2 = s2.upper().strip()
    if s1 == s2:
        return 1.0
    jaro = _jaro(s1, s2)
    prefix = 0
    for c1, c2 in zip(s1, s2):
        if c1 == c2:
            prefix += 1
        else:
            break
        if prefix == 4:
            break
    return jaro + prefix * p * (1 - jaro)


# ---------------------------------------------------------------------------
# Resolution tiers
# ---------------------------------------------------------------------------

CONFIRMED  = "CONFIRMED"    # score >= 0.75  — auto-accept
AMBIGUOUS  = "AMBIGUOUS"    # 0.30 <= score < 0.75 — LLM arbitrates
NOT_FOUND  = "NOT_FOUND"    # score < 0.30


def _tier(score: float) -> str:
    if score >= 0.75:
        return CONFIRMED
    if score >= 0.30:
        return AMBIGUOUS
    return NOT_FOUND


# ---------------------------------------------------------------------------
# Candidate retrieval — blocking strategy per system
# ---------------------------------------------------------------------------

def _candidates_kyc(cbs_pan: str | None, cbs_name: str | None, cbs_dob) -> list[dict]:
    """
    Three blocking keys for KYC (union-deduplicated by kyc_id):
      Block 1: PAN exact
      Block 2: DOB exact
      Block 3: First word of name ILIKE
    """
    SELECT = """
        SELECT kyc_id, registered_name, dob, pan_number,
               kyc_status, kyc_tier, re_kyc_due, notes
        FROM   kyc_master
    """
    candidates: dict[str, dict] = {}

    if cbs_pan:
        row = query_one("kyc", SELECT + "WHERE pan_number = %s", (cbs_pan,))
        if row and "error" not in row:
            candidates[row["kyc_id"]] = row

    if cbs_dob:
        rows = query_db("kyc", SELECT + "WHERE dob = %s", (cbs_dob,))
        for row in rows:
            if "error" not in row:
                candidates.setdefault(row["kyc_id"], row)

    first_word = cbs_name.split()[0] if cbs_name else None
    if first_word:
        rows = query_db(
            "kyc",
            SELECT + "WHERE UPPER(registered_name) LIKE UPPER(%s)",
            (f"{first_word}%",),
        )
        for row in rows:
            if "error" not in row:
                candidates.setdefault(row["kyc_id"], row)

    return list(candidates.values())


def _candidates_card(cbs_pan: str | None, cbs_name: str | None) -> list[dict]:
    """
    Three blocking keys for Card (union-deduplicated by card_id):
      Block 1: PAN exact
      Block 2: First word of CBS name ILIKE (catches normal full names)
      Block 3: Last word of CBS name ILIKE (catches abbreviated names like "P.S. IYER")
    """
    SELECT = """
        SELECT card_id, cardholder_name, pan_number,
               card_type, card_status, credit_limit, current_balance,
               available_limit, payment_due_date, issue_date
        FROM   card_accounts
    """
    candidates: dict[str, dict] = {}

    if cbs_pan:
        row = query_one("card", SELECT + "WHERE pan_number = %s", (cbs_pan,))
        if row and "error" not in row:
            candidates[row["card_id"]] = row

    name_words = cbs_name.split() if cbs_name else []
    words_to_block = set()
    if name_words:
        words_to_block.add(name_words[0])   # first word (given name)
        if len(name_words) > 1:
            words_to_block.add(name_words[-1])  # last word (surname)

    for word in words_to_block:
        rows = query_db(
            "card",
            SELECT + "WHERE UPPER(cardholder_name) LIKE UPPER(%s)",
            (f"%{word}%",),
        )
        for row in rows:
            if "error" not in row:
                candidates.setdefault(row["card_id"], row)

    return list(candidates.values())


def _candidates_dms(cbs_pan: str | None, cbs_name: str | None) -> list[dict]:
    """
    Three blocking keys for DMS (union-deduplicated by dms_id):
      Block 1: PAN exact
      Block 2: First word of CBS name ILIKE (catches normal full names)
      Block 3: Last word of CBS name ILIKE (catches missing-middle-name variants)
    """
    SELECT = """
        SELECT dms_id, applicant_name, pan_number,
               doc_category, doc_type, file_name, upload_date, access_level
        FROM   document_repository
    """
    candidates: dict[str, dict] = {}

    if cbs_pan:
        rows = query_db("dms", SELECT + "WHERE pan_number = %s", (cbs_pan,))
        for row in rows:
            if "error" not in row:
                candidates[row["dms_id"]] = row

    name_words = cbs_name.split() if cbs_name else []
    words_to_block = set()
    if name_words:
        words_to_block.add(name_words[0])
        if len(name_words) > 1:
            words_to_block.add(name_words[-1])

    for word in words_to_block:
        rows = query_db(
            "dms",
            SELECT + "WHERE UPPER(applicant_name) LIKE UPPER(%s)",
            (f"%{word}%",),
        )
        for row in rows:
            if "error" not in row:
                candidates.setdefault(row["dms_id"], row)

    return list(candidates.values())


# ---------------------------------------------------------------------------
# Scoring — per system
# ---------------------------------------------------------------------------

def _score_kyc(record: dict, cbs_pan: str | None, cbs_name: str | None, cbs_dob) -> tuple[float, list[str]]:
    """
    KYC attribute weights:
      pan_number exact        +0.45
      registered_name JW>=0.90 +0.35
      registered_name JW 0.70-0.89 +0.18
      registered_name JW 0.55-0.69 +0.08
      dob exact               +0.20
      dob month/day transposed +0.08
    """
    score = 0.0
    matched: list[str] = []

    rec_pan  = record.get("pan_number")
    rec_name = record.get("registered_name") or ""
    rec_dob  = record.get("dob")

    if cbs_pan and rec_pan and cbs_pan == rec_pan:
        score += 0.45
        matched.append("pan_exact")

    if cbs_name and rec_name:
        jw = _jaro_winkler(cbs_name, rec_name)
        if jw >= 0.90:
            score += 0.35
            matched.append(f"name_high({jw:.2f})")
        elif jw >= 0.70:
            score += 0.18
            matched.append(f"name_mid({jw:.2f})")
        elif jw >= 0.55:
            score += 0.08
            matched.append(f"name_low({jw:.2f})")

    if cbs_dob and rec_dob:
        cbs_str = str(cbs_dob)   # "YYYY-MM-DD"
        rec_str = str(rec_dob)
        if cbs_str == rec_str:
            score += 0.20
            matched.append("dob_exact")
        else:
            # Check month/day transposition: 1990-07-15 vs 1990-15-07
            cbs_parts = cbs_str.split("-")
            rec_parts = rec_str.split("-")
            if (len(cbs_parts) == 3 and len(rec_parts) == 3
                    and cbs_parts[0] == rec_parts[0]
                    and cbs_parts[1] == rec_parts[2]
                    and cbs_parts[2] == rec_parts[1]):
                score += 0.08
                matched.append("dob_transposed")

    return score, matched


def _score_card(record: dict, cbs_pan: str | None, cbs_name: str | None) -> tuple[float, list[str]]:
    """
    Card attribute weights (no DOB on card, so name carries more weight):
      pan_number exact              +0.55
      cardholder_name JW>=0.90      +0.45
      cardholder_name JW 0.70-0.89  +0.32  (higher than KYC mid because card has no DOB)
      cardholder_name JW 0.50-0.69  +0.16
    """
    score = 0.0
    matched: list[str] = []

    rec_pan  = record.get("pan_number")
    rec_name = record.get("cardholder_name") or ""

    if cbs_pan and rec_pan and cbs_pan == rec_pan:
        score += 0.55
        matched.append("pan_exact")

    if cbs_name and rec_name:
        jw = _jaro_winkler(cbs_name, rec_name)
        if jw >= 0.90:
            score += 0.45
            matched.append(f"name_high({jw:.2f})")
        elif jw >= 0.70:
            score += 0.32
            matched.append(f"name_mid({jw:.2f})")
        elif jw >= 0.50:
            score += 0.16
            matched.append(f"name_partial({jw:.2f})")

    return score, matched


def _score_dms(record: dict, cbs_pan: str | None, cbs_name: str | None) -> tuple[float, list[str]]:
    """
    DMS weights (no DOB on DMS documents, name carries more weight):
      pan_number exact              +0.55
      applicant_name JW>=0.90       +0.45
      applicant_name JW 0.70-0.89   +0.32
      applicant_name JW 0.50-0.69   +0.16
    """
    score = 0.0
    matched: list[str] = []

    rec_pan  = record.get("pan_number")
    rec_name = record.get("applicant_name") or ""

    if cbs_pan and rec_pan and cbs_pan == rec_pan:
        score += 0.55
        matched.append("pan_exact")

    if cbs_name and rec_name:
        jw = _jaro_winkler(cbs_name, rec_name)
        if jw >= 0.90:
            score += 0.45
            matched.append(f"name_high({jw:.2f})")
        elif jw >= 0.70:
            score += 0.32
            matched.append(f"name_mid({jw:.2f})")
        elif jw >= 0.50:
            score += 0.16
            matched.append(f"name_partial({jw:.2f})")

    return score, matched


# ---------------------------------------------------------------------------
# Build per-system result block
# ---------------------------------------------------------------------------

def _resolve_system(candidates: list[dict], score_fn, label: str) -> dict:
    """
    Scores all candidates, picks the best, returns the system result block.
    """
    if not candidates:
        return {"candidates": [], "best_candidate": None, "best_score": 0.0, "resolution_tier": NOT_FOUND}

    scored = []
    for rec in candidates:
        score, matched = score_fn(rec)
        scored.append({
            "record": rec,
            "similarity_score": round(score, 4),
            "matched_attributes": matched,
            "resolution_tier": _tier(score),
        })

    scored.sort(key=lambda x: x["similarity_score"], reverse=True)
    best = scored[0]

    return {
        "candidates": scored,
        "best_candidate": best["record"],
        "best_score": best["similarity_score"],
        "resolution_tier": best["resolution_tier"],
    }


# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------

def resolve_identity(customer_id: str) -> dict:
    """
    Resolves a CBS customer_id against all six source systems.

    Returns a structured dict with:
      cbs_anchor — the CBS customer record (the ground truth anchor)
      crm        — deterministic PAN lookup (CONFIRMED or NOT_FOUND)
      kyc        — probabilistic: candidate pool + best match + tier
      card       — probabilistic: candidate pool + best match + tier
      dms        — probabilistic: candidate pool + best match + tier (may have multiple DMS records per customer)
      pms        — deterministic via CRM client_id
    """
    logger.debug("resolve_identity(%s)", customer_id)

    # ── 1. CBS anchor ─────────────────────────────────────────────────────────
    cbs_row = query_one(
        "cbs",
        """SELECT customer_id, full_name, pan_number, dob, mobile, email,
                  gender, nationality, aadhaar_ref,
                  relationship_manager_id, segment_code, status, created_at
           FROM   customer_master
           WHERE  customer_id = %s""",
        (customer_id,),
    )

    if not cbs_row or "error" in cbs_row:
        return {"error": f"CBS customer not found: {customer_id}"}

    cbs_pan  = cbs_row.get("pan_number")
    cbs_name = cbs_row.get("full_name")
    cbs_dob  = cbs_row.get("dob") or cbs_row.get("date_of_birth")

    # ── 2. CRM — deterministic PAN lookup ────────────────────────────────────
    crm_row = query_one(
        "crm",
        """SELECT client_id, pan_number, segment, sub_segment, rm_id,
                  onboarding_date, investment_experience, risk_appetite_stated,
                  preferred_language, aum_band, last_review_date, next_review_date
           FROM   client_profile
           WHERE  pan_number = %s""",
        (cbs_pan,),
    ) if cbs_pan else None

    if crm_row and "error" not in crm_row:
        crm_result = {"matched": crm_row, "method": "PAN_EXACT", "confidence": 1.0}
    else:
        crm_result = {"matched": None, "method": "NOT_FOUND", "confidence": 0.0}

    # ── 3. PMS — deterministic via CRM client_id ─────────────────────────────
    crm_client_id = crm_row.get("client_id") if (crm_row and "error" not in crm_row) else None
    pms_row = query_one(
        "pms",
        """SELECT portfolio_id, client_id, portfolio_name, strategy_type,
                  benchmark_id, inception_date, base_currency, aum, status, managed_by
           FROM   portfolio_master
           WHERE  client_id = %s""",
        (crm_client_id,),
    ) if crm_client_id else None

    if pms_row and "error" not in pms_row:
        pms_result = {"matched": pms_row, "method": "CRM_CLIENT_ID", "confidence": 1.0}
    else:
        pms_result = {"matched": None, "method": "NOT_FOUND", "confidence": 0.0}

    # ── 4. KYC — probabilistic ────────────────────────────────────────────────
    kyc_candidates = _candidates_kyc(cbs_pan, cbs_name, cbs_dob)
    kyc_result = _resolve_system(
        kyc_candidates,
        lambda rec: _score_kyc(rec, cbs_pan, cbs_name, cbs_dob),
        "kyc",
    )

    # ── 5. Card — probabilistic ───────────────────────────────────────────────
    card_candidates = _candidates_card(cbs_pan, cbs_name)
    card_result = _resolve_system(
        card_candidates,
        lambda rec: _score_card(rec, cbs_pan, cbs_name),
        "card",
    )

    # ── 6. DMS — probabilistic (customer may have multiple DMS documents) ─────
    dms_candidates = _candidates_dms(cbs_pan, cbs_name)
    dms_result = _resolve_system(
        dms_candidates,
        lambda rec: _score_dms(rec, cbs_pan, cbs_name),
        "dms",
    )

    return {
        "cbs_anchor": dict(cbs_row),
        "crm":        crm_result,
        "kyc":        kyc_result,
        "card":       card_result,
        "dms":        dms_result,
        "pms":        pms_result,
    }
