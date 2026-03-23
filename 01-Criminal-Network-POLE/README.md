# Case Study: Unmasking Structural Risk in Criminal Networks

## Overview
This investigation utilizes **Graph Data Science (GDS)** to move beyond traditional frequency-based crime analysis. Using the **POLE (Person-Object-Location-Event)** framework, I analyzed a network of **61,000+ nodes** to identify hidden "brokers"—individuals who facilitate criminal infrastructure without necessarily being the most "active" offenders.

## The Challenge: "The Quiet Kingpin"
Traditional law enforcement reporting often prioritizes suspects based on **incident count**. However, in sophisticated networks, the most dangerous actors often maintain a low profile, acting as "bridges" between disparate cells. 

**The Goal:** Use Centrality Algorithms to quantify "Structural Power" vs "Incident Activity."

## Methodology & Tech Stack
* **Graph Engine:** Neo4j 5.x
* **Library:** Neo4j Graph Data Science (GDS)
* **Algorithms:** * **PageRank:** To measure prestige and quality of connections.
    * **Betweenness Centrality:** To identify bottlenecks and information brokers.
    * **Nodal Density:** To identify localized clusters of high-risk activity.
    * View all technical queries used in this investigation [here](./queries.cypher).

## Key Discovery: Phillip vs. Jessica
By comparing "Surface Activity" (Crime Count) with "Network Influence" (Centrality), a critical anomaly was discovered.

| Metric | Phillip (The Operator) | Jessica (The Strategist) |
| :--- | :--- | :--- |
| **Total Crimes** | 5 (Rank 1) | 5 (Rank 1) |
| **Nodal Density** | ~14 | **28 (High-Density Hub)** |
| **Betweenness Score** | 10,529 | **26,533 (Rank 1)** |
| **PageRank** | Rank 16 | **Rank 12** |

### Network Visualization
![Network Bridge Analysis](https://raw.githubusercontent.com/diransuraj/Financial-Crime-Graph-Intelligence/main/01-Criminal-Network-POLE/images/jessica-network-bridge.png)
*Figure 1: Visualization of Jessica acting as a "Global Bridge" between otherwise disconnected criminal clusters.*

## Fraud Analysis Insights
1. **The Brokerage Effect:** Jessica’s Betweenness score of **26,533** is a statistical outlier. In a population of only 369 persons, she sits on the shortest path for nearly 43% of the network's potential communication routes.
2. **Infrastructure Control:** Jessica was found to be linked to 3 unique email addresses and 3 physical locations. In fraud detection, this "Multi-Point Anchor" pattern is a high-confidence indicator of a **mule-herder** or **identity orchestrator**.
3. **Operational Impact:** Disrupting Jessica provides a **3.5x higher systemic impact** on the network than arresting Phillip, despite them having the same criminal record.

## How to Run
1. Ensure Neo4j Desktop or Aura is running with the GDS plugin installed.
2. Import the POLE dataset (Link in root README).
3. Run the cells in `Criminal_Network_Analysis_POLE.ipynb` to reproduce the Centrality rankings.

---
**Author:** [Diran Suraj]  
**Role:** Fraud & Network Analyst  
**Tools:** #Neo4j #Cypher #GraphDataScience #Python

---
##  Data Provenance
The dataset used in this investigation is the **POLE (Person, Object, Location, Event)** synthetic dataset provided by Neo4j. It is a recognized standard for Link Analysis and law enforcement GDS training.

* **Source:** [Neo4j Graph Examples - POLE](https://github.com/neo4j-graph-examples/pole)
* **Scale:** 61,521 Nodes | 100,000+ Relationships
* **License:** Public Domain / Creative Commons (via Neo4j)
