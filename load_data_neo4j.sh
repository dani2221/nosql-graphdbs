docker exec -it neo4j-container bash -c "
  cypher-shell -u neo4j -p password <<EOF
  CREATE CONSTRAINT unique_user_name FOR (n:User) REQUIRE n.name IS UNIQUE;
  CREATE CONSTRAINT unique_institution_name FOR (n:Institution) REQUIRE n.name IS UNIQUE;
  CREATE CONSTRAINT unique_place_name FOR (n:Place) REQUIRE n.name IS UNIQUE;
  CREATE CONSTRAINT unique_university_name FOR (n:University) REQUIRE n.name IS UNIQUE;
EOF
"

docker exec -it neo4j-container bash -c "
  cypher-shell -u neo4j -p password <<EOF
  LOAD CSV WITH HEADERS FROM 'file:///combined.csv' AS row
  MERGE (u:User {name: row.name})

  WITH u,row,split(row.institution, ';') AS institutions WHERE row.institution IS NOT NULL
  FOREACH (f in institutions | merge (inst:Institution {name: f}) merge (u)-[:works_at]->(inst))

  WITH u,row,split(row.place, ';') AS places WHERE row.place IS NOT NULL
  FOREACH (f in places | merge (inst:Place {name: f}) merge (u)-[:lives_in]->(inst))

  WITH u,row,split(row.university, ';') AS universities WHERE row.university IS NOT NULL
  FOREACH (f in universities | merge (inst:University {name: f}) merge (u)-[:studies_at]->(inst))
  
  SET u.job_title = row.job_title,
      u.gender = row.gender,
      u.last_name = row.last_name
EOF
"

docker exec -it neo4j-container bash -c "
  cypher-shell -u neo4j -p password <<EOF
  LOAD CSV FROM 'file:///gplus_combined_reduced.txt' AS row FIELDTERMINATOR ' '
  CALL {
    WITH row
    MERGE (start:User {name: row[0]})
    MERGE (end:User {name: row[1]})
    MERGE (start)-[rel:CONNECTED_TO]->(end)
  }
  IN TRANSACTIONS OF 100000 ROWS
EOF
"