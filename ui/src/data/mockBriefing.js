const mockBriefing = {
  briefing_header: {
    client: "Arjun Ramesh Menon",
    customer_id: "CUST000001",
    segment: "HNI",
    relationship_manager: "RM001",
    date: "07 May 2026",
    prepared_by: "AI Advisory Intelligence Platform — for RM use only",
  },
  executive_summary:
    "Arjun Ramesh Menon is an active HNI client, customer since 2015, with a total AUM of Rs.1,25,00,000. The overall risk tier is LOW, with verified KYC, clear CDD, and excellent credit health. No immediate compliance escalation is required, but standard review must address a significant declared income discrepancy and severe portfolio concentration.",
  client_snapshot: {
    segment: "HNI",
    customer_since: "2015-06-01",
    aum_total_inr: "Rs.1,25,00,000",
    kyc_status: "VERIFIED",
    re_kyc_due: "2026-06-01",
    stated_risk_appetite: "MODERATE",
    investment_goal: "WEALTH_GROWTH",
    last_rm_review: "2024-01-10",
  },
  compliance_and_due_diligence: {
    cdd_status: "PASS",
    risk_score: 22.5,
    risk_tier: "LOW",
    red_flags_high: [
      {
        source: "INCOME",
        flag: "Significant income discrepancy: Lifestyle and spend patterns infer a minimum annual income of Rs.1,02,60,000, which exceeds the declared gross annual income of Rs.60,00,000 by 71.0%.",
      },
    ],
    caution_points_medium: [
      {
        source: "PORTFOLIO",
        flag: "Severe concentration risk: 82.00% of the Rs.1,25,00,000 portfolio is allocated to a single holding (Axis Bluechip Fund - Direct Growth), misaligned with the client's stated 'MODERATE' risk appetite.",
      },
      {
        source: "SYSTEM",
        flag: "Relationship maintenance gap: The annual CRM review is overdue by over a year (scheduled 2025-01-10), and PMS/DMS links are missing from the HNI profile.",
      },
      {
        source: "SYSTEM",
        flag: "Zero primary CBS account transactions over the last 3 months despite active EMI payments of Rs.85,000 on a Rs.98,00,000 home loan, indicating servicing from an undisclosed external account.",
      },
    ],
    recommended_compliance_action: "STANDARD_REVIEW",
    edd_summary: null,
  },
  income_validation: {
    declared_annual_gross_inr: "Rs.60,00,000",
    inferred_income_spend_signals_inr: "Rs.1,02,60,000",
    market_benchmark_p50_inr: "Rs.24,00,000",
    discrepancy_pct: "71.0%",
    discrepancy_status: "FLAGGED",
    signals: [
      "Lifestyle spend exceeds declared income by 71.0%.",
      "High lifestyle expenditure (monthly card spend of Rs.2,85,000) and home loan obligations (monthly EMI Rs.85,000) conflict with the declared net annual income of Rs.42,00,000.",
    ],
  },
  portfolio_summary: {
    total_aum_inr: "Rs.1,25,00,000",
    portfolio_count: 1,
    portfolios: [
      {
        name: "Arjun - Growth Portfolio",
        strategy: "GROWTH",
        aum_inr: "Rs.1,25,00,000",
        alpha: "0.33",
        sharpe: "1.85",
        status: "PERFORMING",
      },
    ],
    asset_allocation: {
      equity_pct: 18.0,
      debt_pct: 0.0,
      gold_pct: 0.0,
      cash_pct: 0.0,
      hybrid_pct: 82.0,
      other_pct: 0.0,
    },
    concentration_alerts: [
      "CONCENTRATION RISK: Single holding (Axis Bluechip Fund - Direct Growth) represents 82.00% of portfolio weight, heavily exceeding the 45% threshold.",
    ],
    suitability_notes:
      "The portfolio performs well against its Nifty 50 TRI benchmark with a positive alpha of 0.33 and a healthy Sharpe ratio of 1.85. However, 82% of assets are concentrated in a single hybrid fund — strategic diversification is strongly recommended to align with the client's stated MODERATE risk appetite.",
  },
  next_steps: [
    "Address portfolio concentration by advising a diversification strategy — move assets away from the single hybrid fund to align with the client's stated MODERATE risk appetite.",
    "Clarify the significant gap between inferred lifestyle spending and declared income; request updated ITR filings and external bank statements.",
    "Investigate the external bank account servicing the Rs.85,000 monthly home loan EMI and explore consolidation of banking flows internally.",
    "Complete the overdue annual CRM review and resolve missing PMS and DMS cross-links to construct a complete wealth profile.",
  ],
  disclaimer:
    "This briefing is AI-generated for Relationship Manager use only. It does not constitute investment advice, compliance clearance, or a product recommendation. All decisions remain with the RM and are subject to bank policy and regulatory guidelines.",
};

export default mockBriefing;
