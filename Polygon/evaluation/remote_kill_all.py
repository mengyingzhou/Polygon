import os
import json
from multiprocessing import Process

HOME = os.environ["HOME"]

def kill_server_router(key, internal_ip):
    if "server" in key:
        os.system('ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null %s "sudo wondershaper clear ens4;"' % internal_ip)
        os.system('ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null %s "cd ~; ~/data/kill_server.sh"' % internal_ip)

    if "router" in key:
        os.system('ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null %s "cd ~; ~/data/kill_server.sh"' % internal_ip)
    
def kill_client(key):
    os.system('ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null %s "~/data/kill_client.sh"' % key)


f = open(HOME + "/client.json", "r")
clients = json.load(f)
f.close()
p_l = []
for key in clients:
    key = key['hostname']
    kill_client(key)
    p = Process(target=kill_client,args=(key, ))
    p_l.append(p)
    p.start()
for p in p_l:
    p.join()


f = open(HOME + "/server.json", "r")
servers = json.load(f)
f.close()
p_l = []
for key in servers.keys():
    try:
        internal_ip = servers[key]['internal_ip1']
    except:
        pass

    p = Process(target=kill_server_router,args=(key, internal_ip,))
    p_l.append(p)
    p.start()
for p in p_l:
    p.join()
