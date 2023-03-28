import subprocess
import json
import os

machines=json.load(open(os.environ["HOME"]+"/data/server.json"));
clients=json.load(open(os.environ["HOME"]+"/data/client.json"));
fh = subprocess.Popen("tail -150 " + os.environ["HOME"]+"/data/iftop_log.txt", stdout=subprocess.PIPE, shell=True)
lines = reversed(fh.stdout.readlines())
cnt=0
geo_ratio={}
routers = [x for x in machines if "router" in x]

std_ratio = open(os.environ["HOME"]+"/data/initial_std.txt").readlines()
for i in range(len(routers)):
    geo_ratio[routers[i].split('-')[1]] = float(std_ratio[i])

ips = []
zones = []


for raw_line in lines:
    line = raw_line.decode('ascii')
    if line.startswith("=="):
        cnt += 1
    if cnt == 0:
        continue
    if cnt == 2:
        break

    if "<=" in line:
        last_info = line.split("<=")[0].replace(" ", "")
    
    if "=>" in line:
        speed = line.split("=>")[1].split("b")[2]
        if 'M' in speed or ('K' in speed and float(speed.split('K')[0]) > 200):
            ip_add = ''
            for item in last_info.split('.'):
                if item.isdigit():
                    if ip_add:
                        ip_add = item + '.' + ip_add
                    else:
                        ip_add = item
            if ip_add not in ips:
                ips.append(ip_add)

ans=0
for ip in ips:
    for client in clients:
        if client['hostname'] == ip:
            if 'us-' in client['zone']:
                zone = 'northamerica'
            else:
                zone = client['zone'].split('-')[0]
            ans = ans + float(geo_ratio[zone])
            break
print(ans)