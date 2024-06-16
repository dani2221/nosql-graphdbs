from .database import Database
import time

import psycopg2


class PostgresDB(Database):
    def connect(self, connection_string: str):
        self.conn = psycopg2.connect(connection_string)
        
            
    def execute(self, query: str):
        cursor = self.conn.cursor()
        
        start_time = time.time()
        cursor.execute(query)
        counts = cursor.rowcount
        end_time = time.time()
        
        return (counts, end_time - start_time)