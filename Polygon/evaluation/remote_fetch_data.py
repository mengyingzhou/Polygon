import os
import json
from multiprocessing import Process

HOME = os.environ["HOME"]
root = HOME
results_path = root + "/results"

def run_server_router(key, internal_ip):
    if "server" in key:
        print("server: ", key)
        os.system("mkdir -p %s/server_results/%s" % (results_path, key))
        os.system('ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null %s "sudo wondershaper clear ens4; rm -f ~/experiment_results.zip && zip -r experiment_results.zip experiment_results >/dev/null"' % internal_ip)
        os.system("sshpass scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no %s:~/server*.log %s/server_results/%s" % (internal_ip, results_path, key))
        os.system("sshpass scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no %s:~/experiment_results.zip %s/server_results/%s" % (internal_ip, results_path, key))
        os.system("sshpass scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no %s:~/traffic.log %s/server_results/%s >/dev/null" % (internal_ip, results_path, key))
        os.system("sshpass scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no %s:~/cpu.log %s/server_results/%s >/dev/null" % (internal_ip, results_path, key))
        os.system("sshpass scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no %s:~/iftop_log.txt %s/server_results/%s >/dev/null" % (internal_ip, results_path, key))
        print("fetch %s done!" % key)

    if "router" in key:
        print("router: ", key)
        os.system("mkdir -p %s/router_results/%s" % (results_path, key)) 
        os.system('ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null %s "rm -f ~/experiment_results.zip && zip -r experiment_results.zip experiment_results >/dev/null"' % internal_ip)
        os.system("sshpass scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no %s:~/balancer*.log %s/router_results/%s >/dev/null" % (internal_ip, results_path, key))
        os.system("sshpass scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no %s:~/experiment_results.zip %s/router_results/%s >/dev/null" % (internal_ip, results_path, key))
        print("fetch %s done!" % results_path, key)

def run_client(external_ip):
    print("client", external_ip)
    os.system("mkdir -p %s/client_results/%s" % (results_path, external_ip)) 
    os.system('ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null %s "rm -f ~/experiment_results.zip && zip -r experiment_results.zip experiment_results >/dev/null"' % external_ip)
    os.system("sshpass scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no %s:~/client*.log %s/client_results/%s >/dev/null" % (external_ip, results_path, external_ip))
    os.system("sshpass scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no %s:~/experiment_results.zip %s/client_results/%s >/dev/null" % (external_ip, results_path, external_ip))
    # os.system("sshpass scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no %s:~/del_port.log %s/client_results/%s >/dev/null" % (external_ip, results_path, external_ip))
    os.system("sshpass scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no %s:~/a_*.log %s/client_results/%s >/dev/null" % (external_ip, results_path, external_ip))
    print("fetch %s done!" % external_ip)




if os.path.exists(results_path):
    print("delete last results first")
    exit()
os.system("rm -f %s/results.zip" % root)
os.system("mkdir -p %s" % results_path)


f = open(root + "/server.json", "r")
servers = json.load(f)
f.close()
p_l = []
for key in servers.keys():
    try:
        internal_ip = servers[key]['internal_ip1']
    except:
        pass

    p = Process(target=run_server_router,args=(key, internal_ip,))
    p_l.append(p)
    p.start()
for p in p_l:
    p.join()
print("fetch server done!")


f = open(root + "/client.json", "r")
hosts = json.load(f)
f.close()
p_l = []
for key in hosts:
    external_ip = key['hostname']
    p = Process(target=run_client,args=(external_ip,))
    p_l.append(p)
    p.start()
for p in p_l:
    p.join()
print("fetch client done!")


os.system("cd %s && zip -r results.zip results >/dev/null" % root)
print("zip results done!")
