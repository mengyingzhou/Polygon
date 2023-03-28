#!/usr/bin/env bash

BASEDIR=$(dirname "$0")
root=${HOME}/data
date > ${root}/start_wrapper.sh.start_ts

tmux has-session -t main 2> /dev/null; if [[ $? == 0 ]]; then tmux kill-session -t main; fi
tmux new-session -ds main

bash ${root}/kill_client.sh
rm -f ~/traffic.log
rm -f ~/tmp.log
rm -f ~/del_port.log
rm -f ${root}/client*.log && rm -rf ~/experiment_results && mkdir -p ~/experiment_results
sleep 5

# create datacenters.txt
python3 -c "import os
import json
data = json.load(open(os.environ['HOME']+'/data/server.json'))
prefix = set([d[:-7] for d in data.keys() if d.startswith('polygon')])
ans = ['%s %s %s' % (p[7:], data['%s-router' % p]['external_ip1'], data['%s-server' % p]['external_ip1'])
        for p in prefix]
with open(os.environ['HOME']+'/data/datacenters.txt', 'w') as f:
    for a in ans:
        f.write(a)
        f.write('\n')"

# tmux send-key -t main:0 "${root}/start_anycast.sh" Enter
tmux send-key -t main:0 "${root}/start_polygon.sh" Enter

date > ${root}/start_wrapper.sh.end_ts

