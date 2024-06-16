Steps:
1. download gplus_combined.txt.gz from https://snap.stanford.edu/data/ego-Gplus.html
2. extract file
3. move gplus_combined.txt into `/import` folder
4. `head -n 5000000 gplus_combined.txt > gplus_combined_reduced.txt` reduce the dataset from 30 mil rows to 5 mil rows
4. `docker compose up --build` 
5. `sh load_data.sh` and wait around 15 minutes for the data to be loaded in the databases (rip pc)
6. write queries in `/evaluator/app/queries.json` for both postgres and neo4j
7. restart the docker compose `docker compose up --build` and see the time results for the queries


Example Query results:
<img width="759" alt="image" src="https://github.com/dani2221/nosql-graphdbs/assets/55097438/41b503bd-d231-4553-a5d9-40672a35ee77">


