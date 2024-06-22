#!/bin/bash

docker exec -i postgres-container psql -U postgres <<EOF
\c nosql
CREATE TABLE relationships (
  person1 VARCHAR,
  person2 VARCHAR
);
\COPY relationships(person1, person2) FROM 'import/gplus_combined_reduced.txt' DELIMITER ' ' CSV;

-- Create details table
CREATE TABLE details (
    id SERIAL PRIMARY KEY,
    job_title TEXT,
    gender TEXT,
    last_name TEXT,
    name TEXT
);

-- Create institution table
CREATE TABLE institution (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE
);

-- Create place table
CREATE TABLE place (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE
);

-- Create university table
CREATE TABLE university (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE
);

-- Create details_institution table for many-to-many relationship
CREATE TABLE details_institution (
    details_id INTEGER REFERENCES details(id),
    institution_id INTEGER REFERENCES institution(id),
    PRIMARY KEY (details_id, institution_id)
);

-- Create details_place table for many-to-many relationship
CREATE TABLE details_place (
    details_id INTEGER REFERENCES details(id),
    place_id INTEGER REFERENCES place(id),
    PRIMARY KEY (details_id, place_id)
);

-- Create details_university table for many-to-many relationship
CREATE TABLE details_university (
    details_id INTEGER REFERENCES details(id),
    university_id INTEGER REFERENCES university(id),
    PRIMARY KEY (details_id, university_id)
);


-- Create a temporary table for importing data
CREATE TEMP TABLE import_data (
    id INTEGER,
    job_title TEXT,
    institution TEXT,
    place TEXT,
    university TEXT,
    gender TEXT,
    last_name TEXT,
    name TEXT
);

COPY import_data (id, job_title, institution, place, university, gender, last_name, name)
FROM '/import/combined.csv' DELIMITER ',' CSV HEADER;

-- Insert into institution table
INSERT INTO institution (name)
SELECT DISTINCT unnest(STRING_TO_ARRAY(institution,';'))
FROM import_data;

-- Insert into place table
INSERT INTO place (name)
SELECT DISTINCT unnest(STRING_TO_ARRAY(place,';'))
FROM import_data;

-- Insert into university table
INSERT INTO university (name)
SELECT DISTINCT unnest(STRING_TO_ARRAY(university,';'))
FROM import_data;

-- Insert into details table
INSERT INTO details (id, job_title, gender, last_name, name)
SELECT id, job_title, gender, last_name, name
FROM import_data;

-- Insert into details_institution table (many-to-many relationship)
INSERT INTO details_institution (details_id, institution_id)
SELECT d.id, i.id
FROM details d
JOIN import_data imp ON d.id = imp.id
JOIN unnest(STRING_TO_ARRAY(imp.institution,';')) inst(name) ON true
JOIN institution i ON inst.name = i.name
ON CONFLICT (details_id, institution_id) DO NOTHING;

-- Insert into details_place table (many-to-many relationship)
INSERT INTO details_place (details_id, place_id)
SELECT d.id, p.id
FROM details d
JOIN import_data imp ON d.id = imp.id
JOIN unnest(STRING_TO_ARRAY(imp.place,';')) plc(name) ON true
JOIN place p ON plc.name = p.name
ON CONFLICT (details_id, place_id) DO NOTHING;

-- Insert into details_university table (many-to-many relationship)
INSERT INTO details_university (details_id, university_id)
SELECT d.id, u.id
FROM details d
JOIN import_data imp ON d.id = imp.id
JOIN unnest(STRING_TO_ARRAY(imp.university,';')) univ(name) ON true
JOIN university u ON univ.name = u.name
ON CONFLICT (details_id, university_id) DO NOTHING;

DROP TABLE import_data;

EOF


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
    MERGE (start:Node {name: row[0]})
    MERGE (end:Node {name: row[1]})
    MERGE (start)-[rel:CONNECTED_TO]->(end)
  }
  IN TRANSACTIONS OF 100000 ROWS
EOF
"