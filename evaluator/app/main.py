import json
import os
import time

from database.neo4jdb import Neo4JDB
from database.postgresdb import PostgresDB

if __name__ == '__main__':
    config_file = 'app/queries.json'
    with open(config_file, 'r') as f:
        config = json.load(f)
        
    neo4j = Neo4JDB()
    postgres = PostgresDB()
    
    time.sleep(10)
    
    neo4j.connect(os.environ.get("NEO4JDATABASE_URL"))
    postgres.connect(os.environ.get("POSTGRES_DATABASE_URL"))
    
    
    for query in config:
        print(f"EXECUTING: {query['TITLE']}", flush=True)
        
        print("NEO4J QUERY:", flush=True)
        print(query["NEO4J"], flush=True)
        rows, t = neo4j.execute(query['NEO4J'])
        print(f"NEO4J TOOK {t} seconds and queried {rows} results", flush=True)
        
        print("POSTGRES QUERY:", flush=True)
        print(query["POSTGRES"], flush=True)
        rows, t = postgres.execute(query['POSTGRES'])
        print(f"POSTGRES TOOK {t} seconds and queried {rows} results", flush=True)
        
        print('\n\n', flush=True)
        
        
        
    