import json
import configparser

config = configparser.ConfigParser()
config['DNS']={}
config['client']={}
config['client']['ips'] = ''
config['server']={}

config['DNS'] = {
            'inter': '10.128.0.2',
            'exter': '35.232.57.157'
        }

machines=json.load(open('machine_client.json'))
for item in machines: 
    config['client']['ips'] = config['client']['ips'] + item['hostname'] + ','

machines=json.load(open('machine_server.json'))
for key in ['polygon-asia-southeast1-c-server', 'polygon-northamerica-northeast1-c-server', 'polygon-australia-southeast1-c-server', 'polygon-southamerica-east1-b-server', 'polygon-europe-west2-b-server']: 
    config['server'][key] = machines[key]['external_ip1']

with open('ip.conf','w') as cfg:
    config['layer'] = {}
    config['layer']['polygon-asia-southeast1-c-server'] = 'polygon-australia-southeast1-c-server'
    config['layer']['polygon-northamerica-northeast1-c-server'] = 'polygon-southamerica-east1-b-server'
    config['layer']['polygon-australia-southeast1-c-server'] = 'polygon-europe-west2-b-server'
    config['layer']['polygon-southamerica-east1-b-server'] = 'polygon-europe-west2-b-server'
    config['client']['ips'] = config['client']['ips'][:-1]
    config.write(cfg)