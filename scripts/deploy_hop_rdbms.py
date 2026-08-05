import os

conn_json = """{
  "name": "postgres_dw_conn",
  "rdbmsId": "POSTGRESQL",
  "pluginId": "POSTGRESQL",
  "driverType": "POSTGRESQL",
  "hostname": "postgres_dw",
  "port": "5432",
  "databaseName": "eedb_dw",
  "username": "postgres",
  "password": "Encrypted 2be98afc86aa7f2e4cb79ce10bef2cf8b",
  "manualUrl": "",
  "attributes": {}
}"""

hop_dir = r'd:\Especialização Engenharia de Dados e Big Data USP\3° Ciclo\eEDB-022 Ingestão e Pipeline de Dados - Prof. MSc. Leandro Mendes Ferreira\hop'

paths = [
    os.path.join(hop_dir, 'metadata', 'rdbms'),
    os.path.join(hop_dir, 'metadata', 'relational-database')
]

for p in paths:
    os.makedirs(p, exist_ok=True)
    with open(os.path.join(p, 'postgres_dw_conn.json'), 'w', encoding='utf-8') as f:
        f.write(conn_json)

print('Updated local metadata files!')
