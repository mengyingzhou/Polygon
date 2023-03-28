#!/usr/bin/env bash
root=${HOME}"/DNS_CDN"
date > ${root}/start_server.sh.start_ts

unicast=`python3 -c "import os
import json
machines=json.load(open('${root}/machine_server.json'))
print(machines[os.uname()[1]]['external_ip1'])"`

for i in `seq 100`
do 
    {
        port=$((4433+$i))
        echo server_$port
        echo sudo LD_LIBRARY_PATH=${root} ${root}/server/server --interface=ens4 --unicast=${unicast} 0.0.0.0 $port ${root}/server.key ${root}/server.crt -q
        sudo LD_LIBRARY_PATH=${root} ${root}/server/server --interface=ens4 --unicast=${unicast} 0.0.0.0 $port ${root}/server/server.key ${root}/server/server.crt -q 1>> ${root}/server_tmp_${port}.log 2>> ${root}/server_${port}.log
    } &
done

date > ${root}/start_server.sh.end_ts