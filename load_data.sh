#!/bin/bash

docker exec -i postgres-container psql -U postgres <<EOF
CREATE DATABASE nosql;
\c nosql
CREATE TABLE relationships (
  node1 VARCHAR,
  node2 VARCHAR
);
\COPY relationships(node1, node2) FROM 'import/gplus_combined_reduced.txt' DELIMITER ' ' CSV;
EOF


docker exec -it neo4j-container bash -c "
  cypher-shell -u neo4j -p password <<EOF
  CREATE CONSTRAINT unique_node_name FOR (n:Node) REQUIRE n.name IS UNIQUE;
EOF
"

docker exec -it neo4j-container bash -c "
  cypher-shell -u neo4j -p password <<EOF
  LOAD CSV FROM 'file:///gplus_combined_reduced.txt' AS row FIELDTERMINATOR ' '
  CALL {
    WITH row
    MERGE (start:Node {name: row[0]})
    MERGE (end:Node {name: row[1]})
    MERGE (start)-[rel:CONNECTED_TO]->(end)
  }
  IN TRANSACTIONS OF 100000 ROWS
EOF
"