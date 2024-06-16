from abc import ABC, abstractmethod

class Database(ABC):
    
    @abstractmethod
    def connect(self, connection_string: str):
        pass
    
    @abstractmethod
    def execute(self, query: str):
        pass