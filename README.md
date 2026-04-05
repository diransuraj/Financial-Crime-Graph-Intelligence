# 🛡️ Fraud & Criminal Intelligence Portfolio

A collection of Graph Data Science investigations using Neo4j, GDS, and SQL to identify high-risk entities, hidden financial patterns, and complex money laundering rings.

## 📁 Projects

### [01. Criminal Link Analysis (POLE Dataset)](./01-Criminal-Network-POLE)
- **Goal:** Identify hidden "Quiet Kingpins" using Betweenness Centrality.
- **Result:** Unmasked a strategic broker (Jessica) with a centrality score of 26,533.

### [02. AML Transaction Monitoring System (Paysim Dataset)](./02-AML-Investigations-Paysim)
- **Goal:** Develop a layered detection system to maximize fraud recall while maintaining operational efficiency by reducing false positives, addressing the precision-recall tradeoff inherent in money mule detection.
- **Result:** Achieved a 53.7% precision rate (1 in 2 alerts is fraud) and 66.6% recall, catching 5,726 fraud cases annually while generating only 10,662 alerts—a 97% reduction in investigator workload compared to a naive scoring system.

### [03. Graph-Based AML Detection (FinCEN Files)](./03-Graph-Based-AML-FinCEN)
- **Goal:** Detect complex money laundering rings by applying graph analytics (PageRank, Louvain, entity resolution, risk propagation) to FinCEN Suspicious Activity Reports.
- **Key Findings:**
  - Identified a **133-node high-risk cluster** containing two FATF grey-list institutions (Iraq and Jordan)
  - Traced **$5.2M in suspicious flows** from seeds to sink nodes
  - Detected **affiliate U-turn layering** (Caledonian Bank → HSBC Hong Kong → Caledonian Bank)
  - Resolved **1,089 alias relationships** across 61 entities via three-tier matching
  - Propagated risk to **205 institutions**—a **2,278% increase** over watchlist-only monitoring
- **Tech Stack:** PostgreSQL (SQL detection) → Python → Neo4j GDS (graph algorithms)

---
## 🛠 Technical Toolkit
- **Graph Databases:** Neo4j (Cypher, GDS Library)
- **Data Science:** Python (Pandas, Jupyter, NetworkX, Matplotlib)
- **Databases:** PostgreSQL (SQL detection layer)
- **Domain Expertise:** Fraud Detection, Anti-Money Laundering (AML), Link Analysis, Financial Crime Investigation, SAR Filing

## 📬 Contact
- **LinkedIn:** [linkedin.com/in/diran-s/](https://www.linkedin.com/in/diran-s/)
- **Role Interests:** Fraud Analyst, Financial Crime Investigator, Graph Data Analyst, AML Intelligence Analyst

---

## 📊 Portfolio at a Glance

| Project | Focus | Key Technique | Outcome |
| :--- | :--- | :--- | :--- |
| Criminal Link Analysis | Hidden kingpins | Betweenness Centrality | Identified strategic broker (26,533 score) |
| AML Transaction Monitoring | Money mule detection | Layered rules + Random Forest | 53.7% precision, 66.6% recall |
| Graph-Based AML Detection | Money laundering rings | PageRank + Louvain + Risk Propagation | 133-node cluster, 205 elevated institutions |
