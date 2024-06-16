Steps:
1. download gplus_combined.txt.gz from https://snap.stanford.edu/data/ego-Gplus.html
2. extract file
3. create forlder `/imports` and move gplus_combined.txt to that directory
4. `head -n 5000000 gplus_combined.txt > gplus_combined_reduced.txt` reduce the dataset from 30 mil rows to 5 mil rows
4. `docker compose up --build` 
5. `sh load_data.sh` and wait around 15 minutes for the data to be loaded in the databases (rip pc)
6. write queries in `/tester/app/queries.json` for both postgres and neo4j
7. restart the docker compose `docker compose up --build` and see the time results for the queries

