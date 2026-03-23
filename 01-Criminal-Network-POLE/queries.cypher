// Query 1: Top 10 High-Volume Offenders (Surface Activity)
// Purpose: Identify nodes with the highest direct links to 'Crime' entities.
MATCH (p:Person)-[:PARTY_TO]->(c:Crime)
RETURN p.name AS Suspect, count(c) AS IncidentCount
ORDER BY IncidentCount DESC 
LIMIT 10;

// Query 2: Identifying 'Quiet Kingpins' via Betweenness Centrality
// Purpose: Find nodes that act as critical bridges across the entire 61k node graph.
CALL gds.betweenness.stream('criminalNetwork')
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name AS Name, 
       labels(gds.util.asNode(nodeId))[0] AS Type, 
       score AS BetweennessScore
ORDER BY BetweennessScore DESC 
LIMIT 10;

// Query 3: Multi-Modal Infrastructure Analysis
// Purpose: Quantify the diversity of entities connected to a single node.
MATCH (n:Person {name: 'Jessica'})-[r]-(neighbor)
RETURN labels(neighbor)[0] AS EntityType, 
       type(r) AS Relationship, 
       count(*) AS TotalConnections
ORDER BY TotalConnections DESC;

// Query 4: Identifying High-Prestige Influence (PageRank)
// Purpose: Measure the 'importance' of a node based on the quality of its neighbors.
CALL gds.pageRank.stream('criminalNetwork')
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name AS Name, score AS PageRank
ORDER BY PageRank DESC 
LIMIT 10;
