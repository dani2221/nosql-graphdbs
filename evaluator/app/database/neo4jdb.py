from .database import Database

from neo4j import GraphDatabase

class Neo4JDB(Database):
    def connect(self, connection_string: str):
        with GraphDatabase.driver(connection_string, auth=("neo4j", 'password')) as driver:
            self.driver = driver
            driver.verify_connectivity()
            
    def execute(self, query: str):
        records, summary, _ = self.driver.execute_query(query)
        return (len(records), summary.result_available_after/1000)