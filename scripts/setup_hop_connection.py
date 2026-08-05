import os
import glob
import xml.etree.ElementTree as ET

hop_dir = r'd:\Especialização Engenharia de Dados e Big Data USP\3° Ciclo\eEDB-022 Ingestão e Pipeline de Dados - Prof. MSc. Leandro Mendes Ferreira\hop'

# 1. Create metadata folders and json for Hop 2.x
rdbms_dirs = [
    os.path.join(hop_dir, 'metadata', 'rdbms'),
    os.path.join(hop_dir, 'metadata', 'relational-database')
]

conn_json = """{
  "name": "postgres_dw_conn",
  "hostname": "postgres_dw",
  "port": "5432",
  "databaseName": "eedb_dw",
  "username": "postgres",
  "password": "Encrypted 2be98afc86aa7f2e4cb79ce10bef2cf8b",
  "pluginId": "POSTGRESQL",
  "pluginName": "PostgreSQL",
  "driverType": "POSTGRESQL",
  "manualUrl": "",
  "attributes": {}
}"""

for d in rdbms_dirs:
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, 'postgres_dw_conn.json'), 'w', encoding='utf-8') as f:
        f.write(conn_json)

print('Metadata connection JSON created!')

# 2. Embed connection XML into all .hpl files so pipeline carries its own connection definition
hpl_files = glob.glob(os.path.join(hop_dir, 'pipelines', '*.hpl'))
for hpl in hpl_files:
    tree = ET.parse(hpl)
    root = tree.getroot()
    
    # Check if connection already exists
    conn = root.find('connection')
    if conn is None:
        conn = ET.Element('connection')
        root.insert(1, conn)
        
        name = ET.SubElement(conn, 'name')
        name.text = 'postgres_dw_conn'
        
        server = ET.SubElement(conn, 'server')
        server.text = 'postgres_dw'
        
        ctype = ET.SubElement(conn, 'type')
        ctype.text = 'POSTGRESQL'
        
        access = ET.SubElement(conn, 'access')
        access.text = 'Native'
        
        db = ET.SubElement(conn, 'database')
        db.text = 'eedb_dw'
        
        port = ET.SubElement(conn, 'port')
        port.text = '5432'
        
        user = ET.SubElement(conn, 'username')
        user.text = 'postgres'
        
        pwd = ET.SubElement(conn, 'password')
        pwd.text = 'Encrypted 2be98afc86aa7f2e4cb79ce10bef2cf8b'

    tree.write(hpl, encoding='UTF-8', xml_declaration=True)
    print(f'Embedded connection into {os.path.basename(hpl)}')
