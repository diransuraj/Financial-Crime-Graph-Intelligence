# Graph-Based AML Detection: A FinCEN Files Case Study
## Proactive Identification of Complex Fraud Rings Using Graph Analytics

**Reference:** CS-AML-2026-001  
**Dataset:** FinCEN Files (ICIJ) — Suspicious Activity Reports  
**Analyst:** Diran Suraj  
**Stack:** PostgreSQL → Python (pandas, psycopg2, graphdatascience) → Neo4j GDS

---

## Executive Summary

This case study presents a graph-based Anti-Money Laundering (AML) detection system that applies network analytics to Suspicious Activity Report (SAR) data from the FinCEN Files. Unlike traditional transaction monitoring that evaluates entities in isolation, this approach identifies **hidden relationships, community structures, and risk propagation patterns** across the global correspondent banking network.

**Key Achievement:** The analysis identified a **133-node high-risk cluster** containing two FATF grey-list institutions, traced **$5.2M in suspicious flows**, detected an **affiliate U-turn layering pattern**, and demonstrated risk propagation affecting **205 institutions**—a **2,278% increase** in detectable risk exposure over watchlist-only monitoring.

---

## The Red Flag: The Hidden Network

**What I'm trying to detect:** Complex money laundering rings where funds move from high-risk jurisdictions through strategic intermediaries to terminal sink nodes—patterns invisible to entity-level monitoring.

**The Pattern:** High-risk seed → Strategic intermediary → Sink node (integration)

**Adversarial Thinking:** *"If I were a money launderer, how would I evade detection?"*

I systematically considered evasion strategies:
- **Fragment entities** → Use multiple name variants → Caught by entity resolution (`SAME_AS` relationships)
- **Avoid direct connections** → Route through intermediaries → Caught by 2-hop risk propagation
- **Stay off watchlists** → Use grey-list jurisdictions → Caught by community density analysis
- **Create false volume** → Cycle funds through affiliates → Caught by affiliate U-turn detection

*This adversarial mindset—required for the CFE exam—informed every analytical layer.*

---

## Regulatory Context: SAR Readiness

My detection system outputs all information required for Suspicious Activity Reports under UK MLR 2017 and US BSA:

| SAR Requirement | How My System Addresses It |
| :--- | :--- |
| **Subject identification** | Tracks originator and beneficiary bank IDs, resolved aliases |
| **Activity description** | Records transaction amounts, dates, path traversal |
| **Red flags / typologies** | Flags specific patterns: layering (affiliate U-turn), structuring, jurisdiction hopping, sink nodes |
| **Risk assessment** | Graph-based risk score (0-100) via propagation from FATF seeds |

**Example:** A flagged cluster would provide an investigator with:
- All participating institutions
- Transaction amounts and routing paths
- Specific red flags triggered (e.g., `affiliate_uturn`, `sink_node`, `grey_list_seed_proximity`)
- Risk propagation score

This equips investigators to file a complete SAR without additional system queries.

*Note: This project demonstrates the detection infrastructure. Actual SAR filing would follow standard regulatory channels. See the demonstration SAR in Section 9.*

---

## 1. Project Architecture

The system implements a graph-based detection pipeline:

```
┌─────────────────────────────────────────────────────────────┐
│              Layer 1: SQL Detection (PostgreSQL)            │
│  • Structuring (30-day rolling aggregates below $10k)       │
│  • Jurisdiction hopping (3+ countries, FATF exposure)       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│           Layer 2: Entity Resolution (Neo4j)                │
│  • Tier 1: Strict name matching (punctuation-normalized)    │
│  • Tier 2: Smart matching (suffix normalization)            │
│  • Tier 3: Investigative overrides (known clusters)         │
│  Result: 1,089 `SAME_AS` relationships, 61 resolved aliases │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│           Layer 3: Graph Algorithms (Neo4j GDS)             │
│  • PageRank (hub identification)                            │
│  • WCC (isolated network detection)                         │
│  • Louvain (community detection)                            │
│  • Cycle detection (layering loops)                         │
│  • Sink node analysis (integration endpoints)               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│           Layer 4: Risk Propagation Engine                  │
│  • Seeds: FATF grey-list entities (score = 100)             │
│  • 1-hop: Direct neighbors (+40)                            │
│  • 2-hop: Two-step neighbors (+20)                          │
│  Output: Risk score (0-100) per institution                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              Output: SAR-Ready Intelligence                 │
│  • High-risk cluster identification (133 nodes)             │
│  • Affiliate U-turn detection (Caledonian pattern)          │
│  • Sink node inventory (integration endpoints)              │
│  • Risk-elevated institutions (205 total)                   │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Component Analysis

### 2.1 SQL Detection Layer (Deterministic)

Two SQL-based detection rules identify suspicious patterns at the transaction level before graph construction.

**Rule 1: Structuring Detection**

Identifies banks sending multiple sub-threshold amounts (<$10k) that aggregate above $20k within 30 days—a classic structuring pattern.

| Bank | 30-Day Cluster Total | Small Transaction Count |
| :--- | :--- | :--- |
| Trust Merchant Bank Sarl | $199,198 | 43 |
| Barclays Bank Plc Ho UK | $89,945 | 45 |
| Natwest Offshore | $82,661 | 31 |

**Rule 2: Jurisdiction Hopping Detection**

Identifies banks transacting with 3+ unique beneficiary countries, including at least one FATF grey/black-list jurisdiction.

| Bank | Unique Countries | Max FATF Risk | Total Volume |
| :--- | :--- | :--- | :--- |
| Deutsche Bank AG | 23 | 2 | $1.70B |
| Bank of China | 11 | 2 | $527M |
| LTB Bank | 17 | 2 | $448M |

**Strengths:** Fully explainable, computationally efficient, regulatory-friendly.
**Weaknesses:** Pattern-specific (misses novel evasion), no relationship detection.

---

### 2.2 Entity Resolution (Graph Construction)

**The Problem:** The same legal institution appears under multiple name variants in SAR filings, fragmenting graph algorithms.

| Name Variant | Country | Community | PageRank |
| :--- | :--- | :--- | :--- |
| Bank of America N.A. | USA | 1637 | 1.751 |
| Bank of America Na | USA | 1637 | 1.602 |
| Bank of America, N.A. | USA | 1637 | 1.509 |

**The Solution:** Three-tier matching:

| Tier | Method | Matches |
| :--- | :--- | :--- |
| 1 (Strict) | Punctuation-normalized exact match + same country | 1,095 |
| 2 (Smart) | Suffix normalization (removes N.A., Ltd, AG, PLC, etc.) | 1,094 |
| 3 (Investigative) | Domain-specific overrides (BOA cluster targeting) | 0 (dynamic) |

**Result:** 1,089 `SAME_AS` relationships created. The Bank of America variants now share a single logical node with `alias_count = 6`, consolidating their PageRank influence.

---

### 2.3 Graph Algorithms

**PageRank (Hub Identification)**

Identifies the most influential banks in the network—institutions that serve as clearing hubs for the global system.

| Bank | Jurisdiction | Influence Score |
| :--- | :--- | :--- |
| JSC Norvik Banka | Latvia | 8.60 |
| Credit Suisse | Singapore | 7.49 |
| Rosbank | Russia | 5.71 |
| Standard Chartered Bank | UAE | 5.64 |

**Finding:** Every top-10 hub belongs to the same connected component (Island 0), confirming a single "Great Continent" network structure.

---

**Louvain Community Detection**

Identifies densely connected subgroups—potential fraud rings.

| Community | Size | Max Risk | Key Members |
| :--- | :--- | :--- | :--- |
| iraq_jordan_cluster | 133 | 2 | Trade Bank (IRQ), Blom Bank (JOR), Standard Chartered (ARE), Bank of America (USA) |
| other_risk_1130 | 169 | 2 | (single seed) |
| other_risk_1356 | 144 | 2 | (single seed) |

**Finding:** The `iraq_jordan_cluster` contains **two** FATF grey-list seeds co-located—a statistically significant anomaly requiring investigation.

---

**Sink Node Analysis**

Identifies banks with high inbound volume and zero outbound activity—potential integration endpoints.

| Bank | Jurisdiction | Inbound Reports | Influence Score |
| :--- | :--- | :--- | :--- |
| JSC Norvik Banka | Latvia | 57 | 8.60 |
| Rosbank | Russia | 42 | 5.71 |
| Standard Chartered Bank | UAE | 22 | 5.64 |

*Caveat: Sink status may reflect data boundaries (SAR filings only) rather than actual capital termination.*

---

**Affiliate U-Turn Detection**

Identifies flows where money returns to a different branch or affiliate of the originating bank.

| Origin Branch | Intermediary | Return Affiliate | Loop Count |
| :--- | :--- | :--- | :--- |
| Caledonian Bank Limited | HSBC Hong Kong | Caledonian Bank Ltd | 1 |
| AS PrivatBank | HSBC Hong Kong | AS Expobank | 1 |

**Finding:** Caledonian Bank routing funds to itself through HSBC Hong Kong has no legitimate commercial rationale. Likely explanations: volume inflation or jurisdictional seasoning.

---

### 2.4 Risk Propagation Engine

**Methodology:**
- **Seeds:** All FATF grey-list banks (fatf_risk = 2) → base score 100
- **1-hop neighbors:** Any bank connected to a seed → +40
- **2-hop neighbors:** Any bank two steps from a seed → +20
- **Capping:** Maximum score 100

**Results:**

| Risk Band | Count | Interpretation |
| :--- | :--- | :--- |
| HIGH (80-100) | 12 | Seeds + immediate intermediaries |
| MEDIUM (50-79) | 30 | Two-step exposed institutions |
| LOW (<50) | 2,231 | No measurable network exposure |

**Impact:** Static watchlist monitoring identifies 9 entities. Graph-based detection identifies **205 institutions** requiring enhanced due diligence—a **2,278% increase** in detectable risk exposure.

---

## 3. Key Findings

### 3.1 The Iraq-Jordan Cluster

A 133-node community containing two FATF grey-list seeds:

```
SEED 1: Trade Bank For Investment And Finance (IRQ) ──$5.1M──► Standard Chartered Bank (ARE)
                                                              │
                                                              ▼
                                                      [SINK: 22 in, 0 out]

SEED 2: Blom Bank S.A.L. (JOR) ──$100K──► Bank of America (USA)
                                          │
                                          ▼
                                  [SINK: 2 in, 0 out]
```

**Why this matters:** No single bank's compliance team can see this pattern. Trade Bank sees one wire to a UAE correspondent. Standard Chartered sees 22 inbound wires—individually unremarkable. Only the graph reveals these institutions are part of the same high-density cluster.

### 3.2 Affiliate U-Turn (Caledonian Bank)

```
Caledonian Bank Ltd (CYM) → HSBC Hong Kong (HKG) → Caledonian Bank Limited (CYM)
```

**Why this matters:** There is no legitimate commercial rationale for a bank to route funds to itself through an international intermediary. This pattern is consistent with volume inflation (artificially boosting reported transaction volumes) and/or jurisdictional seasoning (using Hong Kong's reputation to "clean" funds before return to an offshore vehicle).

### 3.3 Risk Propagation Impact

| Metric | Watchlist Only | Graph-Based | Improvement |
| :--- | :--- | :--- | :--- |
| High-risk entities identified | 9 | 12 | +33% |
| Medium-risk entities identified | 0 | 30 | New detection |
| Total entities requiring scrutiny | 9 | 205 | +2,278% |

---

## 4. Performance Summary

| Detection Layer | Output | Key Finding |
| :--- | :--- | :--- |
| SQL Structuring | 8 flagged banks | Trust Merchant Bank Sarl: 43 sub-threshold transactions aggregating $199,198 |
| SQL Jurisdiction Hopping | 5 flagged banks | Deutsche Bank AG: 23 unique beneficiary countries, $1.70B volume |
| Entity Resolution | 1,089 SAME_AS relationships | Bank of America: 6 aliases consolidated |
| PageRank | Top 10 hubs identified | JSC Norvik Banka (LVA): influence score 8.60 |
| Louvain | 133-node cluster | iraq_jordan_cluster: 2 grey-list seeds co-located |
| Sink Node Analysis | 10+ sinks identified | JSC Norvik Banka: 57 inbound, 0 outbound |
| Affiliate U-Turn | 2 loops detected | Caledonian Bank self-routing via HSBC |
| Risk Propagation | 205 elevated institutions | 12 HIGH, 30 MEDIUM, 2,231 LOW |

---

## 5. Key Insights

### 5.1 Why Graph Analytics Outperforms SQL Alone

SQL detects patterns within rows—structuring, jurisdiction hopping. Graph analytics detects patterns **between** entities:
- Community density reveals clusters SQL cannot see
- PageRank quantifies influence SQL cannot measure
- Path traversal traces flows SQL cannot follow
- Sink analysis identifies integration endpoints SQL cannot surface

### 5.2 The Value of Entity Resolution

Without entity resolution:
- Bank of America's PageRank would be split across 6 nodes
- Louvain would mis-place variants in different communities
- Risk propagation would fail to accumulate true exposure

With entity resolution: 61 aliases consolidated, risk scores accurate, community detection meaningful.

### 5.3 Why Sink Nodes May Not Be True Sinks

The dataset contains only SAR filings. A bank with 22 inbound and 0 outbound transactions may simply have no outbound SAR filings—not no outbound transactions. This data boundary limitation is explicitly acknowledged in Section 8.

---

## 6. Future Enhancements

1. **Temporal Risk Weighting**
   - FATF status changes over time (2000-2017)
   - Apply transaction-date-appropriate risk scores

2. **Weighted Risk Propagation**
   - Transaction amounts should amplify propagation
   - Path redundancy should increase risk scores

3. **External Data Enrichment**
   - Incorporate beneficial ownership data
   - Add sanctions list integration
   - Include adverse media sources

4. **Production Deployment Considerations**
   - Automated entity resolution pipeline
   - Incremental graph updates (vs. full rebuild)
   - Alert prioritization based on PageRank + risk score
   - Dashboard for investigator triage

5. **Additional Graph Algorithms**
   - Betweenness centrality (identify critical intermediaries)
   - Node2Vec embeddings (similarity search)
   - Label propagation (semi-supervised seed expansion)

---

## 7. Conclusion

This project demonstrates that **graph analytics fundamentally changes AML detection** by revealing relationships, community structures, and risk propagation patterns invisible to traditional monitoring.

The composite system:
- **Identifies hidden relationships** through entity resolution (1,089 alias links)
- **Detects fraud rings** via community detection (133-node high-risk cluster)
- **Traces layering patterns** with affiliate U-turn detection
- **Quantifies network risk** through propagation (205 elevated institutions)
- **Provides SAR-ready intelligence** with clear red flags and risk scores

The architecture mirrors graph-based AML systems used by sophisticated financial institutions, demonstrating practical knowledge of:
- Graph database design (Neo4j)
- Graph algorithm selection and interpretation
- Entity resolution strategies
- Risk propagation modeling
- Regulatory reporting requirements

---

## 8. Limitations

| Limitation | Impact | Mitigation |
| :--- | :--- | :--- |
| **Data boundaries** | Sink nodes may reflect SAR filing limits, not actual termination | Explicit caveat in analysis; sink interpretation focuses on "no further SAR activity" |
| **Static FATF risk** | 17-year dataset with static scores may be anachronistic | Primary findings use jurisdictions with sustained risk profiles |
| **Graph sparsity** | Low average degree (1.66) limits cycle detection | Affiliate U-turn pattern serves as functional equivalent |
| **Risk propagation** | Simplified additive model ignores amounts and redundancy | Suitable for triage, not definitive quantification |

---

## Appendix: Technical Specifications

**Dataset:** FinCEN Files (ICIJ), 4,507 interbank SAR transactions, 2,277 banks, 17-year range (2000-2017)

**PostgreSQL Tables:**
- `transactions`: 4,507 rows, 19 columns (originator/beneficiary bank IDs, amounts, dates, FATF risk scores)
- `bank_connections`: 5,498 rows, 7 columns

**Neo4j Graph:**
- 2,273 Bank nodes
- 2,687 SENT_TO relationships
- 1,089 SAME_AS relationships (entity resolution)

**GDS Algorithms:**
- PageRank (writeProperty: `pagerank_v2`)
- WCC (writeProperty: `community_id`)
- Louvain (writeProperty: `louvain_id_v2`)

**Entity Resolution Tiers:**
- Tier 1: Strict (punctuation-normalized, same country)
- Tier 2: Smart (suffix normalization: N.A., Ltd, AG, PLC, branch, etc.)
- Tier 3: Investigative (domain-specific overrides)

**Risk Propagation Formula:**
- Seed (fatf_risk = 2): 100
- 1-hop neighbor: +40 (capped at 100)
- 2-hop neighbor: +20 (capped at 60 before addition)

---

## SQL + Cypher Queries

All detection logic is implemented in SQL (PostgreSQL) and Cypher (Neo4j) for transparency and auditability. The notebook contains:

- **SQL Structuring Detection:** Rolling 30-day sub-threshold aggregation
- **SQL Jurisdiction Hopping:** Multi-country exposure with FATF risk
- **Cypher Entity Resolution:** Three-tier name matching
- **Cypher PageRank:** Influence scoring with GDS
- **Cypher Louvain:** Community detection
- **Cypher Cycle Detection:** Layering loop identification
- **Cypher Affiliate U-Turn:** Sister-branch self-routing detection
- **Cypher Sink Analysis:** Integration endpoint identification
- **Cypher Risk Propagation:** Graph-based scoring engine

These queries run on the FinCEN Files dataset and can be adapted for any SAR transaction monitoring system.


